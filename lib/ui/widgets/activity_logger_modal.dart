import 'dart:io';
import 'package:ecoins/core/theme.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class ActivityLoggerModal extends StatefulWidget {
  final VoidCallback onLogged;
  final String? initialCategory;

  const ActivityLoggerModal(
      {super.key, required this.onLogged, this.initialCategory});

  @override
  State<ActivityLoggerModal> createState() => _ActivityLoggerModalState();
}

class _ActivityLoggerModalState extends State<ActivityLoggerModal> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  XFile? _evidenceImage;
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;
  String? _verificationError;

  final Map<String, IconData> _categories = {
    'transport': Icons.directions_bus,
    'energy': Icons.bolt,
    'food': Icons.restaurant,
    'recycle': Icons.recycling,
    'shopping': Icons.shopping_bag,
  };

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isVerified =>
      _verificationResult != null && _verificationResult!['verified'] == true;

  bool get _isRejected =>
      _verificationResult != null && _verificationResult!['verified'] != true;

  Future<void> _pickAndVerifyImage() async {
    setState(() {
      _isVerifying = true;
      _verificationError = null;
      _verificationResult = null;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (photo == null) {
        setState(() => _isVerifying = false);
        return;
      }

      setState(() => _evidenceImage = photo);

      // Get device location
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

      // Read EXIF timestamp and GPS
      DateTime? imageDate;
      Map<String, dynamic>? imageLocation;

      if (!kIsWeb && photo.path.isNotEmpty) {
        try {
          final exif = await Exif.fromPath(photo.path);
          final dateString = await exif.getOriginalDate();
          if (dateString != null) imageDate = dateString;

          try {
            final latLong = await exif.getLatLong();
            if (latLong != null) {
              imageLocation = {
                'latitude': latLong.latitude,
                'longitude': latLong.longitude,
              };
            }
          } catch (_) {}

          await exif.close();
        } catch (e) {
          debugPrint('Exif error: $e');
        }
      }

      // Get device info
      Map<String, dynamic> deviceInfo = {};
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        if (kIsWeb) {
          final webInfo = await deviceInfoPlugin.webBrowserInfo;
          deviceInfo = {
            'platform': 'Web',
            'browserName': webInfo.browserName.name,
          };
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfoPlugin.androidInfo;
          deviceInfo = {
            'platform': 'Android',
            'manufacturer': androidInfo.manufacturer,
            'model': androidInfo.model,
            'version': androidInfo.version.release,
          };
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfoPlugin.iosInfo;
          deviceInfo = {
            'platform': 'iOS',
            'model': iosInfo.model,
            'systemVersion': iosInfo.systemVersion,
          };
        }
      } catch (e) {
        debugPrint('Device info error: $e');
      }

      // Freshness check — photo must be from the last hour
      imageDate ??= DateTime.now();
      final ageMinutes = DateTime.now().difference(imageDate).inMinutes.abs();
      if (ageMinutes > 60) {
        setState(() {
          _verificationError =
              'This photo is $ageMinutes minutes old. Please take a fresh photo right now.';
          _isVerifying = false;
        });
        return;
      }

      // Location cross-check
      if (devicePosition != null && imageLocation != null) {
        final distance = Geolocator.distanceBetween(
          devicePosition.latitude,
          devicePosition.longitude,
          imageLocation['latitude']!,
          imageLocation['longitude']!,
        );
        if (distance > 100) {
          setState(() {
            _verificationError =
                'Location mismatch detected. Make sure GPS is on and take the photo at the activity location.';
            _isVerifying = false;
          });
          return;
        }
      }

      if (_selectedCategory == null) {
        setState(() {
          _verificationError = 'Please select a category first.';
          _isVerifying = false;
        });
        return;
      }

      final result = await _callVerifyEdgeFunction(
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
        imageDate.toIso8601String(),
      );

      setState(() {
        _verificationResult = result;
        if (result['description'] != null) {
          _descriptionController.text = result['description'] as String;
        }
      });
    } catch (e) {
      setState(() => _verificationError = 'Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<Map<String, dynamic>> _callVerifyEdgeFunction(
    XFile image,
    String category,
    Map<String, dynamic> deviceInfo,
    Map<String, dynamic>? location,
    String? imageTimestamp,
  ) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await Supabase.instance.client.functions.invoke(
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

      if (result['error'] != null && result['verified'] == false) {
        final errMsg = result['error'].toString();
        if (errMsg.contains('API key') || errMsg.contains('provider')) {
          throw Exception('AI service is temporarily unavailable.');
        }
        throw Exception(errMsg);
      }

      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Edge function error: $e');
      return {
        'verified': false,
        'rejection_reason':
            'We couldn\'t connect to our AI verifier. Please check your connection and try again.',
        'error': e.toString(),
      };
    }
  }

  void _retryVerification() {
    setState(() {
      _verificationResult = null;
      _verificationError = null;
      _evidenceImage = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedCategory == null || !_isVerified) return;
    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Points and carbon are server-determined — never trust the client
      final int points =
          (_verificationResult!['points_awarded'] as num?)?.toInt() ?? 50;
      final double carbonSaved =
          (_verificationResult!['carbon_saved_estimate'] as num?)?.toDouble() ??
              0.0;

      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'Verified ${_selectedCategory![0].toUpperCase()}${_selectedCategory!.substring(1)} activity';

      // Upload evidence image
      String? evidenceImageUrl;
      if (_evidenceImage != null) {
        try {
          final bytes = await _evidenceImage!.readAsBytes();
          final fileExt = kIsWeb ? 'jpeg' : _evidenceImage!.path.split('.').last;
          final fileName =
              '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$fileExt';
          await Supabase.instance.client.storage
              .from('activity_evidence')
              .uploadBinary(
                'activity_evidence/$fileName',
                bytes,
                fileOptions: FileOptions(contentType: 'image/$fileExt'),
              );
          evidenceImageUrl = Supabase.instance.client.storage
              .from('activity_evidence')
              .getPublicUrl('activity_evidence/$fileName');
        } catch (e) {
          debugPrint('Image upload failed: $e');
        }
      }

      // Insert activity
      await Supabase.instance.client.from('activities').insert({
        'user_id': user.id,
        'category': _selectedCategory,
        'description': description,
        'carbon_saved': carbonSaved,
        'points_earned': points,
        'is_verified': true,
        'verification_data': _verificationResult,
        'evidence_url': evidenceImageUrl,
        'logged_at': DateTime.now().toIso8601String(),
      });

      // Update profile totals
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
            content: Text('Activity logged! +$points pts earned 🌱'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textMain,
                  ),
                ),
                if (_isVerifying)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryGreen),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'AI verifies your photo and sets the points.',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : AppTheme.textSub),
            ),
            const SizedBox(height: 24),

            // Category picker
            Text('Select Category',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : AppTheme.textMain)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: _isVerified
                          ? null
                          : () => setState(() {
                                _selectedCategory = entry.key;
                                _verificationResult = null;
                                _verificationError = null;
                                _evidenceImage = null;
                              }),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : (isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(entry.value,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700)),
                            const SizedBox(width: 6),
                            Text(
                              entry.key[0].toUpperCase() +
                                  entry.key.substring(1),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700),
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

              // Evidence image preview
              if (_evidenceImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: kIsWeb
                              ? Image.network(_evidenceImage!.path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_evidenceImage!.path),
                                  fit: BoxFit.cover),
                        ),
                      ),
                      if (!_isVerified)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _retryVerification,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // ── Verification result states ──────────────────────────────

              // 1. Not yet verified — show camera prompt
              if (!_isVerified && !_isRejected)
                _buildVerifyPromptCard(isDark),

              // 2. Rejected — show friendly rejection card
              if (_isRejected) _buildRejectionCard(isDark),

              // 3. Verified — show reward summary
              if (_isVerified) _buildRewardCard(isDark),

              // Description field (shown after verification attempt)
              if (_isVerified) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : AppTheme.textMain),
                  decoration: InputDecoration(
                    labelText: 'Add a note (optional)',
                    labelStyle: GoogleFonts.inter(
                        color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryGreen, width: 2),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit button — only visible when verified
              if (_isVerified)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Claim My Points',
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── UI sub-widgets ────────────────────────────────────────────────────────

  Widget _buildVerifyPromptCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.shade900.withAlpha(80) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.blue.shade700.withAlpha(80)
                : const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Take a photo to verify',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D4ED8),
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI will check your photo and automatically calculate the points and CO₂ saved. No manual input needed.',
            style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.blue.shade200 : const Color(0xFF1E40AF)),
          ),
          if (_verificationError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_verificationError!,
                        style: GoogleFonts.inter(
                            color: Colors.red.shade700, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : _pickAndVerifyImage,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.camera_alt, size: 18),
              label: Text(
                _isVerifying ? 'Analysing…' : 'Open Camera',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard(bool isDark) {
    final rejectionReason = _verificationResult?['rejection_reason'] as String?;
    final message = (rejectionReason != null && rejectionReason.isNotEmpty)
        ? rejectionReason
        : 'This activity couldn\'t be verified as eco-friendly. Please try a clearer photo that directly shows the action.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.shade900.withAlpha(60)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.orange.shade700.withAlpha(80)
                : const Color(0xFFFDBA74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: Colors.orange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Activity not verified',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.orange.shade300
                          : const Color(0xFF9A3412),
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? Colors.orange.shade200
                    : const Color(0xFF7C2D12)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _retryVerification,
              icon: const Icon(Icons.camera_alt, size: 16),
              label: Text('Try a different photo',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(bool isDark) {
    final points =
        (_verificationResult!['points_awarded'] as num?)?.toInt() ?? 0;
    final co2 = (_verificationResult!['carbon_saved_estimate'] as num?)
            ?.toStringAsFixed(2) ??
        '0.00';
    final confidence = _verificationResult!['confidence'];
    final confidencePct = confidence != null
        ? '${((confidence as num) * 100).toStringAsFixed(0)}%'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryGreen.withAlpha(30)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? AppTheme.primaryGreen.withAlpha(60)
                : const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Activity verified!',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.primaryGreen
                        : const Color(0xFF14532D),
                    fontSize: 15),
              ),
              if (confidencePct != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(confidencePct,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRewardStat(
                    Icons.savings_outlined,
                    '+$points pts',
                    'Points earned',
                    Colors.amber,
                    isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRewardStat(
                    Icons.cloud_outlined,
                    '$co2 kg',
                    'CO₂ saved',
                    const Color(0xFF3B82F6),
                    isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardStat(
      IconData icon, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppTheme.textMain)),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : AppTheme.textSub)),
            ],
          ),
        ],
      ),
    );
  }
}
