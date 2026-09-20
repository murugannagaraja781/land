import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/account/favorites_screen.dart';
import '../../features/account/notifications_screen.dart';
import '../../features/home/location_dialog.dart';
import '../../features/search/search_screen.dart';
import '../../state/app_state_providers.dart';

class AppBarWidget extends ConsumerWidget {
  const AppBarWidget({super.key, this.onNavigateToSearch});

  final VoidCallback? onNavigateToSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Row 1: Logo + Location Selector
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  // Official Logo Image from screenshot
                  Image.asset(
                    'assets/images/app_logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.terrain_rounded, color: AppColors.primary, size: 28),
                          const SizedBox(width: 6),
                          Text(
                            ref.tr('app_title_ta'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // Vertical thin divider
                  Container(
                    height: 24,
                    width: 1.2,
                    color: const Color(0xFFCBD5E1),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),

                  // Location Pin & Dropdown
                  InkWell(
                    onTap: () => LocationDialog.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location.isNotEmpty
                                ? location.split(',').first
                                : ref.tr('location_default'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Row 2: Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
            child: GestureDetector(
              onTap: () {
                if (onNavigateToSearch != null) {
                  onNavigateToSearch!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                }
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ref.tr('search_placeholder'),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Divider before action icons
                    Container(
                      width: 1,
                      height: 22,
                      color: const Color(0xFFE2E8F0),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                    ),

                    // Voice Search
                    GestureDetector(
                      onTap: () {
                        if (onNavigateToSearch != null) {
                          onNavigateToSearch!();
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: Color(0xFF1565C0),
                          size: 22,
                        ),
                      ),
                    ),

                    // Favorites
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          color: Color(0xFF1E293B),
                          size: 22,
                        ),
                      ),
                    ),

                    // Notifications with red dot badge
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF1E293B),
                              size: 22,
                            ),
                          ),
                          if (unreadNotifs > 0)
                            Positioned(
                              top: 1,
                              right: 5,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
