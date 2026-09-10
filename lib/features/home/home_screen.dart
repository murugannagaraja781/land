import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/common/app_bar_widget.dart';
import '../../components/common/empty_state_widget.dart';
import '../../components/home/category_chip.dart';
import '../../components/home/featured_property_card.dart';
import '../../components/home/olx_grid_card.dart';
import '../../components/home/search_bar.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/property.dart';
import '../../state/app_state_providers.dart';
import '../property_detail/property_detail_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToSearch;

  const HomeScreen({super.key, this.onNavigateToSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(selectedCategoryProvider);
    final featured = ref.watch(featuredPropertiesProvider);
    final latest = ref.watch(latestPropertiesProvider);
    final nearby = ref.watch(nearbyPropertiesProvider);

    // Filter properties if category selected
    final List<Property> displayedList;
    if (activeCategory == 'all') {
      displayedList = latest;
    } else {
      final repo = ref.watch(propertyRepositoryProvider);
      ref.watch(propertiesProvider); // reactivity
      displayedList = repo.getPropertiesByCategory(activeCategory);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.read(propertiesProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // 1. OLX Top App Bar (Location, Language Switcher, Notifications & 2px bordered Search Bar)
              SliverToBoxAdapter(
                child: AppBarWidget(onNavigateToSearch: onNavigateToSearch),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 6),
              ),

              // 2. Browse Categories (OLX Circular Category Avatars with labels)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ref.tr('sec_categories'),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.olxNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 88,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: AppConstants.categories.length,
                          itemBuilder: (context, index) {
                            final cat = AppConstants.categories[index];
                            final isSelected = cat.id == activeCategory;
                            return PropertyCategoryChip(
                              category: cat,
                              isSelected: isSelected,
                              onTap: () {
                                ref.read(selectedCategoryProvider.notifier).setCategory(cat.id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),

              // 5. Category-filtered view (in 2-Column OLX Grid) or Full Feed
              if (activeCategory != 'all') ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${displayedList.length} ${ref.tr('sec_available')}',
                          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(selectedCategoryProvider.notifier).setCategory('all');
                          },
                          child: Text(ref.tr('sec_show_all')),
                        ),
                      ],
                    ),
                  ),
                ),
                if (displayedList.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyStateWidget(
                      onAction: () {
                        ref.read(selectedCategoryProvider.notifier).setCategory('all');
                      },
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.67,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final prop = displayedList[index];
                          return OlxGridCard(
                            property: prop,
                            onTap: () => _openDetail(context, prop),
                          );
                        },
                        childCount: displayedList.length,
                      ),
                    ),
                  ),
              ] else ...[
                // Featured Properties Carousel (OLX Promoted / Top Ads)
                if (featured.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                ref.tr('sec_featured'),
                                style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFC9A227).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  ref.tr('sec_hot'),
                                  style: const TextStyle(
                                    color: Color(0xFFC9A227),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              ref.read(searchFilterProvider.notifier).updateQuery('');
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              );
                            },
                            child: Text(
                              ref.tr('sec_view_all'),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 290,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: featured.length,
                        itemBuilder: (context, index) {
                          final prop = featured[index];
                          return FeaturedPropertyCard(
                            property: prop,
                            onTap: () => _openDetail(context, prop),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Nearby Properties Section
                if (nearby.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ref.tr('sec_nearby'),
                            style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            ref.tr('sec_recommended_sub'),
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 290,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: nearby.length,
                        itemBuilder: (context, index) {
                          final prop = nearby[index];
                          return FeaturedPropertyCard(
                            property: prop,
                            width: 260,
                            onTap: () => _openDetail(context, prop),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Fresh Recommendations / Latest Listings Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ref.tr('sec_latest'),
                          style: AppTextStyles.h3.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${latest.length} ${ref.tr('sec_available')}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),

                // Authentic 2-Column OLX Grid Feed!
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.67,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prop = latest[index];
                        return OlxGridCard(
                          property: prop,
                          onTap: () => _openDetail(context, prop),
                        );
                      },
                      childCount: latest.length,
                    ),
                  ),
                ),
              ],

              // Bottom padding for comfortable scrolling above navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(propertyId: property.id),
      ),
    );
  }
}
