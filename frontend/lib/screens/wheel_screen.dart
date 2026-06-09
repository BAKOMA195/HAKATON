import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> {
  Map<String, dynamic>? _spinsInfo;
  bool _isLoading = true;
  bool _isOpening = false;
  int _openedCount = 0;
  List<Map<String, dynamic>?> _chestResults = [null, null, null];
  int _currentlyOpeningIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadSpinsInfo();
  }

  Future<void> _loadSpinsInfo() async {
    try {
      final info = await ApiService.getSpinsInfo();
      if (mounted) {
        setState(() {
          _spinsInfo = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openChest(int index) async {
    if (_isOpening) return;
    if (_chestResults[index] != null) return;
    if (_openedCount >= 3) return;

    final isFirstChest = _openedCount == 0;
    final isPaidChest = _openedCount >= 1;

    if (isPaidChest) {
      final cost = _spinsInfo?['spin_cost'] ?? 50;
      final user = context.read<UserProvider>().user;
      if ((user?.bonusBalance ?? 0) < cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Недостаточно бонусов!')),
        );
        return;
      }
    }

    setState(() {
      _isOpening = true;
      _currentlyOpeningIndex = index;
    });

    try {
      final result = await ApiService.spinWheel(useFree: isFirstChest);

      if (mounted) {
        setState(() {
          _chestResults[index] = {
            'prizeType': result.prizeType,
            'prizeValue': result.prizeValue,
          };
          _openedCount++;
          _isOpening = false;
          _currentlyOpeningIndex = -1;
        });

        _showRewardDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _currentlyOpeningIndex = -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showRewardDialog(dynamic result) {
    String rewardText;
    IconData rewardIcon;

    if (result.prizeType == 'bonus') {
      rewardText = '${result.prizeValue.toInt()} БОНУСОВ';
      rewardIcon = Icons.monetization_on;
    } else if (result.prizeType == 'discount') {
      rewardText = 'СКИДКА ${result.prizeValue.toInt()}%';
      rewardIcon = Icons.percent;
    } else {
      rewardText = 'РЕДКИЙ БЕЙДЖ';
      rewardIcon = Icons.emoji_events;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 281,
          height: 242,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.black.withOpacity(0.65),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 41,
                top: 187,
                child: const SizedBox(
                  width: 199,
                  height: 25,
                  child: Text(
                    'НА КАРТУ ЛОЯЛЬНОСТИ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 57,
                top: 159,
                child: Text(
                  rewardText,
                  style: const TextStyle(
                    color: Color(0xFFFFC800),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 85,
                top: 20,
                child: Icon(
                  rewardIcon,
                  size: 110,
                  color: const Color(0xFFFFC800),
                ),
              ),
              Positioned(
                right: 15,
                top: 15,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (_openedCount >= 3) {
                      _loadSpinsInfo();
                      context.read<UserProvider>().refreshUser();
                    }
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xFFE31E24))
                : Container(
                    width: 390,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE31E24),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ШАПКА
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star, color: Color(0xFFE31E24), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'SKS QUEST',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ПОДЗАГОЛОВКИ
                        const Text(
                          'ВЫ ЗАХОДИЛИ В ИГРУ 7 ДНЕЙ ПОДРЯД',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ВЫБЕРИТЕ СУНДУК И ЗАБЕРИТЕ НАГРАДУ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFC800),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // СУНДУКИ И ЗВЁЗДОЧКИ
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              left: 10,
                              top: -20,
                              child: Icon(Icons.star, color: Color(0xFFFFC800), size: 32),
                            ),
                            const Positioned(
                              right: 10,
                              bottom: -20,
                              child: Icon(Icons.star, color: Color(0xFFFFC800), size: 24),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildChest(0),
                                _buildChest(1),
                                _buildChest(2),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // ИНФОРМАЦИЯ О СУНДУКАХ
                        if (_spinsInfo != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _openedCount == 0
                                      ? '1-й сундук — бесплатно!'
                                      : _openedCount < 3
                                          ? 'Открыто: $_openedCount / 3'
                                          : 'Все сундуки открыты! 🎉',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_openedCount >= 1 && _openedCount < 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Следующий сундук: ${_spinsInfo!['spin_cost'] ?? 50} бонусов',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildChest(int index) {
    final isOpened = _chestResults[index] != null;
    final canOpen = !isOpened && !_isOpening && _openedCount < 3;
    final isOpeningThis = _currentlyOpeningIndex == index;

    return GestureDetector(
      onTap: canOpen ? () => _openChest(index) : null,
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: isOpeningThis
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFFC800),
                      ),
                    ),
                  )
                : Image.asset(
                    isOpened
                        ? 'assets/chest_open.png'
                        : 'assets/chest_closed.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            isOpened
                ? 'Открыт!'
                : (_openedCount == 0)
                    ? 'Бесплатно'
                    : 'За 50 бон.',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isOpened ? const Color(0xFFFFC800) : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
