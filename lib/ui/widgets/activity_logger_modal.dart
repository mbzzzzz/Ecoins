import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class ActivityLoggerModal extends StatefulWidget {
  final VoidCallback onLogged;

  const ActivityLoggerModal({super.key, required this.onLogged});

  @override
  State<ActivityLoggerModal> createState() => _ActivityLoggerModalState();
}

class _ActivityLoggerModalState extends State<ActivityLoggerModal> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  double _sliderValue = 1.0;
  bool _isSubmitting = false;

  // Verification State
  XFile? _evidenceImage;
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;
  String? _verificationError;
  Map<String, dynamic>? _deviceInfo;
  Map<String, dynamic>? _imageMetadata;
  Map<String, dynamic>? _deviceLocation;
  DateTime? _imageTimestamp;

  final Map<String, IconData> _categories = {
    'transport': Icons.directions_bus,
    'energy': Icons.bolt,
    'food': Icons.restaurant,
    'recycle': Icons.recycling,
    'shopping': Icons.shopping_bag,
  };

  final _picker = ImagePicker();

  Future<void> _pickAndVerifyImage() async {
    setState(() {
      _isVerifying = true;
      _verificationError = null;
      _verificationResult = null;
    });

    try {
      // 1. Pick Image (Prefer Camera)
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Reduce size for API
        maxWidth: 800,
      );

      if (photo == null) {
        setState(() => _isVerifying = false);
        return;
      }

      setState(() => _evidenceImage = photo);

      // 2. Get Device Location
      Position? devicePosition;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          devicePosition = await Geolocator.getCurrentPosition();
        }
      } catch (e) {
        debugPrint('Location error: $e');
      }

      // 3. Read Exif (Metadata) - Get device info, timestamp, location
      DateTime? imageDate;
      Map<String, dynamic>? exifData;
      Map<String, dynamic>? imageLocation;

      if (!kIsWeb && !this.isEmpty(photo.path)) {
        try {
          final exif = await Exif.fromPath(photo.path);
          final dateString = await exif.getOriginalDate();
          if (dateString != null) {
            imageDate = dateString;
          }

          // Get GPS location from EXIF if available
          try {
            final latLong = await exif.getLatLong();
            if (latLong != null) {
              imageLocation = {
                'latitude': latLong.latitude,
                'longitude': latLong.longitude
              };
            }
          } catch (e) {
            debugPrint('EXIF GPS error: $e');
          }

          // Get device model from EXIF
          try {
            final make = await exif.getAttribute('Make');
            final model = await exif.getAttribute('Model');
            exifData = {'make': make, 'model': model};
          } catch (e) {
            debugPrint('EXIF device error: $e');
          }

          await exif.close();
        } catch (e) {
          debugPrint('Exif error: $e');
        }
      }

      // 4. Get Device Info
      Map<String, dynamic> deviceInfo = {};
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        if (kIsWeb) {
          final webInfo = await deviceInfoPlugin.webBrowserInfo;
          deviceInfo = {
            'platform': 'Web',
            'browserName': webInfo.browserName.name,
            'userAgent': webInfo.userAgent,
          };
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          deviceInfo = {
            'platform': 'Android',
            'manufacturer': androidInfo.manufacturer,
            'model': androidInfo.model,
            'device': androidInfo.device,
            'brand': androidInfo.brand,
            'version': androidInfo.version.release,
          };
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfoPlugin.iosInfo;
          deviceInfo = {
            'platform': 'iOS',
            'name': iosInfo.name,
            'model': iosInfo.model,
            'systemName': iosInfo.systemName,
            'systemVersion': iosInfo.systemVersion,
            'identifierForVendor': iosInfo.identifierForVendor,
          };
        }
      } catch (e) {
        debugPrint('Device info error: $e');
      }

      // 5. Verification Logic - Image must be recent (within 1 hour)
      if (imageDate != null) {
        final now = DateTime.now();
        final diff = now.difference(imageDate).inMinutes.abs();
        if (diff > 60) {
          setState(() {
            _verificationError =
                'Image is too old (${diff.toInt()} minutes). Please take a new photo within the last hour.';
            _isVerifying = false;
          });
          return;
        }
      } else {
        // If no EXIF date, use current time (photo was just taken)
        imageDate = DateTime.now();
      }

      // 6. Cross-verify location if both available
      if (devicePosition != null && imageLocation != null) {
        final distance = Geolocator.distanceBetween(
          devicePosition.latitude,
          devicePosition.longitude,
          imageLocation['latitude']!,
          imageLocation['longitude']!,
        );
        // Allow up to 100m difference (GPS accuracy)
        if (distance > 100) {
          setState(() {
            _verificationError =
                'Location mismatch detected. Please ensure GPS is enabled and take photo at the activity location.';
            _isVerifying = false;
          });
          return;
        }
      }

      // 7. Call Verification Edge Function
      if (_selectedCategory == null) {
        setState(() {
          _verificationError = 'Select a category first.';
          _isVerifying = false;
        });
        return;
      }

      final result = await _verifyWithEdgeFunction(
        photo,
        _selectedCategory!,
        deviceInfo,
        devicePosition != null
            ? {
                'latitude': devicePosition.latitude,
                'longitude': devicePosition.longitude,
                'accuracy': devicePosition.accuracy,
              }
            : null,
        imageDate?.toIso8601String(),
      );

      setState(() {
        _verificationResult = result;
        _deviceInfo = deviceInfo;
        _imageMetadata = exifData;
        _deviceLocation = devicePosition != null
            ? {
                'latitude': devicePosition.latitude,
                'longitude': devicePosition.longitude,
                'accuracy': devicePosition.accuracy,
              }
            : null;
        _imageTimestamp = imageDate;
        // Auto-update slider if AI confident
        if (result['carbon_saved_estimate'] != null) {
          double kg = (result['carbon_saved_estimate'] as num).toDouble();
          double slider = (kg / 0.5);
          if (slider < 1) slider = 1;
          if (slider > 10) slider = 10;
          _sliderValue = slider;
        }
        if (result['description'] != null) {
          _descriptionController.text = result['description'];
        }
      });
    } catch (e) {
      setState(() => _verificationError = 'Verification failed: $e');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  bool isEmpty(String? s) => s == null || s.isEmpty;

  Future<Map<String, dynamic>> _verifyWithEdgeFunction(
    XFile image,
    String category,
    Map<String, dynamic> deviceInfo,
    Map<String, dynamic>? location,
    String? imageTimestamp,
  ) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final functions = Supabase.instance.client.functions;
      // ENABLE REAL EDGE FUNCTION
      const bool useRealEdgeFunction = true;

      if (useRealEdgeFunction) {
        final response = await functions.invoke(
          'verify-activity',
          body: {
            'imageBase64': base64Image,
            'category': category,
            'deviceInfo': deviceInfo,
            'location': location,
            'imageTimestamp': imageTimestamp,
          },
        );

        final result = response.data ?? {};

        // Handle explicit backend errors (e.g., config missing)
        if (result['error'] != null && result['verified'] == false) {
           // If it's a configuration error, make it user-friendly but honest
           if (result['error'].toString().contains('API key')) {
             throw Exception('Server Configuration Error: AI Provider Key missing.');
           }
           throw Exception(result['error']);
        }

        return Map<String, dynamic>.from(result);
      } else {
        throw Exception('Edge function disabled');
      }

    } catch (e) {
      debugPrint('Verification Failed: $e');
      // No more mock fallback. Return error state.
      // This ensures we are not "faking" success.
      return {
          'verified': false,
          'error': 'Verification failed: ${e.toString().replaceAll('Exception:', '').trim()}',
      };
    }
  }

  void _submit() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      double carbonSaved = _sliderValue * 0.5;
      int points = (_sliderValue * 10).toInt();

      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please log in to save activities.')));
          Navigator.pop(context);
        }
        return;
      }

      // Enforce Verification
      if (_verificationResult == null ||
          _verificationResult!['verified'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Verification required. Please verify with AI first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      String description = _descriptionController.text.isEmpty
          ? 'Logged $_selectedCategory'
          : _descriptionController.text;

      String? evidenceImageUrl;
      // Upload Evidence Image if exists
      if (_evidenceImage != null) {
        try {
          final bytes = await _evidenceImage!.readAsBytes();
          // On web, blob URLs don't have a real file extension; default to jpeg.
          final fileExt =
              kIsWeb ? 'jpeg' : _evidenceImage!.path.split('.').last;
          // Format: activity_evidence/{userId}/{timestamp}.ext
          final fileName =
              '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$fileExt';
          final storagePath = 'activity_evidence/$fileName';

          await Supabase.instance.client.storage
              .from('activity_evidence')
              .uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(contentType: 'image/$fileExt'),
              );

          evidenceImageUrl = Supabase.instance.client.storage
              .from('activity_evidence')
              .getPublicUrl(storagePath);
        } catch (e) {
          debugPrint('Image upload failed: $e');
          description += '\n[Image Upload Failed]';
        }
      }

      // Handle Verification Bonus & Data
      if (_verificationResult != null &&
          _verificationResult!['verified'] == true) {
        points += 50; // Bonus
        if (_verificationResult!['carbon_saved_estimate'] != null) {
          carbonSaved =
              (_verificationResult!['carbon_saved_estimate'] as num).toDouble();
        }
        description +=
            '\n\n[Verified by AI: Carbon=${carbonSaved}kg, Confidence=${_verificationResult!['confidence']}]';
        if (_verificationResult!['reasoning'] != null) {
          description += '\nReason: ${_verificationResult!['reasoning']}';
        }
      }

      // Ensure profile exists for this user to satisfy foreign key constraints
      final existingProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'display_name': user.userMetadata?['full_name'] ??
              (user.email != null ? user.email!.split('@')[0] : 'Eco User'),
          'points_balance': 0,
          'carbon_saved_kg': 0.0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 1. Add Activity to Supabase
      await Supabase.instance.client.from('activities').insert({
        'user_id': user.id,
        'category': _selectedCategory,
        'description': description,
        'carbon_saved': carbonSaved,
        'points_earned': points,
        'is_verified': _verificationResult != null &&
            _verificationResult!['verified'] == true,
        'verification_data': _verificationResult,
        'evidence_url': evidenceImageUrl,
        'logged_at': DateTime.now().toIso8601String(),
      });

      // 2. Update Profile (Fetch first then update)
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      final currentPoints = (profile['points_balance'] as num?) ?? 0;
      final currentCarbon = (profile['carbon_saved_kg'] as num?) ?? 0.0;

      await Supabase.instance.client.from('profiles').update({
        'points_balance': currentPoints + points,
        'carbon_saved_kg': currentCarbon + carbonSaved,
      }).eq('id', user.id);

      if (mounted) {
        Navigator.pop(context);
        widget.onLogged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity Logged! +$points Points'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Activity',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_isVerifying)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Select Category',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () =>
                          setState(() => _selectedCategory = entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.value,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key[0].toUpperCase() +
                                  entry.key.substring(1),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(height: 24),

              // Image Preview Section
              if (_evidenceImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: kIsWeb
                          ? Image.network(_evidenceImage!.path,
                              fit: BoxFit.cover)
                          : Image.file(File(_evidenceImage!.path),
                              fit: BoxFit.cover),
                    ),
                  ),
                ),

              // AI Verification Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('AI Authentication',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const Spacer(),
                        if (_verificationResult != null &&
                            _verificationResult!['verified'])
                          const Icon(Icons.check_circle, color: Colors.green)
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _verificationResult == null
                          ? 'Take a photo to verify this activity and earn Double Points!'
                          : (_verificationResult!['reasoning'] ??
                              (_verificationResult!['verified']
                                  ? 'Verified!'
                                  : 'Could not verify.')),
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    if (_verificationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_verificationError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 12),
                    if (_verificationResult == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isVerifying ? null : _pickAndVerifyImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Verify with Camera'),
                        ),
                      ),
                    // Show Verification Metadata
                    if (_verificationResult != null &&
                        (_deviceInfo != null ||
                            _imageMetadata != null ||
                            _deviceLocation != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildVerificationMetadata(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Impact Section: Show Slider OR Verified details
              if (_verificationResult != null &&
                  _verificationResult!['verified']) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Verified Impact',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                              '${(_sliderValue * 0.5).toStringAsFixed(1)} kg CO₂',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981))),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Points Earned',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${(_sliderValue * 10).toInt() + 50}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber)),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Impact Estimate',
                    style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  value: _sliderValue,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _sliderValue.round().toString(),
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => _sliderValue = val),
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isVerifying) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _verificationResult != null &&
                                  _verificationResult!['verified']
                              ? 'Log Verified Activity'
                              : 'Log Activity',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationMetadata() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      leading: const Icon(Icons.info_outline, size: 18, color: Colors.blue),
      title: const Text(
        'Verification Metadata',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
      ),
      children: [
        // Device Information
        if (_deviceInfo != null && _deviceInfo!.isNotEmpty) ...[
          _buildMetadataSection(
            'Device Information',
            Icons.phone_android,
            _deviceInfo!,
          ),
          const SizedBox(height: 8),
        ],

        // Image Metadata (EXIF)
        if (_imageMetadata != null && _imageMetadata!.isNotEmpty) ...[
          _buildMetadataSection(
            'Image Metadata (EXIF)',
            Icons.image,
            _imageMetadata!,
          ),
          const SizedBox(height: 8),
        ],

        // Device Location
        if (_deviceLocation != null) ...[
          _buildMetadataSection(
            'Device Location',
            Icons.location_on,
            {
              'Latitude':
                  _deviceLocation!['latitude']?.toStringAsFixed(6) ?? 'N/A',
              'Longitude':
                  _deviceLocation!['longitude']?.toStringAsFixed(6) ?? 'N/A',
              'Accuracy':
                  '${(_deviceLocation!['accuracy'] ?? 0).toStringAsFixed(1)}m',
            },
          ),
          const SizedBox(height: 8),
        ],

        // Image Timestamp
        if (_imageTimestamp != null) ...[
          _buildMetadataSection(
            'Image Timestamp',
            Icons.access_time,
            {
              'Date Taken': _imageTimestamp!.toLocal().toString().split('.')[0],
              'Time Since': _getTimeSince(_imageTimestamp!),
            },
          ),
          const SizedBox(height: 8),
        ],

        // Verification Result Metadata
        if (_verificationResult != null) ...[
          _buildMetadataSection(
            'Verification Result',
            Icons.verified,
            {
              'Verified':
                  _verificationResult!['verified'] == true ? 'Yes' : 'No',
              'Confidence': _verificationResult!['confidence'] != null
                  ? '${((_verificationResult!['confidence'] as num) * 100).toStringAsFixed(1)}%'
                  : 'N/A',
              'Verification Time':
                  _verificationResult!['verification_timestamp'] != null
                      ? DateTime.parse(
                              _verificationResult!['verification_timestamp'])
                          .toLocal()
                          .toString()
                          .split('.')[0]
                      : 'N/A',
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataSection(
      String title, IconData icon, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _getTimeSince(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
  }
}
