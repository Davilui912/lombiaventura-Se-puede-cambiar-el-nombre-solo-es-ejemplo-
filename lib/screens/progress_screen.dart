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
                        // NUEVA INSTRUCCIÓN ENTRE APP BAR Y RACHA
                        _InstruccionBanner(),
                        const SizedBox(height: 16),
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

// NUEVO BANNER DE INSTRUCCIÓN
class _InstruccionBanner extends StatelessWidget {
  const _InstruccionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD6ECFF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1B5E8C), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF1B5E8C),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu primer reto será llegar a los 15 días seguidos cuidando con éxito tu lombricompostero. ¡No pierdas tu racha! Recuerda registrar diariamente tus cuidados en "Mi Diario".',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF1B5E8C),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
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

/// Estado visual de una celda del calendario mensual.
enum DayStatus {
  /// Celda de relleno antes del día 1 del mes (no es un día real).
  blank,

  /// Día ya cumplido (racha activa ese día).
  completed,

  /// Día de hoy.
  today,

  /// Día futuro dentro del mes, aún no alcanzado.
  upcoming,

  /// Día pasado en el que se rompió la racha (opcional).
  missed,
}

class CalendarDay {
  final int? dayNumber;
  final DayStatus status;

  const CalendarDay({this.dayNumber, required this.status});
}

/// Calendario mensual tipo "Ce mois-ci" de Duolingo:
/// - Encabezado con las iniciales de los días de la semana.
/// - Cuadrícula de círculos: verde con check (completado),
///   dorado con flama (hoy), gris con número (próximo/perdido).
class MonthlyStreakCalendar extends StatelessWidget {
  final String title;
  final List<String> weekdayLabels;
  final List<CalendarDay> days;

  const MonthlyStreakCalendar({
    super.key,
    this.title = 'Calendario',
    this.weekdayLabels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
    required this.days,
  });

  /// Genera la lista de [CalendarDay] a partir de datos simples,
  /// para no tener que armar el enum a mano en cada pantalla.
  ///
  /// [firstWeekdayOffset]: cuántas celdas en blanco van antes del día 1
  /// (0 = el mes empieza en lunes, 1 = martes, ... 6 = domingo).
  static List<CalendarDay> buildDays({
    required int daysInMonth,
    required int firstWeekdayOffset,
    required Set<int> completedDays,
    Set<int> missedDays = const {},
    int? todayDay,
  }) {
    final days = <CalendarDay>[
      for (var i = 0; i < firstWeekdayOffset; i++)
        const CalendarDay(status: DayStatus.blank),
      for (var d = 1; d <= daysInMonth; d++)
        CalendarDay(
          dayNumber: d,
          status: d == todayDay
              ? DayStatus.today
              : completedDays.contains(d)
                  ? DayStatus.completed
                  : missedDays.contains(d)
                      ? DayStatus.missed
                      : DayStatus.upcoming,
        ),
    ];

    final remainder = days.length % 7;
    if (remainder != 0) {
      for (var i = 0; i < 7 - remainder; i++) {
        days.add(const CalendarDay(status: DayStatus.blank));
      }
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: weekdayLabels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) => _DayCell(day: days[index]),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final CalendarDay day;

  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    switch (day.status) {
      case DayStatus.blank:
        return _circle(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
          child: const SizedBox.shrink(),
        );

      case DayStatus.completed:
        return _circle(
          color: const Color(0xFF58CC02),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 18,
          ),
        );

      case DayStatus.today:
        return _circle(
          color: const Color(0xFFFFC800),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 18,
          ),
        );

      case DayStatus.missed:
        return _circle(
          color: const Color(0xFFF5F5F5),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          child: Text(
            '${day.dayNumber}',
            style: const TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );

      case DayStatus.upcoming:
        return _circle(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
          child: Text(
            '${day.dayNumber}',
            style: const TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
    }
  }

  Widget _circle({
    required Color color,
    Border? border,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
