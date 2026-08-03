import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../config/theme.dart';
import '../../services/actividad_service.dart';
import '../../services/monedas_service.dart';

class ProblemaMatematico {
  final String id;
  final String nivel;
  final String pregunta;
  final String respuestaCorrecta;
  final List<String> opciones;
  final int monedasGanadas;
  final String emoji;

  ProblemaMatematico({
    required this.id,
    required this.nivel,
    required this.pregunta,
    required this.respuestaCorrecta,
    required this.opciones,
    required this.monedasGanadas,
    required this.emoji,
  });
}

class ProblemasMatematicosScreen extends StatefulWidget {
  const ProblemasMatematicosScreen({super.key});

  @override
  State<ProblemasMatematicosScreen> createState() => _ProblemasMatematicosScreenState();
}

class _ProblemasMatematicosScreenState extends State<ProblemasMatematicosScreen> {
  final ActividadService _actividadService = ActividadService();
  String _nivelSeleccionado = 'base';
  int _problemaActualIndex = 0;
  int _puntaje = 0;
  int _monedasGanadas = 0;
  bool _mostrarResultado = false;
  bool _problemaRespondido = false;
  String _mensajeFeedback = '';
  Color _colorFeedback = AppTheme.verde;
  int _monedasActuales = 0;
  bool _isCorrect = false;

  final List<ProblemaMatematico> _todosLosProblemas = [];

  List<ProblemaMatematico> get _problemasFiltrados {
    return _todosLosProblemas.where((p) => p.nivel == _nivelSeleccionado).toList();
  }

  @override
  void initState() {
    super.initState();
    _cargarProblemas();
    _inicializarMonedas();
    _cargarMonedasActuales();
    _verificarInstruccionesDelDia();
  }

  Future<void> _inicializarMonedas() async {
    try {
      await MonedasService().init();
    } catch (e) {
      print('❌ Error inicializando MonedasService: $e');
    }
  }

  Future<void> _cargarMonedasActuales() async {
    try {
      final monedas = MonedasService().obtenerMonedas();
      setState(() {
        _monedasActuales = monedas;
      });
    } catch (e) {
      print('Error cargando monedas: $e');
    }
  }

  Future<int> _obtenerProblemasResueltosHoy() async {
    final box = await Hive.openBox('progreso_matematicas');
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    return box.get('problemas_resueltos_$hoy', defaultValue: 0);
  }

  Future<void> _guardarProblemaResueltoHoy() async {
    final box = await Hive.openBox('progreso_matematicas');
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final actual = await _obtenerProblemasResueltosHoy();
    await box.put('problemas_resueltos_$hoy', actual + 1);
  }

  Future<bool> _puedeResolverHoy() async {
    final resueltos = await _obtenerProblemasResueltosHoy();
    return resueltos < 5;
  }

  Future<void> _verificarInstruccionesDelDia() async {
    final box = await Hive.openBox('configuracion');
    final ultimaFecha = box.get('ultima_instruccion_matematicas');
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    if (ultimaFecha != hoy) {
      _mostrarInstrucciones();
      await box.put('ultima_instruccion_matematicas', hoy);
    }
  }

