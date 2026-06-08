import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class GuessPriceScreen extends StatefulWidget {
  const GuessPriceScreen({super.key});

  @override
  State<GuessPriceScreen> createState() => _GuessPriceScreenState();
}

class _GuessPriceScreenState extends State<GuessPriceScreen> with TickerProviderStateMixin {
  static const int totalRounds = 5;

  int _currentRound = 0;
  int _coins = 0;
  int _earned = 0;
  int _hits = 0;
  int _sliderValue = 0;
  bool _isLoading = false;
  bool _showResult = false;
  GuessPriceResult? _lastResult;
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
      _lastResult = null;
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

      final user = await ApiService.getMe();
      _coins = user.bonusBalance.toInt();

      _sliderValue = ((_items[0].minPrice + _items[0].maxPrice) / 2).round();

      setState(() => _isLoading = false);
    } catch (e) {
      _items = _getDefaultItems();
      _items.shuffle();
      if (_items.length > totalRounds) {
        _items = _items.sublist(0, totalRounds);
      }
      _sliderValue = ((_items[0].minPrice + _items[0].maxPrice) / 2).round();
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
    final guess = _sliderValue;
    final diff = (guess - item.realPrice).abs();
    final accuracyPercent = (diff / item.realPrice * 100).round();

    int coinsEarned;
    String tier;
    String icon;
    String message;
    Color resultColor;

    if (accuracyPercent <= 5) {
      coinsEarned = 200;
      tier = 'exact';
      icon = '🎯';
      message = 'Точное попадание!';
      resultColor = const Color(0xFF4CAF50);
    } else if (accuracyPercent <= 15) {
      coinsEarned = 100;
      tier = 'close';
      icon = '👍';
      message = 'Близко!';
      resultColor = const Color(0xFFFF9800);
    } else if (accuracyPercent <= 30) {
      coinsEarned = 30;
      tier = 'miss';
      icon = '📉';
      message = 'Мимо...';
      resultColor = const Color(0xFFE94560);
    } else {
      coinsEarned = 0;
      tier = 'far';
      icon = '❌';
      message = 'Далеко от цены';
      resultColor = const Color(0xFFE94560);
    }

    if (coinsEarned >= 100) _hits++;
    _earned += coinsEarned;

    try {
      _lastResult = await ApiService.submitGuessPrice(
        sessionId: _session?.sessionId ?? 0,
        itemId: item.id,
        guess: guess,
      );
    } catch (_) {
      _lastResult = GuessPriceResult(
        coinsEarned: coinsEarned,
        accuracy: accuracyPercent,
        tier: tier,
        message: message,
      );
    }

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
        _lastResult = null;
        final item = _items[_currentRound];
        _sliderValue = ((item.minPrice + item.maxPrice) / 2).round();
      });
    }
  }

  Future<void> _finishGame() async {
    try {
      await ApiService.finishGuessPrice(_session?.sessionId ?? 0);
    } catch (_) {}

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FinalDialog(
          coins: _coins + _earned,
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
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search, size: 60, color: Color(0xFFE94560)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFFE94560)),
              const SizedBox(height: 16),
              const Text('Загрузка...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final item = _items[_currentRound];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Оценщик'),
        backgroundColor: const Color(0xFF1D3557),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAEEDA),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('₽', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF633806))),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${_fmt(_coins)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress dots
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(totalRounds, (i) {
                        Color dotColor;
                        if (i < _currentRound || (_showResult && i == _currentRound)) {
                          dotColor = const Color(0xFF4CAF50);
                        } else if (i == _currentRound) {
                          dotColor = const Color(0xFF1D3557);
                        } else {
                          dotColor = Colors.white.withOpacity(0.2);
                        }
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Раунд ${_currentRound + 1} / $totalRounds',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Item card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_showResult) ...[
                // Slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_fmt(item.minPrice)} ₽', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('${_fmt(item.maxPrice)} ₽', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFE94560),
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: const Color(0xFFE94560),
                          overlayColor: const Color(0xFFE94560).withOpacity(0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        ),
                        child: Slider(
                          value: _sliderValue.toDouble(),
                          min: item.minPrice.toDouble(),
                          max: item.maxPrice.toDouble(),
                          divisions: (item.maxPrice - item.minPrice) ~/ 100,
                          onChanged: (val) {
                            setState(() => _sliderValue = val.round());
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_fmt(_sliderValue)} ₽',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ваша оценка залога',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Energy bar
                LinearProgressIndicator(
                  value: _currentRound / totalRounds,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D3557)),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmGuess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3557),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check),
                              SizedBox(width: 8),
                              Text('Подтвердить оценку', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ],
                          ),
                  ),
                ),
              ] else if (_lastResult != null) ...[
                // Result banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getResultBgColor(_lastResult!.tier),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(_getResultIcon(_lastResult!.tier), style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lastResult!.message,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${_lastResult!.coinsEarned} монет',
                            style: TextStyle(
                              color: _lastResult!.coinsEarned > 0 ? const Color(0xFF4CAF50) : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Answer comparison
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Ваша оценка', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('${_fmt(_sliderValue)} ₽', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Реальная цена', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('${_fmt(item.realPrice)} ₽', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Deviation
                Text(
                  'Отклонение: ${_fmt((_sliderValue - item.realPrice).abs())} ₽ (${_lastResult!.accuracy}%)',
                  style: TextStyle(
                    color: _lastResult!.accuracy <= 15 ? const Color(0xFF4CAF50) : const Color(0xFFE94560),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Next button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextRound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3557),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_currentRound + 1 >= totalRounds ? 'Получить результат 🏆' : 'Следующий предмет'),
                        const SizedBox(width: 8),
                        Icon(_currentRound + 1 >= totalRounds ? Icons.emoji_events : Icons.arrow_forward),
                      ],
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

  Color _getResultBgColor(String tier) {
    switch (tier) {
      case 'exact':
        return const Color(0xFF4CAF50).withOpacity(0.15);
      case 'close':
        return const Color(0xFFFF9800).withOpacity(0.15);
      default:
        return const Color(0xFFE94560).withOpacity(0.15);
    }
  }

  String _getResultIcon(String tier) {
    switch (tier) {
      case 'exact':
        return '🎯';
      case 'close':
        return '👍';
      case 'miss':
        return '📉';
      default:
        return '❌';
    }
  }
}

class _FinalDialog extends StatelessWidget {
  final int coins;
  final int earned;
  final int hits;
  final int totalRounds;
  final VoidCallback onPlayAgain;

  const _FinalDialog({
    required this.coins,
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
      backgroundColor: const Color(0xFF16213E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(trophy, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(grade, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Игра завершена!', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFBA7517), size: 22),
                  const SizedBox(width: 8),
                  Text('+${_fmt(earned)}', style: const TextStyle(color: Color(0xFF633806), fontSize: 26, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Text('монет', style: TextStyle(color: Color(0xFFBA7517), fontSize: 13)),
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
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('$hits', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('точных оценок', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('${totalRounds - hits}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('промахов', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text('${_fmt(coins)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('монет всего', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onPlayAgain();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D3557),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Сыграть ещё раз', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Поделиться', style: TextStyle(fontSize: 14)),
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
