import 'package:flutter/material.dart';
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
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'Все', 'icon': Icons.apps},
    {'id': 'financial', 'label': 'Финансы', 'icon': Icons.account_balance},
    {'id': 'partner', 'label': 'Партнёры', 'icon': Icons.store},
    {'id': 'merch', 'label': 'Мерч', 'icon': Icons.shopping_bag},
    {'id': 'charity', 'label': 'Благотвор.', 'icon': Icons.favorite},
    {'id': 'exclusive', 'label': 'Эксклюзив', 'icon': Icons.diamond},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrizes();
  }

  Future<void> _loadPrizes() async {
    setState(() => _isLoading = true);
    try {
      final prizes = await ApiService.getPrizes(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      setState(() {
        _prizes = prizes;
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

  Future<void> _redeemPrize(Prize prize) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Выкупить "${prize.name}"?', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Стоимость: ${prize.bonusCost} бонусов',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560)),
            child: const Text('Выкупить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await ApiService.redeemPrize(prize.id);
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('🎉 Приз выкуплен!', style: TextStyle(color: Colors.white)),
              content: Text(result['message'], style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadPrizes();
                  },
                  child: const Text('OK', style: TextStyle(color: Color(0xFFE94560))),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог призов'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Column(
          children: [
            // Категории
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'], size: 16, color: isSelected ? Colors.white : Colors.white70),
                          const SizedBox(width: 4),
                          Text(cat['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat['id']);
                        _loadPrizes();
                      },
                      backgroundColor: Colors.white.withOpacity(0.05),
                      selectedColor: const Color(0xFFE94560),
                      checkmarkColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Список призов
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE94560)))
                  : _prizes.isEmpty
                      ? const Center(
                          child: Text('Нет призов в этой категории', style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _prizes.length,
                          itemBuilder: (context, index) {
                            final prize = _prizes[index];
                            return _buildPrizeCard(prize);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeCard(Prize prize) {
    final categoryColors = {
      'financial': const Color(0xFF4CAF50),
      'partner': const Color(0xFF2196F3),
      'merch': const Color(0xFFFF9800),
      'charity': const Color(0xFFE91E63),
      'exclusive': const Color(0xFF9C27B0),
    };
    final color = categoryColors[prize.category] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(prize.category),
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prize.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (prize.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    prize.description!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94560),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${prize.bonusCost} бонусов',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (prize.stockQuantity != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Осталось: ${prize.stockQuantity}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _redeemPrize(prize),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Выкупить'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'financial': return Icons.account_balance;
      case 'partner': return Icons.store;
      case 'merch': return Icons.shopping_bag;
      case 'charity': return Icons.favorite;
      case 'exclusive': return Icons.diamond;
      default: return Icons.card_giftcard;
    }
  }
}
