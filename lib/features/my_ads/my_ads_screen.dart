import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/property_visual.dart';
import '../../models/property.dart';
import '../../state/app_state_providers.dart';
import '../post_property/post_property_wizard.dart';
import '../property_detail/property_detail_screen.dart';
import 'edit_property_screen.dart';

class MyAdsScreen extends ConsumerStatefulWidget {
  const MyAdsScreen({super.key});

  @override
  ConsumerState<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends ConsumerState<MyAdsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Active', 'Pending', 'Sold', 'Drafts'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUserAds = ref.watch(propertiesProvider).where((p) => p.isUserPosted).toList();

    // Stats calculations
    final activeCount = allUserAds.where((p) => p.status == 'active').length;
    final pendingCount = allUserAds.where((p) => p.status == 'pending').length;
    final soldCount = allUserAds.where((p) => p.status == 'sold').length;
    final totalViews = allUserAds.fold<int>(0, (sum, p) => sum + p.views);
    final totalEnquiries = allUserAds.fold<int>(0, (sum, p) => sum + p.enquiries);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Properties & Ads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(propertiesProvider.notifier).refresh(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelLarge,
          tabs: [
            Tab(text: 'Active ($activeCount)'),
            Tab(text: 'Pending ($pendingCount)'),
            Tab(text: 'Sold ($soldCount)'),
            const Tab(text: 'Drafts (0)'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostPropertyWizard()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Post Property',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      body: Column(
        children: [
          // Dashboard Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Listings', '${allUserAds.length}', Icons.apartment_rounded),
                _buildDivider(),
                _buildStatItem('Total Views', '$totalViews', Icons.visibility_outlined),
                _buildDivider(),
                _buildStatItem('Total Enquiries', '$totalEnquiries', Icons.chat_bubble_outline_rounded),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdsList(allUserAds.where((p) => p.status == 'active').toList(), 'active'),
                _buildAdsList(allUserAds.where((p) => p.status == 'pending').toList(), 'pending'),
                _buildAdsList(allUserAds.where((p) => p.status == 'sold').toList(), 'sold'),
                _buildAdsList([], 'draft'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.h4.copyWith(fontSize: 16, color: AppColors.textPrimary)),
            Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28, color: AppColors.borderLight);
  }

  Widget _buildAdsList(List<Property> ads, String tabType) {
    if (ads.isEmpty) {
      String title = 'No $tabType listings';
      String msg = tabType == 'active'
          ? 'You do not have any active ads right now. Post your property in 2 minutes!'
          : 'No properties currently in $tabType status.';

      return EmptyStateView(
        icon: Icons.holiday_village_outlined,
        title: title,
        message: msg,
        actionText: '+ Post Property Now',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostPropertyWizard()),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return _buildUserAdCard(ad);
      },
    );
  }

  Widget _buildUserAdCard(Property ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Top row: thumbnail + details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                PropertyVisual(
                  propertyType: ad.propertyType,
                  width: 95,
                  height: 95,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 14),
                // Title, Price, Location, Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(ad.status),
                          Text(
                            ad.propertyType,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ad.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h4.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatIndianPrice(ad.price, isRental: ad.isRental),
                        style: AppTextStyles.priceMedium.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              ad.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Bar: Views & Enquiries
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceAlt,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text('${ad.views} Views', style: AppTextStyles.labelSmall),
                    const SizedBox(width: 14),
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text('${ad.enquiries} Enquiries', style: AppTextStyles.labelSmall),
                  ],
                ),
                Text(
                  'ID: ${ad.id.split('_').last}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // Actions Row: Preview, Edit, Mark as Sold, Delete
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Preview
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PropertyDetailScreen(propertyId: ad.id)),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Preview'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),

                // Edit
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditPropertyScreen(property: ad)),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),

                // Mark Sold
                if (ad.status != 'sold')
                  TextButton.icon(
                    onPressed: () => _confirmMarkSold(ad),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.warning),
                    label: Text('Sold', style: TextStyle(color: AppColors.warning, fontSize: 13)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),

                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  tooltip: 'Delete Ad',
                  onPressed: () => _confirmDelete(ad),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = 'Active';
        break;
      case 'pending':
        bg = AppColors.warningLight;
        text = AppColors.warning;
        label = 'In Review';
        break;
      case 'sold':
        bg = const Color(0xFFECEFF1);
        text = const Color(0xFF455A64);
        label = 'Sold';
        break;
      default:
        bg = AppColors.surfaceAlt;
        text = AppColors.textSecondary;
        label = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _confirmMarkSold(Property ad) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Mark as Sold/Rented?'),
        content: Text('Are you sure you want to mark "${ad.title}" as Sold? It will be moved to the Sold tab.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(propertiesProvider.notifier).markAsSold(ad.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Listing marked as Sold!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm Sold'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Property ad) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Listing?'),
        content: Text('This will remove "${ad.title}" permanently from your local device listings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(propertiesProvider.notifier).deleteProperty(ad.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Property deleted from device storage.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
