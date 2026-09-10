import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/account/notifications_screen.dart';
import '../../features/home/location_dialog.dart';
import '../../features/search/filter_bottom_sheet.dart';
import '../../features/search/search_screen.dart';
import '../../state/app_state_providers.dart';
import 'language_switcher.dart';

class AppBarWidget extends ConsumerWidget {
  const AppBarWidget({super.key, this.onNavigateToSearch});

  final VoidCallback? onNavigateToSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(selectedLocationProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          // Row 1: Location on Left, Language Switcher & Notifications on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // OLX Location Selector
              InkWell(
                onTap: () => LocationDialog.show(context),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.olxNavy,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: Text(
                          location.isNotEmpty ? location : 'Tenkasi, Tamil Nadu',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.olxNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.olxNavy,
                      ),
                    ],
                  ),
                ),
              ),

              // Right Actions: Language Switcher & Bell
              Row(
                children: [
                  const LanguageSwitcher(),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 24,
                            color: AppColors.olxNavy,
                          ),
                        ),
                      ),
                      if (unreadNotifs > 0)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Iconic OLX Large Search Bar with 2px border
          GestureDetector(
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.olxNavy,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.olxNavy,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ref.tr('search_placeholder'),
                      style: const TextStyle(
                        color: Color(0xFF7F9799),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => FilterBottomSheet.show(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.olxNavy,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
