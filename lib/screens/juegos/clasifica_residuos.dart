import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/logros_service.dart';
import '../../services/monedas_service.dart';
import '../../services/sound_service.dart';

class ClasificaResiduosScreen extends StatefulWidget {
  const ClasificaResiduosScreen({super.key});

  @override
  State<ClasificaResiduosScreen> createState() =>
      _ClasificaResiduosScreenState();
}

class _ClasificaResiduosScreenState extends State<ClasificaResiduosScreen> {
  int _aciertos = 0;
  int _errores = 0;
  int _ronda = 0;
  bool _juegoTerminado = false;
  String _mensaje = 'Arrastra cada residuo al contenedor correcto';
  bool _monedasOtorgadas = false;

  // Lista de residuos para clasificar
  final List<Map<String, dynamic>> _residuos = [
    {'nombre': 'Cáscara de plátano', 'emoji': '🍌', 'correcto': true},
    {'nombre': 'Botella de plástico', 'emoji': '🧴', 'correcto': false},
    {'nombre': 'Cáscara de huevo', 'emoji': '🥚', 'correcto': true},
    {'nombre': 'Lata de aluminio', 'emoji': '🥫', 'correcto': false},
    {'nombre': 'Restos de café', 'emoji': '☕', 'correcto': true},
    {'nombre': 'Bolsa de plástico', 'emoji': '🛍️', 'correcto': false},
    {'nombre': 'Hojas secas', 'emoji': '🍂', 'correcto': true},
    {'nombre': 'Pila/batería', 'emoji': '🔋', 'correcto': false},
  ];

  List<Map<String, dynamic>> _residuosPendientes = [];
  final bool _arrastrando = false;

  @override
  void initState() {
    super.initState();
    _iniciarRonda();
  }

  void _iniciarRonda() {
    setState(() {
      _residuosPendientes = List.from(_residuos)..shuffle();
      _ronda++;
      if (_ronda > 3) {
        _juegoTerminado = true;
        _mensaje = _aciertos >= 6
            ? '¡Eres un Lombrikid! 🌟'
            : '¡Sigue practicando! 💪';

        // ✅ Dar monedas al terminar el juego (si no se dieron antes)
        if (!_monedasOtorgadas && _aciertos >= 6) {
          _otorgarMonedas();
        }
      } else {
        _mensaje = 'Ronda $_ronda: ¡Clasifica los residuos! ♻️';
      }
    });
  }

  Future<void> _otorgarMonedas() async {
    _monedasOtorgadas = true;
    final monedasService = MonedasService();
    await monedasService.init();
    await monedasService.agregarMonedas(15);
    await SoundService.instance.monedasGanadas();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ganaste 15 monedas! 🪙'),
          backgroundColor: AppTheme.verde,
        ),
      );
    }
  }

  void _verificarRespuesta(
      Map<String, dynamic> residuo, bool contenedorComposta) {
    if (residuo['correcto'] == contenedorComposta) {
      setState(() {
        _aciertos++;
        if (_aciertos >= 3) {
          LogrosService().desbloquearInsignia('clasificador');
        }
        _mensaje =
            '✅ ¡Correcto! ${residuo['emoji']} va ${contenedorComposta ? "en la composta" : "en la basura"}';
        _residuosPendientes.remove(residuo);
      });

      SoundService.instance.retoCompletado();
    } else {
      setState(() {
        _errores++;
        _mensaje =
            '❌ ¡Ups! ${residuo['emoji']} NO va ${contenedorComposta ? "en la composta" : "en la basura"}';
      });
    }

    if (_residuosPendientes.isEmpty && !_juegoTerminado) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _iniciarRonda();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('♻️ Clasifica residuos'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('⭐ $_aciertos', style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
      body: _juegoTerminado ? _buildPantallaFinal() : _buildJuego(),
    );
  }

  Widget _buildJuego() {
    return Column(
      children: [
        // Mensaje
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.verde.withValues(alpha: 0.1),
          child: Text(
            _mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontFamily: 'Fredoka', color: AppTheme.cafe),
          ),
        ),

        // Contenedores
        Expanded(
          flex: 2,
          child: Row(
            children: [
              // Contenedor COMPOSTA
              Expanded(
                  child: _buildContenedor('🪱 Composta', AppTheme.verde, true)),
              // Contenedor BASURA
              Expanded(
                  child: _buildContenedor('🗑️ Basura', Colors.red, false)),
            ],
          ),
        ),

        // Residuos para arrastrar
        Expanded(
          flex: 3,
          child: _residuosPendientes.isEmpty
              ? const Center(
                  child: Text('¡Ronda completada! 🎉',
                      style: TextStyle(fontSize: 20)))
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _residuosPendientes.map((residuo) {
                    return _buildResiduo(residuo);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildContenedor(String label, Color color, bool esComposta) {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (detalles) {
        _verificarRespuesta(detalles.data, esComposta);
      },
      builder: (context, candidatos, rechazados) {
        final tieneCandidatos = candidatos.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tieneCandidatos
                ? color.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tieneCandidatos ? color : color.withValues(alpha: 0.5),
              width: tieneCandidatos ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label.split(' ')[0], style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'Fredoka',
                ),
              ),
              if (tieneCandidatos)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('¡Suelta aquí!',
                      style: TextStyle(fontSize: 14, color: AppTheme.cafe)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResiduo(Map<String, dynamic> residuo) {
    return Draggable<Map<String, dynamic>>(
      data: residuo,
      feedback: _tarjetaResiduo(residuo, true),
      childWhenDragging:
          Opacity(opacity: 0.3, child: _tarjetaResiduo(residuo, false)),
      child: _tarjetaResiduo(residuo, false),
    );
  }

  Widget _tarjetaResiduo(Map<String, dynamic> residuo, bool esFeedback) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esFeedback ? AppTheme.amarillo : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: esFeedback
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
              ],
        border: Border.all(color: AppTheme.cafe.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(residuo['emoji'], style: const TextStyle(fontSize: 35)),
          const SizedBox(height: 4),
          Text(
            residuo['nombre'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.cafe),
          ),
        ],
      ),
    );
  }

  Widget _buildPantallaFinal() {
    final ganaste = _aciertos >= 6;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ganaste ? '🏆' : '🌱', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              _mensaje,
              style: const TextStyle(
                  fontFamily: 'Fredoka', fontSize: 28, color: AppTheme.verde),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildEstadistica('✅ Aciertos', _aciertos, AppTheme.verde),
            _buildEstadistica('❌ Errores', _errores, Colors.red),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _aciertos = 0;
                  _errores = 0;
                  _ronda = 0;
                  _juegoTerminado = false;
                  _monedasOtorgadas = false;
                  _iniciarRonda();
                });
              },
              child: const Text('🔄 Jugar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadistica(String label, int valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$valor',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}
