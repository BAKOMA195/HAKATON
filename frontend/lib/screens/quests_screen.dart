import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  List<Quest> _dailyQuests = [];
  List<Quest> _weeklyQuests = [];
  List<Quest> _seasonalQuests = [];
  Map<int, bool> _completedQuestIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final daily = await ApiService.getDailyQuests();
      
      // Weekly and seasonal quests - using same API for now since backend only has daily endpoint
      // In production, these would come from separate endpoints
      final weekly = <Quest>[
        Quest(
          id: 100,
          title: 'Оформить 2 займа',
          description: 'Выполните 2 займа за неделю',
          bonusReward: 400,
          questType: 'weekly',
          actionType: 'weekly_loans',
          isActive: true,
        ),
        Quest(
          id: 101,
          title: 'Погасить долг вовремя',
          description: 'Погасите задолженность без просрочек',
          bonusReward: 300,
          questType: 'weekly',
          actionType: 'weekly_repay',
          isActive: true,
        ),
      ];
      
      final seasonal = <Quest>[
        Quest(
          id: 200,
          title: 'Золотой сезон: 5 000 XP',
          description: 'Наберите 5000 XP за сезон',
          bonusReward: 2000,
          questType: 'seasonal',
          actionType: 'seasonal_gold',
          isActive: true,
        ),
      ];

      if (mounted) {
        setState(() {
          _dailyQuests = daily;
          _weeklyQuests = weekly;
          _seasonalQuests = seasonal;
          _completedQuestIds = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeQuest(Quest quest) async {
    if (_completedQuestIds[quest.id] == true) return;
    
    try {
      final result = await ApiService.completeQuest(quest.id);
      if (mounted) {
        setState(() {
          _completedQuestIds[quest.id] = true;
        });
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '✅ Квест выполнен!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${result['bonus_earned']} бонусов!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Баланс: ${result['new_balance']} бонусов',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<UserProvider>().refreshUser();
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFFE31E24), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  IconData _getQuestIcon(String actionType) {
    switch (actionType) {
      case 'check_deposit':
      case 'weekly_loans':
        return Icons.account_balance;
      case 'read_article':
        return Icons.article;
      case 'use_calculator':
        return Icons.calculate;
      case 'update_profile':
        return Icons.person;
      case 'rate_app':
        return Icons.star;
      case 'share':
        return Icons.share;
      case 'browse_marketplace':
        return Icons.storefront;
      case 'check_leaderboard':
        return Icons.emoji_events;
      case 'check_achievements':
        return Icons.emoji_events;
      case 'refer_friend':
        return Icons.person_add;
      case 'weekly_repay':
        return Icons.payment;
      case 'seasonal_gold':
        return Icons.workspace_premium;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final balance = user?.bonusBalance.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.black)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadQuests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ШАПКА
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
                                  child: const Icon(Icons.push_pin_outlined, color: Colors.white, size: 22),
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
                                    balance.toString().replaceAllMapped(
                                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                          (Match m) => '${m[1]} ',
                                        ),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ЕЖЕДНЕВНЫЕ
                        const Text(
                          'ЕЖЕДНЕВНЫЕ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._dailyQuests.map((q) => _buildQuestCard(q, balance)),

                        const SizedBox(height: 24),

                        // НЕДЕЛЬНЫЕ
                        const Text(
                          'НЕДЕЛЬНЫЕ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._weeklyQuests.map((q) => _buildQuestCard(q, balance)),

                        const SizedBox(height: 24),

                        // СЕЗОННЫЕ
                        const Text(
                          'СЕЗОННЫЕ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._seasonalQuests.map((q) => _buildQuestCard(q, balance)),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildQuestCard(Quest quest, int balance) {
    final isCompleted = _completedQuestIds[quest.id] == true;
    final icon = _getQuestIcon(quest.actionType);

    return GestureDetector(
      onTap: () => _completeQuest(quest),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          border: Border.all(
            color: const Color(0xFFB3B3B3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x26ED1B24),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: const Color(0xFFE31E24), size: 20),
            ),
            const SizedBox(width: 12),
            // Название и прогресс
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFE31E24) : const Color(0xFFF2D2D3),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Награда или статус
            isCompleted
                ? Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2D2D3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Color(0xFFE31E24), size: 16),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x26ED1B24),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '+${quest.bonusReward}',
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
