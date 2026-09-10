import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/app_state_providers.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'saved_searches_screen.dart';

class AccountScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToMyAds;

  const AccountScreen({super.key, this.onNavigateToMyAds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final favCount = ref.watch(favoritesListProvider).length;
    final myAdsCount = ref.watch(propertiesProvider).where((p) => p.isUserPosted).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryMedium],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryLight, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0] : 'M',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.name,
                                    style: AppTextStyles.h3.copyWith(fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (profile.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.phone,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  profile.city,
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 14),

                  // Profile Completion Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile Strength: Highly Completed',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${(profile.completionPercentage * 100).toInt()}%',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: profile.completionPercentage,
                          backgroundColor: AppColors.primaryLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Activity Section
            Text('My Real Estate Activity', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            _buildGroupedCard([
              _buildSettingsTile(
                icon: Icons.holiday_village_outlined,
                title: 'My Property Listings',
                subtitle: '$myAdsCount active & pending ads',
                badge: '$myAdsCount',
                onTap: () {
                  if (onNavigateToMyAds != null) {
                    onNavigateToMyAds!();
                  }
                },
              ),
              _buildSettingsTile(
                icon: Icons.favorite_border_rounded,
                title: 'Favorite Properties',
                subtitle: '$favCount saved in wishlist',
                badge: '$favCount',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.saved_search_rounded,
                title: 'Saved Searches & Alerts',
                subtitle: 'Custom filter notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedSearchesScreen()),
                  );
                },
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // 3. Preferences Section
            Text('Preferences & Settings', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            _buildGroupedCard([
              _buildSettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notification Center',
                subtitle: 'Alerts, price drops, messages',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.language_rounded,
                title: 'App Language',
                subtitle: 'English (UK / India)',
                trailingText: 'English',
                onTap: () {
                  _showToast(context, 'Language: English (Tamil support enabled in settings)');
                },
              ),
              _buildSettingsTile(
                icon: Icons.currency_rupee_rounded,
                title: 'Currency Format',
                subtitle: 'Indian Lakhs & Crores (INR)',
                trailingText: '₹ INR',
                onTap: () {
                  _showToast(context, 'Default Currency: Indian Rupee (₹)');
                },
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // 4. Support & About
            Text('Support & Legal', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            _buildGroupedCard([
              _buildSettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support FAQs',
                subtitle: 'Frequently asked questions',
                onTap: () {
                  _showFAQDialog(context);
                },
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Tenkasi Dreams Land',
                subtitle: 'தென்காசி கனவுகள் - Land Promoters',
                onTap: () {
                  _showAboutDialog(context);
                },
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // 5. Backend Server & Architecture
            Text('Server & Production Architecture', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            _buildGroupedCard([
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (ApiConfig.instance.isOnlineMode ? AppColors.primary : AppColors.accentGold).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.dns_rounded,
                    color: ApiConfig.instance.isOnlineMode ? AppColors.primary : AppColors.accentGold,
                    size: 20,
                  ),
                ),
                title: const Text('Backend API Server', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  ApiConfig.instance.isOnlineMode
                      ? 'Live REST API: ${ApiConfig.instance.serverUrl}'
                      : 'Offline Cache Active (Ready for Server Host)',
                  style: AppTextStyles.bodySmall,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ApiConfig.instance.isOnlineMode ? AppColors.primaryLight : AppColors.accentGoldLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ApiConfig.instance.isOnlineMode ? AppColors.primary : AppColors.accentGold,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    ApiConfig.instance.isOnlineMode ? 'ONLINE API' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ApiConfig.instance.isOnlineMode ? AppColors.primary : AppColors.accentGold,
                    ),
                  ),
                ),
                onTap: () => _showServerConfigDialog(context, ref),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildSettingsTile(
                icon: Icons.sync_rounded,
                iconColor: AppColors.primary,
                title: 'Sync with Remote Server',
                subtitle: 'Push/pull properties with configured endpoint',
                onTap: () async {
                  final synced = await ref.read(propertiesProvider.notifier).syncWithServer();
                  if (context.mounted) {
                    _showToast(
                      context,
                      synced
                          ? 'Synchronized with ${ApiConfig.instance.serverUrl} successfully!'
                          : 'Offline Mode: Served from fast local cache.',
                    );
                  }
                },
                isLast: true,
              ),
            ]),

            const SizedBox(height: 24),

            // 6. Demo Data Management (Reset Data)
            Text('Demo Controls', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            _buildGroupedCard([
              _buildSettingsTile(
                icon: Icons.restart_alt_rounded,
                iconColor: AppColors.warning,
                title: 'Reset Demo Data',
                subtitle: 'Restore 22 default properties, chats, and ads',
                onTap: () => _confirmResetDemoData(context, ref),
              ),
              _buildSettingsTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                title: 'Log Out',
                subtitle: 'End current demo session',
                onTap: () {
                  _showToast(context, 'Demo session active (Offline Demo Mode)');
                },
                isLast: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    String? badge,
    String? trailingText,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
          ),
          title: Text(title, style: AppTextStyles.labelLarge),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (trailingText != null)
                Text(
                  trailingText,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.borderLight),
      ],
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & FAQs'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Q: How does offline mode work?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('A: All properties, chats, bookmarks, and new postings are saved directly into your device local storage. You do not need internet to search, filter, or post listings!'),
              SizedBox(height: 12),
              Text('Q: How do I post a property?', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('A: Tap "+ Post Property" on the My Ads tab and complete the 8-step wizard form.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tenkasi Dreams Land',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'தென்காசி கனவுகள்',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'LAND PROMOTERS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'A modern real estate marketplace application dedicated to lands, plots, villas, and properties in Tenkasi and Tamil Nadu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _confirmResetDemoData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will reset all listings, chats, and favorites back to the pristine 22 seed properties in Tamil Nadu.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(propertiesProvider.notifier).resetAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo data restored to initial seed state!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController(text: ApiConfig.instance.serverUrl);
    bool isOnline = ApiConfig.instance.isOnlineMode;
    String? pingMessage = ApiConfig.instance.lastPingStatus;
    bool isTesting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Server Configuration'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tenkasi Dreams Land is architected to work 100% offline or immediately connect to your production REST backend.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Live REST Server Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    isOnline ? 'Active: Syncing with server' : 'Offline: Local database storage',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isOnline,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    setDialogState(() => isOnline = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Server API URL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'http://127.0.0.1:8000/api',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                // Ping status card
                if (pingMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      pingMessage!,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() {
                            isTesting = true;
                            pingMessage = 'Testing server connection...';
                          });
                          await ApiConfig.instance.setServerUrl(urlController.text.trim());
                          await ApiConfig.instance.testConnection();
                          setDialogState(() {
                            isTesting = false;
                            pingMessage = ApiConfig.instance.lastPingStatus;
                          });
                        },
                  icon: isTesting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_ping_rounded, size: 16),
                  label: const Text('Test Connection (Ping)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiConfig.instance.setServerUrl(urlController.text.trim());
                await ApiConfig.instance.setOnlineMode(isOnline);
                if (isOnline) {
                  await ref.read(propertiesProvider.notifier).syncWithServer();
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isOnline
                            ? 'Live Server Mode Enabled: ${urlController.text.trim()}'
                            : 'Offline Cache Mode Enabled',
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
