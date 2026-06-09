import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _leaderboard = [];
  Map<String, dynamic>? _myLeague;
  bool _isLoading = true;
  int _totalParticipants = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getLeaderboard(),
        ApiService.getMyLeague(),
      ]);
      if (!mounted) return;
      setState(() {
        _leaderboard = results[0] as List<LeaderboardEntry>;
        _myLeague = results[1] as Map<String, dynamic>;
        _totalParticipants = _leaderboard.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final balance = user?.bonusBalance.toInt() ?? 0;
    final myRank = _myLeague?['rank'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ШАПКА
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
                        child: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 22),
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
                          _fmt(balance),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. КАРТОЧКА МЕСТА ПОЛЬЗОВАТЕЛЯ
              Center(
                child: Container(
                  width: 228,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ваше место',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF2F2F2)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#$myRank',
                        style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Из ${_fmt(_totalParticipants)} участников',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF2F2F2)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. ПЬЕДЕСТАЛ ПОЧЕТА (Топ-3)
              if (_leaderboard.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2-е место
                    if (_leaderboard.length > 1)
                      _buildPodiumColumn(
                        place: '2',
                        name: _leaderboard[1].pseudonym,
                        avatarColor: const Color(0xFF6C707D),
                        podiumColor: const Color(0xFFF2F2F2),
                        podiumHeight: 60,
                        emoji: _getEmoji(_leaderboard[1].pseudonym),
                      ),
                    if (_leaderboard.length > 1) const SizedBox(width: 12),
                    // 1-е место
                    if (_leaderboard.isNotEmpty)
                      _buildPodiumColumn(
                        place: '🏆',
                        name: _leaderboard[0].pseudonym,
                        avatarColor: const Color(0xFF3B5998),
                        podiumColor: const Color(0x35FFC800),
                        podiumHeight: 90,
                        emoji: _getEmoji(_leaderboard[0].pseudonym),
                      ),
                    if (_leaderboard.isNotEmpty) const SizedBox(width: 12),
                    // 3-е место
                    if (_leaderboard.length > 2)
                      _buildPodiumColumn(
                        place: '3',
                        name: _leaderboard[2].pseudonym,
                        avatarColor: const Color(0xFF8B6530),
                        podiumColor: const Color(0xFFF2F2F2),
                        podiumHeight: 45,
                        emoji: _getEmoji(_leaderboard[2].pseudonym),
                      ),
                  ],
                ),
              const SizedBox(height: 30),

              // 4. ТАБЛИЦА ЛИДЕРОВ
              const Text(
                'Топ участников',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),

              ..._leaderboard.map((entry) => _buildLeaderRow(entry, _myLeague?['pseudonym'])),

              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Рейтинг обновляется ежемесячно. Топ-3 получают призы автоматически.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumColumn({
    required String place,
    required String name,
    required Color avatarColor,
    required Color podiumColor,
    required double podiumHeight,
    required String emoji,
  }) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: podiumColor,
            border: Border.all(color: const Color(0xFFB3B3B3)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: place == '🏆'
                ? const Icon(Icons.emoji_events, color: Colors.amber, size: 24)
                : Text(
                    place,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderRow(LeaderboardEntry entry, String? currentUser) {
    final isCurrentUser = entry.pseudonym == currentUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        border: Border.all(
          color: isCurrentUser ? Colors.black : const Color(0xFFB3B3B3),
          width: isCurrentUser ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.pseudonym,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String name) {
    final hash = name.hashCode.abs();
    final emojis = ['🐱', '🐶', '🦊', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸'];
    return emojis[hash % emojis.length];
  }
}
