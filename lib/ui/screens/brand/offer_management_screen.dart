import 'package:ecoins/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class OfferManagementScreen extends StatefulWidget {
  const OfferManagementScreen({super.key});

  @override
  State<OfferManagementScreen> createState() => _OfferManagementScreenState();
}

class _OfferManagementScreenState extends State<OfferManagementScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String? _brandId;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get Brand ID first
      final brand = await Supabase.instance.client
          .from('brands')
          .select('id')
          .eq('owner_user_id', user.id)
          .single();

      _brandId = brand['id'];

      final data = await Supabase.instance.client
          .from('offers')
          .select()
          .eq('brand_id', _brandId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOffer(
      {String? id,
      required String title,
      required String description,
      required int cost}) async {
    if (_brandId == null) return;
    try {
      if (id != null) {
        // Update
        await Supabase.instance.client.from('offers').update({
          'title': title,
          'description': description,
          'points_cost': cost,
        }).eq('id', id);
      } else {
        // Create
        await Supabase.instance.client.from('offers').insert({
          'brand_id': _brandId,
          'title': title,
          'description': description,
          'points_cost': cost,
          'is_active': true,
        });
      }
      _fetchOffers();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showOfferDialog({Map<String, dynamic>? offer}) {
    final titleController =
        TextEditingController(text: offer != null ? offer['title'] : '');
    final descriptionController =
        TextEditingController(text: offer != null ? offer['description'] : '');
    final costController = TextEditingController(
        text: offer != null ? offer['points_cost'].toString() : '500');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offer != null ? 'Edit Offer' : 'New Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Offer Title',
                    hintText: 'e.g. 20% Off Next Order')),
            const SizedBox(height: 12),
            TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your offer...'),
                maxLines: 2),
            const SizedBox(height: 12),
            TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Points Cost'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                _saveOffer(
                    id: offer?['id'],
                    title: titleController.text,
                    description: descriptionController.text,
                    cost: int.tryParse(costController.text) ?? 500);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen),
            child: Text(offer != null ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOffer(String id) async {
    try {
      await Supabase.instance.client.from('offers').delete().eq('id', id);
      setState(() {
        _offers.removeWhere((o) => o['id'] == id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen)));

    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Active Campaigns',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textMain)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
            IconThemeData(color: isDark ? Colors.white : AppTheme.textMain),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOfferDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _offers.isEmpty
          ? Center(
              child: Text('No active offers. Launch one!',
                  style: TextStyle(
                      color: isDark ? Colors.grey[400] : AppTheme.textSub)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final offer = _offers[index];
                return Card(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isDark
                        ? BorderSide(color: Colors.grey[800]!)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    onTap: () => _showOfferDialog(offer: offer),
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(offer['title'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.textMain)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (offer['description'] != null &&
                            (offer['description'] as String).isNotEmpty)
                          Text(
                            offer['description'],
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                fontSize: 13),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Cost: ${offer['points_cost']} pts • Created ${timeago.format(DateTime.parse(offer['created_at']))}',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: isDark ? Colors.grey[500] : Colors.grey),
                      onPressed: () => _deleteOffer(offer['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
