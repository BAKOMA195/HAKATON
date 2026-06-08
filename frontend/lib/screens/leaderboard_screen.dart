import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _leaderboard = [];
  List<Achievement> _achievements = [];
  Map<String, dynamic>? _myLeague;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getLeaderboard(),
        ApiService.getAchievements(),
        ApiService.getMyLeague(),
      ]);
      setState(() {
        _leaderboard = results[0] as List<LeaderboardEntry>;
        _achievements = results[1] as List<Achievement>;
        _myLeague = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рейтинг и достижения'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE94560),
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFE94560),
          tabs: const [
            Tab(text: '🏆 Лидерборд'),
            Tab(text: '🎖 Достижения'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboard(),
                  _buildAchievements(),
                ],
              ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Column(
      children: [
        // Моя лига
        if (_myLeague != null)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE94560), Color(0xFFC23152)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Моя лига', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      _myLeague!['league'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Позиция', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(
                      '#${_myLeague!['rank']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Таблица лидеров
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _leaderboard.length,
            itemBuilder: (context, index) {
              final entry = _leaderboard[index];
              return _buildLeaderboardItem(entry, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int index) {
    final medals = ['🥇', '🥈', '🥉'];
    final isTop3 = index < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop3
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3 ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Ранг
          SizedBox(
            width: 40,
            child: Text(
              isTop3 ? medals[index] : '#${entry.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Аватар
          CircleAvatar(
            radius: 20,
            backgroundColor: _getLeagueColor(entry.league).withOpacity(0.2),
            child: Text(
              entry.pseudonym.substring(0, 1),
              style: TextStyle(
                color: _getLeagueColor(entry.league),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.pseudonym,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${entry.bonusEarnedMonth.toInt()} бонусов за месяц',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Лига
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getLeagueColor(entry.league).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getLeagueColor(entry.league)),
            ),
            child: Text(
              entry.league,
              style: TextStyle(
                color: _getLeagueColor(entry.league),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 40,
                color: achievement.bonusReward >= 500
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFE94560),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '+${achievement.bonusReward} бонусов',
                style: const TextStyle(color: Color(0xFFE94560), fontSize: 12),
              ),
              if (achievement.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  achievement.description!,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getLeagueColor(String league) {
    switch (league) {
      case 'Бриллиант': return const Color(0xFF00BCD4);
      case 'Платина': return const Color(0xFF9C27B0);
      case 'Золото': return const Color(0xFFFFD700);
      case 'Серебро': return const Color(0xFFB0BEC5);
      case 'Бронза': return const Color(0xFFCD7F32);
      default: return Colors.grey;
    }
  }
}
