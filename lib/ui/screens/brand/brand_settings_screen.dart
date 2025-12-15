import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

class BrandSettingsScreen extends StatefulWidget {
  const BrandSettingsScreen({super.key});

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = true;
  String? _logoUrl;
  File? _logoFile;
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _brandId;

  @override
  void initState() {
    super.initState();
    _fetchBrandData();
  }

  Future<void> _fetchBrandData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('brands')
          .select()
          .eq('owner_user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _brandId = data['id'];
          _nameController.text = data['name'];
          _websiteController.text = data['website_url'] ?? '';
          _logoUrl = data['logo_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching brand settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_brandId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      String? logoUrl = _logoUrl;
      
      // Upload Logo if changed
      if (_logoFile != null) {
        final fileExt = _logoFile!.path.split('.').last;
        final fileName = '$_brandId/logo_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        await _supabase.storage.from('brand-logos').upload(fileName, _logoFile!, fileOptions: const FileOptions(upsert: true));
        logoUrl = _supabase.storage.from('brand-logos').getPublicUrl(fileName);
      }

      await _supabase.from('brands').update({
        'name': _nameController.text,
        'website_url': _websiteController.text,
        'logo_url': logoUrl,
      }).eq('id', _brandId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Brand Settings', style: GoogleFonts.outfit(color: isDark ? Colors.white : AppTheme.textMain)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                   Container(
                     width: 100,
                     height: 100,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: isDark ? Colors.grey[800] : Colors.white,
                       border: Border.all(color: AppTheme.primaryGreen, width: 2),
                       image: _logoFile != null 
                         ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                         : (_logoUrl != null ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.cover) : null),
                     ),
                     child: (_logoFile == null && _logoUrl == null)
                       ? Icon(Icons.store, size: 50, color: isDark ? Colors.grey[400] : Colors.grey)
                       : null,
                   ),
                   Positioned(
                     bottom: 0,
                     right: 0,
                     child: InkWell(
                       onTap: _pickImage,
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: const BoxDecoration(
                           color: AppTheme.primaryGreen,
                           shape: BoxShape.circle,
                         ),
                         child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                       ),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            Text('Brand Profile', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
            const SizedBox(height: 16),
            
            _buildTextField('Brand Name', _nameController, isDark),
            const SizedBox(height: 16),
            _buildTextField('Website URL', _websiteController, isDark),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save Changes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
          ),
        ),
      ],
    );
  }
}
