import 'dart:io';
import 'package:ecoins/core/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ecoins/ui/widgets/scale_button.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController(); // Added Bio

  XFile? _imageFile;
  String? _currentAvatarUrl;

  bool _isLoading = false;
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['display_name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _currentAvatarUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentAvatarUrl;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = kIsWeb ? 'png' : _imageFile!.path.split('.').last.toLowerCase();
      // Fixed path per user — upsert replaces the previous file cleanly
      final filePath = '$userId/avatar.$fileExt';

      final bytes = await _imageFile!.readAsBytes();

      await _supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Cache-busting timestamp ensures the app reloads the new image
      final baseUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      return '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      String? avatarUrl = _currentAvatarUrl;
      if (_imageFile != null) {
        final uploaded = await _uploadImage();
        if (uploaded != null) {
           avatarUrl = uploaded;
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image. Saving text only.')));
        }
      }

      await _supabase.from('profiles').update({
        'display_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark
        ? [AppTheme.backgroundDark, const Color(0xFF1A1A2E)]
        : [AppTheme.backgroundLight, const Color(0xFFF0F9FF)];

    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      if (kIsWeb) {
        backgroundImage = NetworkImage(_imageFile!.path);
      } else {
        backgroundImage = FileImage(File(_imageFile!.path));
      }
    } else if (_currentAvatarUrl != null) {
      backgroundImage = NetworkImage(_currentAvatarUrl!);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Edit Profile',
            style: GoogleFonts.outfit(
                color: isDark ? Colors.white : AppTheme.textMain,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : AppTheme.textMain),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 40),
          child: Column(
            children: [
              // Avatar Edit
              ZoomIn(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _pickImage();
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: backgroundImage,
                          child: (backgroundImage == null)
                              ? Icon(Icons.person,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400])
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.4), blurRadius: 8)]
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    _buildLabel('Display Name', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(context, _nameController, 'Enter your name',
                        isDark, Icons.person_outline),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Column(
                   children: [
                      _buildLabel('Bio', isDark),
                      const SizedBox(height: 8),
                      _buildTextField(context, _bioController, 'Tell us about yourself',
                          isDark, Icons.info_outline,
                          maxLines: 3),
                   ],
                ),
              ),

              const SizedBox(height: 40),

              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: ScaleButton(
                    onTap: _isLoading ? () {} : () {
                       HapticFeedback.mediumImpact();
                       _saveProfile();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Save Changes',
                              style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller,
      String hint, bool isDark, IconData icon,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style:
            GoogleFonts.inter(color: isDark ? Colors.white : AppTheme.textMain),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.grey)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Icon(icon, color: Colors.grey)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
