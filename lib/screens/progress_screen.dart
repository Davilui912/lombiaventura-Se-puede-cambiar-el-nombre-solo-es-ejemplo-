import 'package:flutter/material.dart';
import '../services/actividad_service.dart';
import '../services/monedas_service.dart';

class ProgressScreen extends StatefulWidget {
  final int coins;
  final int streakDays;
  final int recordDays;
  final VoidCallback? onBack;

  const ProgressScreen({
    super.key,
    required this.coins,
    required this.streakDays,
    required this.recordDays,
    this.onBack,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final Future<int> _coinsFuture;
  late Future<int> _streakFuture;

  @override
  void initState() {
    super.initState();
    _coinsFuture = _loadCurrentCoins();
    _streakFuture = _loadCurrentStreak();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _streakFuture = _loadCurrentStreak();
  }

  Future<int> _loadCurrentCoins() async {
    await MonedasService().init();
    return MonedasService().obtenerMonedas();
  }

  Future<int> _loadCurrentStreak() async {
    return ActividadService().obtenerRacha();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FutureBuilder<int>(
          future: _coinsFuture,
          builder: (context, snapshot) {
            final coins = snapshot.data ?? widget.coins;
            return Column(
              children: [
                _TopBar(
                  coins: coins,
                  onBack:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
                ),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FutureBuilder<int>(
                          future: _streakFuture,
                          builder: (context, snapshot) {
                            final streakDays =
                                snapshot.data ?? widget.streakDays;
                            return _StreakBanner(days: streakDays);
                          },
                        ),
                        const SizedBox(height: 16),
                        _RecordCard(days: widget.recordDays),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --------Barra superior: botón de retroceso + título + monedas----------
class _TopBar extends StatelessWidget {
  final int coins;
  final VoidCallback onBack;

  const _TopBar({required this.coins, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _BackButton(onTap: onBack),
              const SizedBox(width: 12),
              const Text(
                'Progreso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C8C1C),
                ),
              ),
            ],
          ),
          _CoinPill(coins: coins),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF8E9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF58CC02), width: 2),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF3C8C1C),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;

  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$coins',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFC800),
            size: 22,
          ),
        ],
      ),
    );
  }
}

// -------Banner de racha (franjas diagonales + fuego + texto)----------
class _StreakBanner extends StatelessWidget {
  final int days;

  const _StreakBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalStripesPainter(
                  baseColor: const Color(0xFFFFC107),
                  stripeColor: const Color(0xFFFFB300),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFF7A5200),
                    size: 56,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$days días !',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '¡Sigue así, Lombrikid!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A5200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja franjas diagonales de dos tonos, tipo "peligro/premio",
/// dentro del área del banner de racha.
class _DiagonalStripesPainter extends CustomPainter {
  final Color baseColor;
  final Color stripeColor;

  _DiagonalStripesPainter({
    required this.baseColor,
    required this.stripeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final stripePaint = Paint()..color = stripeColor;
    const stripeWidth = 26.0;
    const gap = 26.0;
    final diagonal = size.width + size.height;

    for (double x = -size.height; x < diagonal; x += stripeWidth + gap) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth - size.height, size.height)
        ..lineTo(x - size.height, size.height)
        ..close();
      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.stripeColor != stripeColor;
  }
}

// -------Tarjeta de récord----------
class _RecordCard extends StatelessWidget {
  final int days;

  const _RecordCard({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFD6ECFF),
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1B5E8C), width: 3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFF1B5E8C),
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'RECORD',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFF1B5E8C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$days días',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
