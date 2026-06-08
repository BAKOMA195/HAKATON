import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with TickerProviderStateMixin {
  double _rotation = 0;
  bool _isSpinning = false;
  Map<String, dynamic>? _spinsInfo;
  String? _result;

  final List<Map<String, dynamic>> _prizes = [
    {'label': '10', 'color': const Color(0xFFE94560), 'value': 10},
    {'label': '25', 'color': const Color(0xFF9C27B0), 'value': 25},
    {'label': '50', 'color': const Color(0xFF2196F3), 'value': 50},
    {'label': '100', 'color': const Color(0xFF4CAF50), 'value': 100},
    {'label': '500', 'color': const Color(0xFFFF9800), 'value': 500},
    {'label': '5%', 'color': const Color(0xFF00BCD4), 'value': 0, 'type': 'discount'},
    {'label': '🎖', 'color': const Color(0xFF607D8B), 'value': 0, 'type': 'badge'},
    {'label': '25', 'color': const Color(0xFF9C27B0), 'value': 25},
  ];

  @override
  void initState() {
    super.initState();
    _loadSpinsInfo();
  }

  Future<void> _loadSpinsInfo() async {
    try {
      final info = await ApiService.getSpinsInfo();
      setState(() => _spinsInfo = info);
    } catch (_) {}
  }

  Future<void> _spin({bool free = true}) async {
    if (_isSpinning) return;
    setState(() => _isSpinning = true);

    try {
      final result = await ApiService.spinWheel(useFree: free);

      // Анимация вращения
      final randomAngle = math.pi * 2 * (5 + math.Random().nextDouble() * 5);
      setState(() => _rotation += randomAngle);

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isSpinning = false;
          _result = result.prizeType == 'bonus'
              ? 'Вы выиграли ${result.prizeValue.toInt()} бонусов!'
              : result.prizeType == 'discount'
                  ? 'Скидка ${result.prizeValue.toInt()}% на следующий ЗБ!'
                  : 'Редкий бейдж!';
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('🎰 Результат!', style: TextStyle(color: Colors.white)),
            content: Text(
              _result!,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadSpinsInfo();
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFFE94560))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSpinning = false);
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
        title: const Text('Колесо фортуны'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Колесо
              SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Указатель
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 0,
                        height: 0,
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: const Color(0xFFE94560),
                              width: 15,
                            ),
                            vertical: BorderSide(
                              color: Colors.transparent,
                              width: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Вращающееся колесо
                    AnimatedBuilder(
                      animation: Listenable.merge([]),
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotation,
                          child: CustomPaint(
                            size: const Size(280, 280),
                            painter: WheelPainter(prizes: _prizes),
                          ),
                        );
                      },
                    ),
                    // Центр колеса
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A2E),
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Color(0xFFE94560), width: 3),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'SKS',
                          style: TextStyle(
                            color: Color(0xFFE94560),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Информация о прокрутках
              if (_spinsInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Бесплатная', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            _spinsInfo!['free_spin_available'] == true ? '✅ Да' : '❌ Нет',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Платные сегодня', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '${_spinsInfo!['paid_spins_today']}/${_spinsInfo!['paid_spins_remaining'] + _spinsInfo!['paid_spins_today']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Стоимость', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '${_spinsInfo!['spin_cost']} бон.',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isSpinning || _spinsInfo?['free_spin_available'] != true) ? null : () => _spin(free: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Бесплатная', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isSpinning || _spinsInfo?['paid_spins_remaining'] == 0) ? null : () => _spin(free: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('За 50 бон.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Таблица вероятностей
              const Text(
                'Вероятности призов (прозрачность):',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _prizes.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: p['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p['color']),
                    ),
                    child: Text(
                      '${p['label']} бон.',
                      style: TextStyle(color: p['color'], fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;

  WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * math.pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final startAngle = i * sliceAngle - math.pi / 2;

      final paint = Paint()
        ..color = prizes[i]['color']
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Текст
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sliceAngle / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i]['label'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius * 0.6 - textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }

    // Обводка
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
