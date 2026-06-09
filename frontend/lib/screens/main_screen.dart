import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'guess_price_screen.dart';
import 'marketplace_screen.dart';
import 'quests_screen.dart';
import 'leaderboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GuessPriceScreen(),
    const MarketplaceScreen(),
    const QuestsScreen(),
    const LeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 'Главная', 0),
            _buildNavItem(Icons.sports_esports_outlined, 'Игра', 1),
            _buildNavItem(Icons.card_giftcard, 'Призы', 2),
            _buildNavItem(Icons.push_pin_outlined, 'Задания', 3),
            _buildNavItem(Icons.emoji_events_outlined, 'Рейтинг', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.black : const Color(0xFFB3B3B3),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : const Color(0xFFB3B3B3),
            ),
          ),
        ],
      ),
    );
  }
}
