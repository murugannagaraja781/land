import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/common/bottom_nav_bar.dart';
import '../../screens/post_ad/post_ad_wizard.dart';
import '../../state/app_state_providers.dart';
import '../account/account_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';
import '../my_ads/my_ads_screen.dart';
import '../search/search_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _openPostAdWizard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PostAdWizard(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unread messages count for chat badge
    final conversations = ref.watch(conversationsProvider);
    final totalUnreadChats = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    final screens = [
      HomeScreen(
        onNavigateToSearch: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
        },
      ),
      const ChatListScreen(),
      const MyAdsScreen(),
      AccountScreen(onNavigateToMyAds: () => _onTabTapped(2)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onPostAdTap: _openPostAdWizard,
        unreadChatsCount: totalUnreadChats,
      ),
    );
  }
}
