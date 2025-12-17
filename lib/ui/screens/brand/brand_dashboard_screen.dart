import 'package:ecoins/core/theme.dart';
import 'package:ecoins/ui/screens/brand/offer_management_screen.dart';
import 'package:ecoins/ui/screens/brand/widget_integration_screen.dart';
import 'package:ecoins/ui/screens/brand/brand_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BrandDashboardScreen extends StatefulWidget {
  const BrandDashboardScreen({super.key});

  @override
  State<BrandDashboardScreen> createState() => _BrandDashboardScreenState();
}

class _BrandDashboardScreenState extends State<BrandDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _brand;
  int _activeOffersCount = 0;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchBrandData();
  }

  Future<void> _fetchBrandData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      // Fetch brand associated with user
      final data = await _supabase
          .from('brands')
          .select()
          .eq('owner_user_id', user.id)
          .maybeSingle();

      // Fetch active offers count for this brand
      int offersCount = 0;
      if (data != null) {
        final offers = await _supabase
            .from('offers')
            .select('id')
            .eq('brand_id', data['id'])
            .eq('is_active', true);
        offersCount = offers.length;
      }

      if (mounted) {
        setState(() {
          _brand = data;
          _activeOffersCount = offersCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching brand: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBrand() async {
    // Navigate to onboarding or show dialog
    // check if we need to implement BrandOnboardingScreen
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_brand == null) {
      return _buildOnboardingView(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Brand Portal', style: GoogleFonts.outfit(color: isDark ? Colors.white : AppTheme.textMain, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrandSettingsScreen()),
              ).then((_) {
                // Refresh data after returning from settings
                _fetchBrandData();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF1B5E20), const Color(0xFF004D40)] 
                      : [AppTheme.primaryGreen, Colors.teal.shade400], 
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      image: _brand!['logo_url'] != null ? DecorationImage(image: NetworkImage(_brand!['logo_url']), fit: BoxFit.cover) : null,
                    ),
                    child: _brand!['logo_url'] == null 
                      ? Center(child: Text(_brand!['name'][0], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)))
                      : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _brand!['name'],
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _brand!['website_url'] ?? 'No website',
                          style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Carbon Saved', '0 kg', Icons.cloud_outlined, Colors.teal, isDark),
                _buildStatCard('Active Offers', '$_activeOffersCount', Icons.local_offer_outlined, Colors.orange, isDark),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('Management', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
            const SizedBox(height: 16),
            
            _buildMenuTile(
              title: 'Campaigns & Offers',
              subtitle: 'Create and manage discount codes',
              icon: Icons.campaign_outlined,
              color: Colors.purple,
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfferManagementScreen())),
            ),
            const SizedBox(height: 12),
            _buildMenuTile(
              title: 'Widget Integration',
              subtitle: 'Get embed code for your website',
              icon: Icons.code,
              color: Colors.blue,
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WidgetIntegrationScreen())),
            ),
             const SizedBox(height: 12),
            _buildMenuTile(
              title: 'Brand Settings',
              subtitle: 'Update profile and billing',
              icon: Icons.storefront_outlined,
              color: Colors.grey,
              isDark: isDark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandSettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingView(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Partner with Eco Rewards', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 80, color: isDark ? Colors.grey[700] : Colors.grey),
            const SizedBox(height: 20),
            Text('No Brand Found', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
             const SizedBox(height: 10),
            Text('Register your sustainable brand to get started.', style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                 final result = await Navigator.push(
                   context,
                   MaterialPageRoute(builder: (_) => const CreateBrandScreen()),
                 );
                 // Refresh data after returning from creation
                 if (mounted && result == true) {
                   await _fetchBrandData();
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Register Brand'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
          Text(title, style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required String title, required String subtitle, required IconData icon, required Color color, required bool isDark, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey.shade100)
      ),
      tileColor: isDark ? AppTheme.surfaceDark : Colors.white,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.grey)),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey),
    );
  }
}

class CreateBrandScreen extends StatefulWidget {
  const CreateBrandScreen({super.key});

  @override
  State<CreateBrandScreen> createState() => _CreateBrandScreenState();
}

class _CreateBrandScreenState extends State<CreateBrandScreen> {
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isLoading = false;
  File? _logoFile;
  String? _logoPreview;
  bool _isDragging = false;
  final _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _logoFile = File(pickedFile.path);
          _logoPreview = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _handleDragEnter() {
    setState(() => _isDragging = true);
  }

  void _handleDragLeave() {
    setState(() => _isDragging = false);
  }

  Future<void> _handleFileDrop() async {
    setState(() => _isDragging = false);
    await _pickImage();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a brand name')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) context.go('/brand-auth');
        return;
      }

      String? logoUrl;

      // Upload logo if provided
      if (_logoFile != null) {
        try {
          final fileExt = _logoFile!.path.split('.').last;
          final fileName = '${user.id}/logo_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          
          final bytes = await _logoFile!.readAsBytes();
          await _supabase.storage.from('brand-logos').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
          logoUrl = _supabase.storage.from('brand-logos').getPublicUrl(fileName);
        } catch (e) {
          debugPrint('Error uploading logo: $e');
          // Continue without logo if upload fails
        }
      }

      // Create brand
      await _supabase.from('brands').insert({
        'owner_user_id': user.id,
        'name': _nameController.text.trim(),
        'website_url': _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        'logo_url': logoUrl,
      });
      
      if (mounted) {
        // Navigate back to dashboard which will refresh and show the brand
        Navigator.pop(context, true);
        // The dashboard will automatically refresh when we return
        // because it checks in initState or we can trigger refresh
      }
    } catch(e) {
      debugPrint('Error creating brand: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Register Brand', style: GoogleFonts.outfit(color: isDark ? Colors.white : AppTheme.textMain)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete Your Brand Profile',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your brand information to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : AppTheme.textSub,
              ),
            ),
            const SizedBox(height: 32),

            // Logo Upload with Drag and Drop
            Text(
              'Brand Logo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            MouseRegion(
              onEnter: (_) => _handleDragEnter(),
              onExit: (_) => _handleDragLeave(),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: _isDragging
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : (isDark ? AppTheme.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isDragging
                          ? AppTheme.primaryGreen
                          : (isDark ? Colors.grey[700]! : Colors.grey.shade300),
                      width: _isDragging ? 2 : 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _logoPreview != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_logoPreview!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _logoFile = null;
                                    _logoPreview = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Drag & drop your logo here',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'or tap to browse',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Brand Name
            Text(
              'Brand Name',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Enter your brand name',
                filled: true,
                fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Website URL
            Text(
              'Website URL (Optional)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _websiteController,
              keyboardType: TextInputType.url,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'https://yourbrand.com',
                prefixIcon: const Icon(Icons.language),
                filled: true,
                fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Complete Registration',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
