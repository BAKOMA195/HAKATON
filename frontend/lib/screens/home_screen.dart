import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import 'guess_price_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  double _bonusBalance = 1500;
  int _dailyStreak = 5;
  String _username = 'bakoma';

  Future<void> _doCheckin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.dailyCheckin();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _bonusBalance += result.bonusEarned;
          _dailyStreak = result.currentStreak;
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('🎉 Ежедневный вход!', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${result.bonusEarned} бонусов!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE94560),
                  ),
                ),
                const SizedBox(height: 8),
                Text(result.message, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  'Серия: ${result.currentStreak} дней 🔥',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отлично!', style: TextStyle(color: Color(0xFFE94560))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка с балансом
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Привет, $_username!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Статус: ${_getLeagueName(_bonusBalance)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE94560), Color(0xFFC23152)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${_bonusBalance.toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Серия ежедневных входов
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Ежедневный вход',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (_dailyStreak % 30) / 30,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_dailyStreak / 30 дней',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            _getNextMilestone(_dailyStreak),
                            style: const TextStyle(color: Color(0xFFE94560), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _doCheckin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE94560),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Забрать бонусы!',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: -0.2),
                const SizedBox(height: 20),

                // Быстрые действия
                const Text(
                  'Игровые механики',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildActionCard(
                      icon: Icons.flag,
                      title: 'Квесты',
                      subtitle: 'Выполняй задания',
                      color: const Color(0xFF4CAF50),
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.casino,
                      title: 'Колесо',
                      subtitle: 'Крути и выигрывай',
                      color: const Color(0xFF9C27B0),
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.store,
                      title: 'Призы',
                      subtitle: 'Трать бонусы',
                      color: const Color(0xFFFF9800),
                      onTap: () {},
                    ),
                    _buildActionCard(
                      icon: Icons.search,
                      title: 'Оценщик',
                      subtitle: 'Угадай цену',
                      color: const Color(0xFF1D3557),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GuessPriceScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.emoji_events,
                      title: 'Лидерборд',
                      subtitle: 'Топ игроков',
                      color: const Color(0xFF2196F3),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getLeagueName(double balance) {
    if (balance >= 5000) return '💎 Бриллиант';
    if (balance >= 3000) return '🥇 Золото';
    if (balance >= 1500) return '🥈 Серебро';
    if (balance >= 500) return '🥉 Бронза';
    return '🌟 Новичок';
  }

  String _getNextMilestone(int streak) {
    if (streak < 7) return 'До 50 бонусов: ${7 - streak} дн.';
    if (streak < 14) return 'До 150 бонусов: ${14 - streak} дн.';
    if (streak < 30) return 'До 500 бонусов: ${30 - streak} дн.';
    return 'Максимум! 🔥';
  }
}