  void _mostrarInstrucciones() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.verde.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calculate, color: AppTheme.verde, size: 40),
            ),
            const SizedBox(height: 12),
            const Text(
              '🧮 Problemas matemáticos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.verde),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Resuelve problemas para ganar monedas y mejorar tus habilidades.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.bolt, 'Hasta 5 problemas por día', Colors.amber),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.emoji_events, 'Gana monedas por cada acierto', AppTheme.verde),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.rocket_launch, '4 niveles de dificultad', Colors.blue),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.verde,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '¡Comenzar!',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String texto, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  void _mostrarMensajeLimiteDiario() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
            const SizedBox(height: 8),
            const Text(
              '¡Excelente trabajo! 🎉',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.verde),
            ),
          ],
        ),
        content: const Text(
          'Has completado tus 5 problemas de hoy.\n\n¡Descansa y vuelve mañana! 🌱',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.verde,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                '¡Vale!',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cargarProblemas() {
    _todosLosProblemas.addAll([
      // Base
      ProblemaMatematico(id: 'base_1', nivel: 'base', pregunta: 'En una caja hay 18 lombrices y en otra hay 24. ¿Cuántas lombrices hay en total?', respuestaCorrecta: '42', opciones: ['38', '42', '44', '48'], monedasGanadas: 2, emoji: '➕'),
      ProblemaMatematico(id: 'base_2', nivel: 'base', pregunta: 'En un lombricario había 60 lombrices. Si regalaron 18, ¿cuántas quedaron?', respuestaCorrecta: '42', opciones: ['38', '42', '44', '48'], monedasGanadas: 2, emoji: '➖'),
      ProblemaMatematico(id: 'base_3', nivel: 'base', pregunta: 'Cada caja tiene 30 lombrices. Si hay 7 cajas, ¿cuántas lombrices hay en total?', respuestaCorrecta: '210', opciones: ['180', '200', '210', '240'], monedasGanadas: 2, emoji: '✖️'),
      ProblemaMatematico(id: 'base_4', nivel: 'base', pregunta: 'Una lombriz produce 2 gramos de humus por semana. Si hay 25 lombrices, ¿cuántos gramos de humus producen en una semana?', respuestaCorrecta: '50', opciones: ['40', '50', '60', '75'], monedasGanadas: 2, emoji: '🧮'),
      ProblemaMatematico(id: 'base_5', nivel: 'base', pregunta: 'Si una bolsa de humus pesa 5 kg y se llenan 8 bolsas, ¿cuántos kilogramos de humus hay en total?', respuestaCorrecta: '40', opciones: ['30', '35', '40', '45'], monedasGanadas: 2, emoji: '⚖️'),
      ProblemaMatematico(id: 'base_6', nivel: 'base', pregunta: 'En el huerto se usaron 36 kg de humus y quedaban 52 kg almacenados. ¿Cuántos kilogramos había al principio?', respuestaCorrecta: '88', opciones: ['78', '82', '88', '96'], monedasGanadas: 2, emoji: '📦'),
      ProblemaMatematico(id: 'base_7', nivel: 'base', pregunta: 'Un grupo de estudiantes recolectó 48 cáscaras de frutas. Si las repartieron en 6 cajas para las lombrices, ¿cuántas cáscaras pusieron en cada caja?', respuestaCorrecta: '8', opciones: ['6', '7', '8', '9'], monedasGanadas: 2, emoji: '➗'),
      ProblemaMatematico(id: 'base_8', nivel: 'base', pregunta: 'Hay 54 lombrices y se quieren repartir por igual en 9 recipientes. ¿Cuántas lombrices habrá en cada recipiente?', respuestaCorrecta: '6', opciones: ['4', '5', '6', '7'], monedasGanadas: 2, emoji: '📦'),

      // Bronce
      ProblemaMatematico(id: 'bronce_1', nivel: 'bronce', pregunta: 'Una familia separó 4 kg de residuos orgánicos cada día durante 7 días. ¿Cuántos kilogramos separaron en total?', respuestaCorrecta: '28', opciones: ['24', '26', '28', '32'], monedasGanadas: 3, emoji: '🗑️'),
      ProblemaMatematico(id: 'bronce_2', nivel: 'bronce', pregunta: 'Si una bolsa de humus cuesta \$35 y una persona compra 4 bolsas, ¿cuánto debe pagar?', respuestaCorrecta: '140', opciones: ['120', '130', '140', '150'], monedasGanadas: 3, emoji: '💰'),
      ProblemaMatematico(id: 'bronce_3', nivel: 'bronce', pregunta: 'Una escuela vendió 9 bolsas de humus a \$40 cada una. ¿Cuánto dinero obtuvo?', respuestaCorrecta: '360', opciones: ['320', '340', '360', '400'], monedasGanadas: 3, emoji: '🏫'),
      ProblemaMatematico(id: 'bronce_4', nivel: 'bronce', pregunta: 'En un taller participaron 32 niños. Si se formaron equipos de 4 integrantes, ¿cuántos equipos se hicieron?', respuestaCorrecta: '8', opciones: ['6', '7', '8', '9'], monedasGanadas: 3, emoji: '👥'),
      ProblemaMatematico(id: 'bronce_5', nivel: 'bronce', pregunta: 'Una lombriz mide aproximadamente 8 cm. Si colocas 6 lombrices una tras otra, ¿cuántos centímetros medirían en total?', respuestaCorrecta: '48', opciones: ['40', '42', '46', '48'], monedasGanadas: 3, emoji: '📏'),
      ProblemaMatematico(id: 'bronce_6', nivel: 'bronce', pregunta: 'Se recolectaron 72 hojas secas y se repartieron en 8 montones iguales. ¿Cuántas hojas quedaron en cada montón?', respuestaCorrecta: '9', opciones: ['7', '8', '9', '10'], monedasGanadas: 3, emoji: '🍂'),
      ProblemaMatematico(id: 'bronce_7', nivel: 'bronce', pregunta: 'Si cada planta necesita 2 puños de humus y hay 18 plantas, ¿cuántos puños de humus se necesitan?', respuestaCorrecta: '36', opciones: ['30', '32', '34', '36'], monedasGanadas: 3, emoji: '🌱'),
      ProblemaMatematico(id: 'bronce_8', nivel: 'bronce', pregunta: 'En una semana nacieron 40 lombrices nuevas. Si ya había 125, ¿cuántas hay ahora?', respuestaCorrecta: '165', opciones: ['155', '160', '165', '170'], monedasGanadas: 3, emoji: '🪱'),

      // Plata
      ProblemaMatematico(id: 'plata_1', nivel: 'plata', pregunta: 'Se prepararon 10 cajas para lombrices y en cada una se colocaron 15 lombrices. ¿Cuántas lombrices se utilizaron?', respuestaCorrecta: '150', opciones: ['140', '145', '150', '160'], monedasGanadas: 4, emoji: '📦'),
      ProblemaMatematico(id: 'plata_2', nivel: 'plata', pregunta: 'Si un kilogramo de humus cuesta \$28 y una persona compra 6 kg, ¿cuánto pagará?', respuestaCorrecta: '168', opciones: ['148', '158', '168', '178'], monedasGanadas: 4, emoji: '💰'),
      ProblemaMatematico(id: 'plata_3', nivel: 'plata', pregunta: 'En un huerto había 96 plantas. Si se abonaron primero 58, ¿cuántas plantas faltan por abonar?', respuestaCorrecta: '38', opciones: ['28', '32', '38', '42'], monedasGanadas: 4, emoji: '🌿'),
      ProblemaMatematico(id: 'plata_4', nivel: 'plata', pregunta: 'En el criadero hay 8 cajas con 25 lombrices cada una. ¿Cuántas lombrices hay en total?', respuestaCorrecta: '200', opciones: ['180', '190', '200', '220'], monedasGanadas: 4, emoji: '🏠'),
      ProblemaMatematico(id: 'plata_5', nivel: 'plata', pregunta: 'Si una lombriz cuesta \$1.50 y un cliente compra 6, ¿cuánto debe pagar?', respuestaCorrecta: '9.00', opciones: ['7.50', '8.00', '9.00', '10.50'], monedasGanadas: 4, emoji: '🪱'),
      ProblemaMatematico(id: 'plata_6', nivel: 'plata', pregunta: 'Se vendieron 15 lombrices a \$1.50 cada una. ¿Cuánto dinero se obtuvo?', respuestaCorrecta: '22.50', opciones: ['18.50', '20.00', '22.50', '24.00'], monedasGanadas: 4, emoji: '💰'),
      ProblemaMatematico(id: 'plata_7', nivel: 'plata', pregunta: 'Hay 240 lombrices y se quieren repartir en 8 cajas con la misma cantidad. ¿Cuántas lombrices irán en cada caja?', respuestaCorrecta: '30', opciones: ['25', '28', '30', '32'], monedasGanadas: 4, emoji: '📦'),
      ProblemaMatematico(id: 'plata_8', nivel: 'plata', pregunta: 'Se tienen 180 lombrices y cada cliente compra 12. ¿A cuántos clientes se les puede vender?', respuestaCorrecta: '15', opciones: ['12', '13', '14', '15'], monedasGanadas: 4, emoji: '👥'),

      // Oro
      ProblemaMatematico(id: 'oro_1', nivel: 'oro', pregunta: 'Una lombriz cuesta \$1.50. ¿Cuánto costarán 28 lombrices?', respuestaCorrecta: '42.00', opciones: ['36.00', '40.00', '42.00', '48.00'], monedasGanadas: 5, emoji: '💎'),
      ProblemaMatematico(id: 'oro_2', nivel: 'oro', pregunta: 'Si 20 lombrices cuestan \$30, ¿cuánto costarán 45 lombrices si el precio por lombriz es el mismo?', respuestaCorrecta: '67.50', opciones: ['60.00', '65.00', '67.50', '72.00'], monedasGanadas: 5, emoji: '🧮'),
      ProblemaMatematico(id: 'oro_3', nivel: 'oro', pregunta: 'En una semana se vendieron 120 lombrices. Si cada una costó \$0.50, ¿cuál fue el ingreso total?', respuestaCorrecta: '60.00', opciones: ['50.00', '55.00', '60.00', '65.00'], monedasGanadas: 5, emoji: '🏪'),
      ProblemaMatematico(id: 'oro_4', nivel: 'oro', pregunta: 'Un criadero tenía 500 lombrices. Vendió 175 y después nacieron 80 más. ¿Cuántas lombrices tiene ahora?', respuestaCorrecta: '405', opciones: ['385', '395', '405', '415'], monedasGanadas: 5, emoji: '🏠'),
      ProblemaMatematico(id: 'oro_5', nivel: 'oro', pregunta: 'Si 20 lombrices cuestan \$30, ¿cuánto costarán 50 lombrices?', respuestaCorrecta: '75.00', opciones: ['65.00', '70.00', '75.00', '80.00'], monedasGanadas: 5, emoji: '💰'),
      ProblemaMatematico(id: 'oro_6', nivel: 'oro', pregunta: 'Si 80 lombrices cuestan \$120, ¿cuánto costarán 150 lombrices?', respuestaCorrecta: '225.00', opciones: ['200.00', '210.00', '225.00', '240.00'], monedasGanadas: 5, emoji: '🧮'),
      ProblemaMatematico(id: 'oro_7', nivel: 'oro', pregunta: 'Un cliente compró 40 lombrices por \$60. Si otro cliente quiere 75 lombrices, ¿cuánto deberá pagar?', respuestaCorrecta: '112.50', opciones: ['100.00', '105.00', '112.50', '120.00'], monedasGanadas: 5, emoji: '🪱'),
      ProblemaMatematico(id: 'oro_8', nivel: 'oro', pregunta: 'Si con 100 lombrices se pueden iniciar 4 camas de lombricomposta, ¿cuántas camas se pueden iniciar con 250 lombrices?', respuestaCorrecta: '10', opciones: ['8', '9', '10', '12'], monedasGanadas: 5, emoji: '🏆'),
    ]);
  }

  Color _getColorNivel(String nivel) {
    switch (nivel) {
      case 'base': return const Color(0xFF58CC71);
      case 'bronce': return const Color(0xFFD4A373);
      case 'plata': return const Color(0xFFA8A8A8);
      case 'oro': return const Color(0xFFFFC107);
      default: return AppTheme.verde;
    }
  }

  String _getEmojiNivel(String nivel) {
    switch (nivel) {
      case 'base': return '🌱';
      case 'bronce': return '🥉';
      case 'plata': return '🥈';
      case 'oro': return '🥇';
      default: return '⭐';
    }
  }

  String _getNombreNivel(String nivel) {
    switch (nivel) {
      case 'base': return 'Base';
      case 'bronce': return 'Bronce';
      case 'plata': return 'Plata';
      case 'oro': return 'Oro';
      default: return '';
    }
  }

  void _seleccionarNivel(String nivel) {
    setState(() {
      _nivelSeleccionado = nivel;
      _problemaActualIndex = 0;
      _puntaje = 0;
      _monedasGanadas = 0;
      _mostrarResultado = false;
      _problemaRespondido = false;
      _isCorrect = false;
    });
  }

  void _responderOpcion(String opcionSeleccionada) async {
    if (_problemaRespondido) return;

    final puedeResolver = await _puedeResolverHoy();
    if (!puedeResolver) {
      _mostrarMensajeLimiteDiario();
      return;
    }

    final problema = _problemasFiltrados[_problemaActualIndex];
    final bool esCorrecto = opcionSeleccionada == problema.respuestaCorrecta;

    setState(() {
      _problemaRespondido = true;
      _isCorrect = esCorrecto;
      if (esCorrecto) {
        _puntaje++;
        _monedasGanadas += problema.monedasGanadas;
        _mensajeFeedback = '¡Excelente! +${problema.monedasGanadas} monedas 🎉';
        _colorFeedback = AppTheme.verde;
      } else {
        _mensajeFeedback = '¡Ups! La correcta era ${problema.respuestaCorrecta}';
        _colorFeedback = Colors.red;
      }
    });

    if (esCorrecto) {
      await _guardarProblemaResueltoHoy();
      await MonedasService().agregarMonedas(problema.monedasGanadas);
      await _cargarMonedasActuales();
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _problemaRespondido = false;
        if (_problemaActualIndex < _problemasFiltrados.length - 1) {
          _problemaActualIndex++;
        } else {
          _mostrarResultado = true;
          _guardarMonedasGanadas();
        }
      });
    });
  }

  void _guardarMonedasGanadas() async {
    if (_monedasGanadas > 0) {
      try {
        await MonedasService().agregarMonedas(_monedasGanadas);
        await _cargarMonedasActuales();
        _actividadService.registrarActividad();
      } catch (e) {
        print('Error guardando monedas: $e');
      }
    }
  }

  void _reiniciarNivel() {
    setState(() {
      _problemaActualIndex = 0;
      _puntaje = 0;
      _monedasGanadas = 0;
      _mostrarResultado = false;
      _problemaRespondido = false;
      _isCorrect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58CC71),
      appBar: AppBar(
        title: const Text(
          '🧮 Problemas matemáticos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF58CC71),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_monedasActuales',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Niveles
              Row(
                children: [
                  _buildNivelButton('base', '🌱', 'Base'),
                  const SizedBox(width: 8),
                  _buildNivelButton('bronce', '🥉', 'Bronce'),
                  const SizedBox(width: 8),
                  _buildNivelButton('plata', '🥈', 'Plata'),
                  const SizedBox(width: 8),
                  _buildNivelButton('oro', '🥇', 'Oro'),
                ],
              ),
              const SizedBox(height: 12),
              // Progreso diario
              FutureBuilder<int>(
                future: _obtenerProblemasResueltosHoy(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final resueltos = snapshot.data!;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.today, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Hoy: $resueltos/5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (resueltos >= 5) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, color: Colors.amber, size: 18),
                          ],
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              // Problema
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _mostrarResultado
                      ? _buildResultado()
                      : _buildProblema(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNivelButton(String nivel, String emoji, String label) {
    final isSelected = _nivelSeleccionado == nivel;
    final color = _getColorNivel(nivel);
    return Expanded(
      child: GestureDetector(
        onTap: () => _seleccionarNivel(nivel),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblema() {
    final problemas = _problemasFiltrados;
    if (problemas.isEmpty) {
      return const Center(child: Text('No hay problemas en este nivel'));
    }
    final problema = problemas[_problemaActualIndex];
    final total = problemas.length;
    final colorNivel = _getColorNivel(_nivelSeleccionado);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_getEmojiNivel(_nivelSeleccionado)} ${_getNombreNivel(_nivelSeleccionado)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: colorNivel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorNivel.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_problemaActualIndex + 1}/$total',
                      style: TextStyle(fontSize: 12, color: colorNivel),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_puntaje',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: (_problemaActualIndex + 1) / total,
              child: Container(
                decoration: BoxDecoration(
                  color: colorNivel,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Pregunta
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorNivel.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  problema.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  problema.pregunta,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Opciones
          ...problema.opciones.map((opcion) {
            Color? bgColor = Colors.grey.shade50;
            Color? borderColor = Colors.grey.shade200;
            Color? textColor = Colors.black87;

            if (_problemaRespondido) {
              if (opcion == problema.respuestaCorrecta) {
                bgColor = const Color(0xFFE8F5E9);
                borderColor = AppTheme.verde;
                textColor = AppTheme.verde;
              } else if (opcion != problema.respuestaCorrecta) {
                bgColor = Colors.grey.shade100;
                borderColor = Colors.grey.shade300;
                textColor = Colors.grey;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: _problemaRespondido ? null : () => _responderOpcion(opcion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _problemaRespondido && opcion == problema.respuestaCorrecta
                              ? AppTheme.verde
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + problema.opciones.indexOf(opcion)),
                            style: TextStyle(
                              color: _problemaRespondido && opcion == problema.respuestaCorrecta
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opcion,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (_problemaRespondido && opcion == problema.respuestaCorrecta)
                        const Icon(Icons.check_circle, color: AppTheme.verde, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          // Feedback
          if (_problemaRespondido)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _colorFeedback.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _colorFeedback.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _colorFeedback == AppTheme.verde ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                    color: _colorFeedback,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _mensajeFeedback,
                    style: TextStyle(
                      color: _colorFeedback,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final total = _problemasFiltrados.length;
    final aciertos = _puntaje;
    final porcentaje = total > 0 ? (aciertos / total * 100).round() : 0;

    String mensajeFinal;
    IconData iconoFinal;
    Color colorFinal;
    String tituloFinal;

    if (porcentaje == 100) {
      tituloFinal = '🎉 ¡Perfecto!';
      mensajeFinal = '¡Resolviste todos correctamente!';
      iconoFinal = Icons.emoji_events;
      colorFinal = Colors.amber;
    } else if (porcentaje >= 70) {
      tituloFinal = '😊 ¡Muy bien!';
      mensajeFinal = 'Sigue practicando para llegar al 100%';
      iconoFinal = Icons.star;
      colorFinal = AppTheme.verde;
    } else if (porcentaje >= 50) {
      tituloFinal = '🤔 ¡Buen intento!';
      mensajeFinal = 'Revisa los errores y vuelve a intentar';
      iconoFinal = Icons.school;
      colorFinal = Colors.orange;
    } else {
      tituloFinal = '💪 ¡No te rindas!';
      mensajeFinal = 'Practica más y lo lograrás';
      iconoFinal = Icons.favorite;
      colorFinal = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorFinal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconoFinal, size: 72, color: colorFinal),
          ),
          const SizedBox(height: 16),
          Text(
            tituloFinal,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            mensajeFinal,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: colorFinal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorFinal.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$aciertos/$total',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colorFinal,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorFinal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$porcentaje%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorFinal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Text(
                  '+$_monedasGanadas monedas',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _reiniciarNivel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getColorNivel(_nivelSeleccionado),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  '🔄 Repetir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  '⬅️ Volver',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}