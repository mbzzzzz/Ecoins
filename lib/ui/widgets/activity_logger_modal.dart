import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_exif/native_exif.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          devicePosition = await Geolocator.getCurrentPosition();
        }
      } catch (e) {
        debugPrint('Location error: $e');
      }

      // 3. Read Exif (Metadata)
      DateTime? imageDate;
      if (!kIsWeb && !this.isEmpty(photo.path)) {
        try {
          final exif = await Exif.fromPath(photo.path);
          final dateString = await exif.getOriginalDate();
          if (dateString != null) {
            imageDate = dateString; 
          }
          await exif.close();
        } catch (e) {
             debugPrint('Exif error: $e');
        }
      }

      // 4. Verification Logic
      // Cross-check: Image must be recent (within 1 hour)
      if (imageDate != null) {
        final now = DateTime.now();
        final diff = now.difference(imageDate).inMinutes.abs();
        if (diff > 60) {
           setState(() => _verificationError = 'Image is too old. Please take a new photo.');
           _isVerifying = false;
           return;
        }
        // TODO: Could also check location distance here if we had metadata location
      }

      // 5. Call Groq AI Vision
      if (_selectedCategory == null) {
         setState(() => _verificationError = 'Select a category first.');
         _isVerifying = false;
         return;
      }

      final result = await _analyzeWithGroq(photo, _selectedCategory!);
      
      setState(() {
        _verificationResult = result;
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

  Future<Map<String, dynamic>> _analyzeWithGroq(XFile image, String category) async {
    // API key should be stored in environment variables or Supabase secrets
    // For now, using placeholder - replace with actual secure storage
    const apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'PLACEHOLDER_API_KEY');
    
    if (apiKey == 'PLACEHOLDER_API_KEY' || apiKey.startsWith('PLACEHOLDER')) {
      await Future.delayed(const Duration(seconds: 2));
      return {
        'verified': true,
        'confidence': 0.95,
        'carbon_saved_estimate': 1.5,
        'reasoning': 'Detected reusable bag. Mock mode.',
        'description': 'Shopping with reusable bags'
      };
    }

    // Read bytes (works on web and mobile for XFile)
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text', 
                'text': 'Verify if this image represents the eco-friendly activity category: "$category". '
                        'Output JSON only with keys: verified (bool), confidence (0-1), carbon_saved_estimate (kg, conservative), reasoning (string), description (short summary).'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'temperature': 0.1,
        'max_tokens': 300,
        'response_format': {'type': 'json_object'} 
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return jsonDecode(content);
    } else {
      throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
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
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to save activities.')));
           Navigator.pop(context);
        }
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
          final fileExt = kIsWeb ? 'jpeg' : _evidenceImage!.path.split('.').last;
          // Format: activity_evidence/{userId}/{timestamp}.ext
          final fileName = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$fileExt';
          final storagePath = 'activity_evidence/$fileName';

          await Supabase.instance.client.storage.from('activity_evidence').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

          evidenceImageUrl = Supabase.instance.client.storage.from('activity_evidence').getPublicUrl(storagePath);
        } catch (e) {
          debugPrint('Image upload failed: $e');
          description += '\n[Image Upload Failed]';
        }
      }

      // Handle Verification Bonus & Data
      if (_verificationResult != null && _verificationResult!['verified'] == true) {
         points += 50; // Bonus
         if (_verificationResult!['carbon_saved_estimate'] != null) {
           carbonSaved = (_verificationResult!['carbon_saved_estimate'] as num).toDouble();
         }
         description += '\n\n[Verified by AI: Carbon=${carbonSaved}kg, Confidence=${_verificationResult!['confidence']}]';
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
        'is_verified': _verificationResult != null && _verificationResult!['verified'] == true,
        'verification_data': _verificationResult,
        'evidence_url': evidenceImageUrl,
        'logged_at': DateTime.now().toIso8601String(), 
      });

      // 2. Update Profile (Fetch first then update)
      final profile = await Supabase.instance.client.from('profiles').select().eq('id', user.id).single();
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_isVerifying)
                  const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981))
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            Text('Select Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.value,
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key[0].toUpperCase() + entry.key.substring(1),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
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
                          ? Image.network(_evidenceImage!.path, fit: BoxFit.cover)
                          : Image.file(File(_evidenceImage!.path), fit: BoxFit.cover),
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
                        const Text('AI Authentication', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const Spacer(),
                        if (_verificationResult != null && _verificationResult!['verified'])
                           const Icon(Icons.check_circle, color: Colors.green)
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _verificationResult == null 
                          ? 'Take a photo to verify this activity and earn Double Points!'
                          : (_verificationResult!['reasoning'] ?? (_verificationResult!['verified'] ? 'Verified!' : 'Could not verify.')),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    if (_verificationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_verificationError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Impact Section: Show Slider OR Verified details
              if (_verificationResult != null && _verificationResult!['verified']) ...[
                 Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Verified Impact', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${(_sliderValue * 0.5).toStringAsFixed(1)} kg CO₂', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                       Column(
                        children: [
                          const Text('Points Earned', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${(_sliderValue * 10).toInt() + 50}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Impact Estimate', style: Theme.of(context).textTheme.titleSmall),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_verificationResult != null && _verificationResult!['verified'] ? 'Log Verified Activity' : 'Log Activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
