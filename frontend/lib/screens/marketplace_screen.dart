import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Prize> _prizes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrizes();
  }

  Future<void> _loadPrizes() async {
    setState(() => _isLoading = true);
    try {
      final prizes = await ApiService.getPrizes();
      setState(() {
        _prizes = prizes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _redeemPrize(Prize prize) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Забрать "${prize.name}"?',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Стоимость: ${prize.bonusCost} бонусов',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF808080))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31E24)),
            child: const Text('Забрать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await ApiService.redeemPrize(prize.id);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '🎉 Приз получен!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            content: Text(
              result['message'],
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadPrizes();
                  context.read<UserProvider>().refreshUser();
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFFE31E24), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ШАПКА
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
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
                          _fmt(balance),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. ЗАГОЛОВОК
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'ПРИЗЫ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. СПИСОК ПРИЗОВ
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31E24)))
                  : _prizes.isEmpty
                      ? const Center(
                          child: Text('Нет доступных призов', style: TextStyle(color: Color(0xFF808080))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _prizes.length,
                          itemBuilder: (context, index) {
                            final prize = _prizes[index];
                            final canAfford = balance >= prize.bonusCost;
                            return _buildPrizeCard(prize, canAfford);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeCard(Prize prize, bool canAfford) {
    return GestureDetector(
      onTap: canAfford ? () => _redeemPrize(prize) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Иконка в розовой коробочке
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF2D2D3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getCategoryIcon(prize.category), color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),

            // Текстовая информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prize.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  if (prize.description != null)
                    Text(
                      prize.description!,
                      style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${prize.bonusCost} монет',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFC800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Кнопка
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: canAfford ? const Color(0xFFF2D2D3) : const Color(0xFFF6F6F6),
                border: canAfford ? null : Border.all(color: const Color(0xFFB3B3B3)),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                canAfford ? 'Забрать' : 'Мало монет',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: canAfford ? const Color(0xFFE31E24) : const Color(0xFF808080),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'financial': return Icons.percent;
      case 'partner': return Icons.card_giftcard;
      case 'merch': return Icons.backpack_outlined;
      case 'charity': return Icons.favorite;
      case 'exclusive': return Icons.diamond;
      default: return Icons.store;
    }
  }
}
