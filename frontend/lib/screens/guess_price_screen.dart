import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class GuessPriceScreen extends StatefulWidget {
  const GuessPriceScreen({super.key});

  @override
  State<GuessPriceScreen> createState() => _GuessPriceScreenState();
}

class _GuessPriceScreenState extends State<GuessPriceScreen> {
  static const int totalRounds = 5;

  int _currentRound = 0;
  double _currentValue = 35000;
  double _minValue = 10000;
  double _maxValue = 60000;
  bool _isLoading = false;
  bool _showResult = false;
  int _earned = 0;
  int _hits = 0;
  GuessPriceSession? _session;
  List<GuessPriceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    setState(() {
      _isLoading = true;
      _currentRound = 0;
      _earned = 0;
      _hits = 0;
      _showResult = false;
    });

    try {
      _session = await ApiService.startGuessPrice();
      _items = await ApiService.getGuessPriceItems(_session!.sessionId);

      if (_items.isEmpty) {
        _items = _getDefaultItems();
      }

      _items.shuffle();
      if (_items.length > totalRounds) {
        _items = _items.sublist(0, totalRounds);
      }

      _minValue = _items[0].minPrice.toDouble();
      _maxValue = _items[0].maxPrice.toDouble();
      _currentValue = ((_minValue + _maxValue) / 2);

      setState(() => _isLoading = false);
    } catch (e) {
      _items = _getDefaultItems();
      _items.shuffle();
      if (_items.length > totalRounds) {
        _items = _items.sublist(0, totalRounds);
      }
      _minValue = _items[0].minPrice.toDouble();
      _maxValue = _items[0].maxPrice.toDouble();
      _currentValue = ((_minValue + _maxValue) / 2);
      setState(() => _isLoading = false);
    }
  }

  List<GuessPriceItem> _getDefaultItems() {
    return [
      GuessPriceItem(id: 1, emoji: '⌚', name: 'Мужские часы Casio', description: 'Кварцевый механизм, нержавеющая сталь, 2019 г.', minPrice: 2000, maxPrice: 18000, realPrice: 7500),
      GuessPriceItem(id: 2, emoji: '💍', name: 'Золотое кольцо 585', description: 'Проба 585, вес 3.8 г, без вставок', minPrice: 5000, maxPrice: 40000, realPrice: 19000),
      GuessPriceItem(id: 3, emoji: '📱', name: 'Смартфон Samsung S22', description: '128 ГБ, состояние хорошее, без коробки', minPrice: 8000, maxPrice: 45000, realPrice: 22000),
      GuessPriceItem(id: 4, emoji: '💻', name: 'Ноутбук Lenovo IdeaPad', description: 'Core i5, 8 ГБ ОЗУ, 2021 г., царапины', minPrice: 10000, maxPrice: 60000, realPrice: 28000),
      GuessPriceItem(id: 5, emoji: '📷', name: 'Фотоаппарат Canon EOS', description: 'Зеркальный, 24 Мп, объектив 18-55', minPrice: 12000, maxPrice: 70000, realPrice: 35000),
    ];
  }

  Future<void> _confirmGuess() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final item = _items[_currentRound];
    final guess = _currentValue.toInt();
    final diff = (guess - item.realPrice).abs();
    final accuracyPercent = (diff / item.realPrice * 100).round();

    int coinsEarned;
    String tier;
    String message;

    if (accuracyPercent <= 5) {
      coinsEarned = 200;
      tier = 'exact';
      message = 'Точное попадание!';
    } else if (accuracyPercent <= 15) {
      coinsEarned = 100;
      tier = 'close';
      message = 'Близко!';
    } else if (accuracyPercent <= 30) {
      coinsEarned = 30;
      tier = 'miss';
      message = 'Мимо...';
    } else {
      coinsEarned = 0;
      tier = 'far';
      message = 'Далеко от цены';
    }

    if (coinsEarned >= 100) _hits++;
    _earned += coinsEarned;

    try {
      await ApiService.submitGuessPrice(
        sessionId: _session?.sessionId ?? 0,
        itemId: item.id,
        guess: guess,
      );
    } catch (_) {}

    setState(() {
      _isLoading = false;
      _showResult = true;
    });
  }

  void _nextRound() {
    if (_currentRound + 1 >= totalRounds) {
      _finishGame();
    } else {
      setState(() {
        _currentRound++;
        _showResult = false;
        final item = _items[_currentRound];
        _minValue = item.minPrice.toDouble();
        _maxValue = item.maxPrice.toDouble();
        _currentValue = ((_minValue + _maxValue) / 2);
      });
    }
  }

  Future<void> _finishGame() async {
    try {
      await ApiService.finishGuessPrice(_session?.sessionId ?? 0);
    } catch (_) {}

    await context.read<UserProvider>().refreshUser();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FinalDialog(
        earned: _earned,
        hits: _hits,
        totalRounds: totalRounds,
        onPlayAgain: () {
          Navigator.pop(context);
          _startGame();
        },
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final balance = user?.bonusBalance.toInt() ?? 0;

    if (_isLoading && _items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, size: 60, color: Color(0xFFE31E24)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFFE31E24)),
              const SizedBox(height: 16),
              const Text('Загрузка...', style: TextStyle(color: Color(0xFF808080))),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: const Center(child: Text('Нет данных для игры')),
      );
    }

    final item = _items[_currentRound];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        child: const Icon(Icons.videogame_asset_outlined, color: Colors.white, size: 22),
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
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(totalRounds, (index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: index < _currentRound || (_showResult && index == _currentRound)
                              ? const Color(0xFFE31E24)
                              : const Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  Text(
                    'Раунд ${_currentRound + 1} / $totalRounds',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB3B3B3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (!_showResult) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_fmt(_minValue.toInt())} ₽', style: const TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.bold)),
                    Text('${_fmt(_maxValue.toInt())} ₽', style: const TextStyle(color: Color(0xFFB3B3B3), fontWeight: FontWeight.bold)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFFE31E24),
                    inactiveTrackColor: const Color(0xFFD9D9D9),
                    thumbColor: Colors.white,
                    overlayColor: const Color(0x29E31E24),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    trackHeight: 6.0,
                  ),
                  child: Slider(
                    value: _currentValue,
                    min: _minValue,
                    max: _maxValue,
                    onChanged: (value) {
                      setState(() => _currentValue = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_fmt(_currentValue.toInt())} ₽',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ваша оценка залога',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB3B3B3),
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _isLoading ? null : _confirmGuess,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2D2D3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFFE31E24)),
                        const SizedBox(width: 8),
                        Text(
                          'Подтвердить оценку',
                          style: const TextStyle(
                            color: Color(0xFFE31E24),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getResultBgColor(_getTier(item)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(_getResultIcon(_getTier(item)), style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getResultMessage(_getTier(item)),
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${_getResultCoins(_getTier(item))} бонусов',
                            style: TextStyle(
                              color: _getResultCoins(_getTier(item)) > 0 ? const Color(0xFF4CAF50) : const Color(0xFFB3B3B3),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD9D9D9)),
                        ),
                        child: Column(
                          children: [
                            const Text('Ваша оценка', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${_fmt(_currentValue.toInt())} ₽', style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD9D9D9)),
                        ),
                        child: Column(
                          children: [
                            const Text('Реальная цена', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${_fmt(item.realPrice)} ₽', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 15, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _nextRound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31E24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: Text(
                      _currentRound + 1 >= totalRounds ? 'Получить результат 🏆' : 'Следующий предмет',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTier(GuessPriceItem item) {
    final diff = (_currentValue.toInt() - item.realPrice).abs();
    final accuracyPercent = (diff / item.realPrice * 100).round();
    if (accuracyPercent <= 5) return 'exact';
    if (accuracyPercent <= 15) return 'close';
    if (accuracyPercent <= 30) return 'miss';
    return 'far';
  }

  Color _getResultBgColor(String tier) {
    switch (tier) {
      case 'exact':
        return const Color(0xFF4CAF50).withOpacity(0.15);
      case 'close':
        return const Color(0xFFFF9800).withOpacity(0.15);
      default:
        return const Color(0xFFE31E24).withOpacity(0.15);
    }
  }

  String _getResultIcon(String tier) {
    switch (tier) {
      case 'exact': return '🎯';
      case 'close': return '👍';
      case 'miss': return '📉';
      default: return '❌';
    }
  }

  String _getResultMessage(String tier) {
    switch (tier) {
      case 'exact': return 'Точное попадание!';
      case 'close': return 'Близко!';
      case 'miss': return 'Мимо...';
      default: return 'Далеко от цены';
    }
  }

  int _getResultCoins(String tier) {
    switch (tier) {
      case 'exact': return 200;
      case 'close': return 100;
      case 'miss': return 30;
      default: return 0;
    }
  }
}

class _FinalDialog extends StatelessWidget {
  final int earned;
  final int hits;
  final int totalRounds;
  final VoidCallback onPlayAgain;

  const _FinalDialog({
    required this.earned,
    required this.hits,
    required this.totalRounds,
    required this.onPlayAgain,
  });

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );

  @override
  Widget build(BuildContext context) {
    String trophy;
    String grade;
    if (hits >= 4) {
      trophy = '🏆';
      grade = 'Мастер-оценщик';
    } else if (hits >= 2) {
      trophy = '🥈';
      grade = 'Опытный оценщик';
    } else {
      trophy = '🥉';
      grade = 'Новичок';
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trophy, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(grade, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Игра завершена!', style: TextStyle(color: Color(0xFF808080), fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2D2D3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond_outlined, color: Color(0xFFE31E24), size: 22),
                  const SizedBox(width: 8),
                  Text('+${_fmt(earned)}', style: const TextStyle(color: Color(0xFFE31E24), fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  const Text('бонусов', style: TextStyle(color: Color(0xFFE31E24), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('$hits', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('точных', style: TextStyle(color: Color(0xFF808080), fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('${totalRounds - hits}', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('промахов', style: TextStyle(color: Color(0xFF808080), fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onPlayAgain();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Сыграть ещё раз', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF808080),
                  side: const BorderSide(color: Color(0xFFD9D9D9)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined),
                    SizedBox(width: 8),
                    Text('На главную', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
