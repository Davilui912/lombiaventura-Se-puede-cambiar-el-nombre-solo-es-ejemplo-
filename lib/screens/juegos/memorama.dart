import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/logros_service.dart';
import '../../services/monedas_service.dart';
import '../../services/sound_service.dart';

class MemoramaScreen extends StatefulWidget {
  const MemoramaScreen({super.key});

  @override
  State<MemoramaScreen> createState() => _MemoramaScreenState();
}

class _MemoramaScreenState extends State<MemoramaScreen> {
  // ✅ IMÁGENES para las parejas
  final List<Map<String, String>> _parejasBase = [
    {'imagen': 'assets/images/memorama/Lombrices.png', 'nombre': 'Lombrices'},
    {'imagen': 'assets/images/memorama/Compostaje.png', 'nombre': 'Compostaje'},
    {'imagen': 'assets/images/memorama/Humus.png', 'nombre': 'Humus'},
    {'imagen': 'assets/images/memorama/Lixiviado.png', 'nombre': 'Lixiviado'},
    {
      'imagen': 'assets/images/memorama/Lombricultura.png',
      'nombre': 'Lombricultura'
    },
    {
      'imagen': 'assets/images/memorama/Materia_organica.png',
      'nombre': 'Materia organica'
    },
    {
      'imagen': 'assets/images/memorama/Planta_crecimiento.png',
      'nombre': 'Plnata en crecimiento'
    },
    {
      'imagen': 'assets/images/memorama/Composteria.png',
      'nombre': 'Composteria'
    },
  ];

  List<Map<String, dynamic>> _cartas = [];
  int? _primeraCarta;
  int? _segundaCarta;
  int _paresEncontrados = 0;
  int _intentos = 0;
  bool _bloqueado = false;
  bool _juegoTerminado = false;
  bool _monedasOtorgadas = false;

  @override
  void initState() {
    super.initState();
    _iniciarJuego();
  }

  void _iniciarJuego() {
    List<Map<String, dynamic>> cartas = [];
    for (var pareja in _parejasBase) {
      // Carta 1: Imagen
      cartas.add({
        'tipo': 'imagen',
        'contenido': pareja['imagen'],
        'nombre': pareja['nombre'],
        'parejaId': pareja['nombre'],
        'volteada': false,
        'encontrada': false,
      });
      // Carta 2: Texto (nombre)
      cartas.add({
        'tipo': 'texto',
        'contenido': pareja['nombre'],
        'nombre': pareja['nombre'],
        'parejaId': pareja['nombre'],
        'volteada': false,
        'encontrada': false,
      });
    }

    cartas.shuffle(Random());

    setState(() {
      _cartas = cartas;
      _primeraCarta = null;
      _segundaCarta = null;
      _paresEncontrados = 0;
      _intentos = 0;
      _bloqueado = false;
      _juegoTerminado = false;
      _monedasOtorgadas = false;
    });
  }

  Future<void> _otorgarMonedas() async {
    _monedasOtorgadas = true;
    final monedasService = MonedasService();
    await monedasService.init();
    await monedasService.agregarMonedas(25);
    await SoundService.instance.monedasGanadas();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Completaste el memorama! Ganaste 25 monedas 🪙'),
          backgroundColor: AppTheme.verde,
        ),
      );
    }
  }

  void _voltearCarta(int index) {
    if (_bloqueado) return;
    if (_cartas[index]['encontrada']) return;
    if (_primeraCarta == index) return;

    setState(() {
      _cartas[index]['volteada'] = true;
    });

    if (_primeraCarta == null) {
      setState(() {
        _primeraCarta = index;
      });
    } else {
      setState(() {
        _segundaCarta = index;
        _intentos++;
        _bloqueado = true;
      });
      _verificarPareja();
    }
  }

  void _verificarPareja() {
    final carta1 = _cartas[_primeraCarta!];
    final carta2 = _cartas[_segundaCarta!];

    final sonPareja = carta1['parejaId'] == carta2['parejaId'] &&
        carta1['tipo'] != carta2['tipo'];

    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      setState(() {
        if (sonPareja) {
          _cartas[_primeraCarta!]['encontrada'] = true;
          _cartas[_segundaCarta!]['encontrada'] = true;
          _paresEncontrados++;

          if (_paresEncontrados >= 4) {
            LogrosService().desbloquearInsignia('memorion');
            SoundService.instance.logroDesbloqueado();
          }

          if (_paresEncontrados == _parejasBase.length) {
            _juegoTerminado = true;
            _otorgarMonedas();
          }
        } else {
          _cartas[_primeraCarta!]['volteada'] = false;
          _cartas[_segundaCarta!]['volteada'] = false;
        }

        _primeraCarta = null;
        _segundaCarta = null;
        _bloqueado = false;
      });

      if (sonPareja) {
        await SoundService.instance.retoCompletado();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Memorama'),
        backgroundColor: AppTheme.verde,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.amarillo, size: 18),
                  const SizedBox(width: 4),
                  Text('$_paresEncontrados/${_parejasBase.length}',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
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
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.verde.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Intentos: $_intentos',
                  style: const TextStyle(fontSize: 16, fontFamily: 'Fredoka')),
              const Text('🧠 Encuentra la imagen con su palabra',
                  style: TextStyle(fontSize: 14, color: AppTheme.cafe)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _cartas.length,
            itemBuilder: (context, index) {
              return _buildCarta(index);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _iniciarJuego,
            icon: const Icon(Icons.refresh),
            label: const Text('Reiniciar'),
          ),
        ),
      ],
    );
  }

  Widget _buildCarta(int index) {
    final carta = _cartas[index];
    final volteada = carta['volteada'];
    final encontrada = carta['encontrada'];
    final esImagen = carta['tipo'] == 'imagen';

    return GestureDetector(
      onTap: () => _voltearCarta(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: encontrada
              ? AppTheme.verde.withValues(alpha: 0.3)
              : volteada
                  ? Colors.white
                  : AppTheme.verde,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: encontrada
                ? AppTheme.verde
                : volteada
                    ? AppTheme.cafe.withValues(alpha: 0.3)
                    : AppTheme.verde,
            width: encontrada ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: encontrada
              ? (esImagen
                  ? Image.asset(
                      carta['contenido'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image,
                          size: 30,
                          color: Colors.grey,
                        );
                      },
                    )
                  : Text(
                      carta['contenido'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe,
                      ),
                      textAlign: TextAlign.center,
                    ))
              : (volteada
                  ? (esImagen
                      ? Image.asset(
                          carta['contenido'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image,
                              size: 30,
                              color: Colors.grey,
                            );
                          },
                        )
                      : Text(
                          carta['contenido'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cafe,
                          ),
                          textAlign: TextAlign.center,
                        ))
                  : const Text(
                      '❓',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
        ),
      ),
    );
  }

  Widget _buildPantallaFinal() {
    final estrellas = _intentos <= 12 ? 3 : (_intentos <= 16 ? 2 : 1);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              '¡Completaste el memorama!',
              style: TextStyle(
                  fontFamily: 'Fredoka', fontSize: 28, color: AppTheme.verde),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text('⭐' * estrellas, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 20),
            _buildEstadistica('🧠 Pares encontrados',
                '$_paresEncontrados/${_parejasBase.length}'),
            _buildEstadistica('🎯 Intentos', '$_intentos'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _iniciarJuego,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('🔄 Jugar de nuevo',
                  style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadistica(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.verde.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.verde)),
          ),
        ],
      ),
    );
  }
}
