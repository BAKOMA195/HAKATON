import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'wheel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  int _achievementsCount = 0;
  int _redeemedCount = 0;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final achievements = await ApiService.getAchievements();
      final redemptions = await ApiService.getMyRedemptions();
      setState(() {
        _achievementsCount = achievements.length;
        _redeemedCount = redemptions.length;
        _dataLoaded = true;
      });
    } catch (_) {
      setState(() => _dataLoaded = true);
    }
  }

  Future<void> _doCheckin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.dailyCheckin();
      setState(() => _isLoading = false);
      await context.read<UserProvider>().refreshUser();
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🎉 Ежедневный вход!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${result.bonusEarned} бонусов!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
              const SizedBox(height: 8),
              Text(result.message),
              const SizedBox(height: 8),
              Text(
                'Серия: ${result.currentStreak} дней 🔥',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (result.currentStreak >= 7) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WheelScreen()),
                  );
                }
              },
              child: Text(
                result.currentStreak >= 7 ? 'Открыть сундуки!' : 'Отлично!',
                style: const TextStyle(color: Color(0xFFE31E24)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  int _calculateLevel(double balance) {
    if (balance >= 10000) return 10;
    if (balance >= 7500) return 9;
    if (balance >= 5000) return 8;
    if (balance >= 3500) return 7;
    if (balance >= 2500) return 6;
    if (balance >= 1500) return 5;
    if (balance >= 1000) return 4;
    if (balance >= 500) return 3;
    if (balance >= 200) return 2;
    return 1;
  }

  String _getLevelName(double balance) {
    if (balance >= 10000) return 'Бриллиантовый клиент';
    if (balance >= 7500) return 'Платиновый клиент';
    if (balance >= 5000) return 'Золотой клиент';
    if (balance >= 3500) return 'Серебряный клиент';
    if (balance >= 2500) return 'Бронзовый клиент';
    if (balance >= 1500) return 'Активный клиент';
    if (balance >= 1000) return 'Новичок+';
    if (balance >= 500) return 'Начинающий';
    if (balance >= 200) return 'Гость';
    return 'Новичок';
  }

  (int currentXP, int nextLevelXP) _calculateXP(double balance) {
    final level = _calculateLevel(balance);
    final thresholds = [0, 200, 500, 1000, 1500, 2500, 3500, 5000, 7500, 10000, 999999];
    final currentXP = balance.toInt() - thresholds[level - 1];
    final nextLevelXP = thresholds[level] - thresholds[level - 1];
    return (currentXP, nextLevelXP);
  }

  String _getNextLevelName(double balance) {
    if (balance >= 10000) return 'Максимум';
    if (balance >= 7500) return 'Бриллиантового';
    if (balance >= 5000) return 'Платинового';
    if (balance >= 3500) return 'Золотого';
    if (balance >= 2500) return 'Серебряного';
    if (balance >= 1500) return 'Бронзового';
    if (balance >= 1000) return 'Активного';
    if (balance >= 500) return 'Новичок+';
    if (balance >= 200) return 'Начинающего';
    return 'Гостя';
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F6F6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE31E24))),
      );
    }

    final balance = user.bonusBalance;
    final streak = user.dailyStreak;
    final level = _calculateLevel(balance);
    final levelName = _getLevelName(balance);
    final (currentXP, nextLevelXP) = _calculateXP(balance);
    final progress = nextLevelXP > 0 ? currentXP / nextLevelXP : 1.0;
    final nextLevelName = _getNextLevelName(balance);
    final xpNeeded = nextLevelXP - currentXP;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE31E24),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SKS QUEST',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFB3B3B3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_outlined, size: 16, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          _fmt(balance.toInt()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE31E24),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$level Уровень',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      levelName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'до $nextLevelName: $xpNeeded XP',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currentXP XP',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '$nextLevelXP XP',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('$streak', 'дней подряд'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      _dataLoaded ? '$_achievementsCount' : '...',
                      'достижений',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      _dataLoaded ? '$_redeemedCount' : '...',
                      'приза получено',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ЗАБРАТЬ ЕЖЕДНЕВНУЮ\nНАГРАДУ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Заходите каждый день, чтобы собрать\nкак можно больше призов за неделю',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF808080),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDayCard(day: 1, label: 'день', isActive: streak >= 1, hasBonus: true, bonusIcon: Icons.star, bonusColor: Colors.amber),
                        const SizedBox(width: 12),
                        _buildDayCard(day: 2, label: 'день', isActive: streak >= 2),
                        const SizedBox(width: 12),
                        _buildDayCard(day: 3, label: 'день', isActive: streak >= 3, hasBonus: true, bonusIcon: Icons.circle, bonusColor: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDayCard(day: 4, label: 'день', isActive: streak >= 4),
                        const SizedBox(width: 12),
                        _buildDayCard(day: 5, label: 'день', isActive: streak >= 5, hasBonus: true, bonusIcon: Icons.circle, bonusColor: Colors.amber),
                        const SizedBox(width: 12),
                        _buildDayCard(day: 6, label: 'день', isActive: streak >= 6),
                        const SizedBox(width: 12),
                        _buildDayCard(day: 7, label: 'день', isActive: streak >= 7, hasBonus: true, bonusIcon: Icons.inventory_2, bonusColor: const Color(0xFFFFC800)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isLoading ? null : _doCheckin,
                      child: Container(
                        width: 165,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.grey : const Color(0xFFE31E24),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Забрать',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required String label,
    bool isActive = false,
    bool hasBonus = false,
    IconData? bonusIcon,
    Color? bonusColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE31E24) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : const Color(0xFFB3B3B3),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : const Color(0xFFB3B3B3),
                ),
              ),
            ],
          ),
        ),
        if (hasBonus && bonusIcon != null)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 2),
                ],
              ),
              child: Icon(
                bonusIcon,
                size: 14,
                color: bonusColor ?? Colors.amber,
              ),
            ),
          ),
      ],
    );
  }
}
