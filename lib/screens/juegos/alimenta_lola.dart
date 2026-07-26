import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/theme.dart';
import '../../services/anuncio_service.dart';
import '../../services/sound_service.dart';

class AlimentaLolaScreen extends StatefulWidget {
  const AlimentaLolaScreen({super.key});

  @override
  State<AlimentaLolaScreen> createState() => _AlimentaLolaScreenState();
}

class _AlimentaLolaScreenState extends State<AlimentaLolaScreen> {
  // ========== VARIABLES DEL JUEGO ==========

  int _puntuacion = 0;
  int _vidas = 3;
  bool _jugando = false;
  bool _juegoTerminado = false;
  Timer? _timer;
  Timer? _timerComida;
  int _tiempoRestante = 30;

  // Posición del personaje (Lola o Lalo)
  double _personajeX = 0.5;
  String _personaje = 'Lola';

  // Comida actual
  double _comidaX = 0.5;
  double _comidaY = 0.0;
  Map<String, dynamic>? _comidaActual;
  bool _comidaCorrecta = true;
  String _mensaje = '';
  bool _comidaVisible = false;

  final List<Map<String, dynamic>> _comidasBuenas = [
    {'nombre': 'Cáscara de plátano', 'emoji': '🍌', 'puntos': 10},
    {'nombre': 'Cáscara de manzana', 'emoji': '🍎', 'puntos': 10},
    {'nombre': 'Hojas secas', 'emoji': '🍂', 'puntos': 10},
    {'nombre': 'Cáscara de huevo', 'emoji': '🥚', 'puntos': 15},
    {'nombre': 'Restos de café', 'emoji': '☕', 'puntos': 10},
    {'nombre': 'Cáscara de zanahoria', 'emoji': '🥕', 'puntos': 10},
  ];

  final List<Map<String, dynamic>> _comidasMalas = [
    {'nombre': 'Bolsa de plástico', 'emoji': '🛍️', 'puntos': -5},
    {'nombre': 'Pila', 'emoji': '🔋', 'puntos': -5},
    {'nombre': 'Carne', 'emoji': '🥩', 'puntos': -5},
    {'nombre': 'Queso', 'emoji': '🧀', 'puntos': -5},
  ];

  // ========== INICIALIZACIÓN ==========

  @override
  void initState() {
    super.initState();
    _cargarPersonaje();
  }

  Future<void> _cargarPersonaje() async {
    final configBox = await Hive.openBox('configuracion');
    final genero = configBox.get('usuario_genero', defaultValue: 'Lola');
    setState(() {
      _personaje = genero;
    });
  }

  // ========== CONTROL DEL JUEGO ==========

  void _iniciarJuego() {
    setState(() {
      _puntuacion = 0;
      _vidas = 3;
      _jugando = true;
      _juegoTerminado = false;
      _tiempoRestante = 30;
      _mensaje = '¡Atrapa la comida buena y evita la mala! 🪱';
      _personajeX = 0.5;
    });
    _iniciarTimer();
    _generarComida();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _tiempoRestante--;
        if (_tiempoRestante <= 0) {
          _terminarJuego();
        }
      });
    });
  }

  void _generarComida() {
    _timerComida?.cancel();
    final random = Random();
    final esBuena = random.nextDouble() < 0.6;

    setState(() {
      _comidaX = 0.1 + random.nextDouble() * 0.8;
      _comidaY = 0.0;
      _comidaVisible = true;

      if (esBuena) {
        _comidaActual = _comidasBuenas[random.nextInt(_comidasBuenas.length)];
        _comidaCorrecta = true;
      } else {
        _comidaActual = _comidasMalas[random.nextInt(_comidasMalas.length)];
        _comidaCorrecta = false;
      }
    });

    // Animación de caída
    _timerComida = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_jugando) {
        timer.cancel();
        return;
      }

      setState(() {
        _comidaY += 0.010;

        // Verificar colisión con el personaje
        final distanciaX = (_comidaX - _personajeX).abs();
        final estaCerca = distanciaX < 0.08;
        final tocoSuelo = _comidaY >= 1.0;

        if (estaCerca && _comidaY > 0.75 && _comidaVisible) {
          // ¡Atrapó la comida! (sin pausa)
          _comidaVisible = false;
          timer.cancel();

          if (_comidaCorrecta) {
            final puntos = _comidaActual?['puntos'] ?? 10;
            setState(() {
              _puntuacion += puntos as int;
              _mensaje =
                  '¡Ñam ñam! ${_comidaActual?['emoji']} +$puntos puntos 😋';
            });

            SoundService.instance.retoCompletado(); // Reproduce sonido de éxito
          } else {
            setState(() {
              _vidas--;
              _mensaje = '¡NOOO! ${_comidaActual?['emoji']} es MALO 😢';
              if (_vidas <= 0) {
                _terminarJuego();
                return;
              }
            });
          }

          // Generar siguiente comida INMEDIATAMENTE
          if (mounted && _jugando) {
            _generarComida();
          }
        } else if (tocoSuelo && _comidaVisible) {
          // La comida llegó al suelo sin ser atrapada
          _comidaVisible = false;
          timer.cancel();

          if (_comidaCorrecta) {
            setState(() {
              _mensaje = '😢 Se perdió la comida buena';
            });
          } else {
            setState(() {
              _mensaje = '💪 ¡Bien! Esquivaste la comida mala';
            });
            SoundService.instance.retoCompletado(); // Reproduce sonido de éxito
          }

          // Generar siguiente comida INMEDIATAMENTE
          if (mounted && _jugando) {
            _generarComida();
          }
        }
      });
    });
  }

  void _moverPersonaje(double direccion) {
    if (!_jugando) return;
    setState(() {
      _personajeX += direccion;
      _personajeX = _personajeX.clamp(0.05, 0.95);
    });
  }

  void _terminarJuego() {
    _timer?.cancel();
    _timerComida?.cancel();
    setState(() {
      _jugando = false;
      _juegoTerminado = true;
      _comidaVisible = false;
    });

    if (_vidas > 0 && _puntuacion > 0) {
      SoundService.instance.monedasGanadas(); // Reproduce sonido de monedas
    }
  }

  Future<void> _salirConAnuncio() async {
    await AnuncioService.mostrarAnuncio(context);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerComida?.cancel();
    super.dispose();
  }

  // ========== CONSTRUCCIÓN DE LA UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪱 Alimenta a la lombriz'),
        backgroundColor: AppTheme.verde,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _salirConAnuncio, // ✅ Cambiar aquí
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(width: 4),
                  Text('$_vidas', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  const Icon(Icons.star, color: AppTheme.amarillo, size: 20),
                  const SizedBox(width: 4),
                  Text('$_puntuacion', style: const TextStyle(fontSize: 18)),
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
    if (!_jugando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/personajes/${_personaje.toLowerCase()}_base.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.bug_report,
                    size: 80, color: AppTheme.verde);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Alimenta a la lombriz!',
              style: TextStyle(
                  fontFamily: 'Fredoka', fontSize: 28, color: AppTheme.verde),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Desliza el dedo de izquierda a derecha para mover a tu lombriz.\nAtrapa la comida BUENA y evita la MALA.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.cafe),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _iniciarJuego,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child:
                  const Text('🎮 ¡Comenzar!', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Fondo
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF87CEEB), Color(0xFF8B5E3C)],
            ),
          ),
        ),

        // Timer y mensaje
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.cafe),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _tiempoRestante / 30,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppTheme.verde),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_tiempoRestante}s',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (_mensaje.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _mensaje.contains('NOOO')
                          ? Colors.red.withValues(alpha: 0.8)
                          : _mensaje.contains('Bien')
                              ? Colors.green.withValues(alpha: 0.8)
                              : AppTheme.verde.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _mensaje,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Comida cayendo
        if (_comidaActual != null && _comidaVisible)
          Positioned(
            left: _comidaX * MediaQuery.of(context).size.width - 30,
            top: _comidaY * MediaQuery.of(context).size.height - 30,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _comidaCorrecta ? AppTheme.verde : Colors.red,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_comidaActual!['emoji'],
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 4),
                  Text(
                    _comidaActual!['nombre'],
                    style: const TextStyle(fontSize: 11, color: AppTheme.cafe),
                  ),
                ],
              ),
            ),
          ),

        // Personaje (Lola o Lalo)
        Positioned(
          left: _personajeX * MediaQuery.of(context).size.width - 50,
          bottom: MediaQuery.of(context).size.height * 0.08,
          child: SizedBox(
            width: 100,
            height: 100,
            child: Image.asset(
              'assets/images/personajes/${_personaje.toLowerCase()}_base.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppTheme.verde,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.bug_report, size: 50, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),

        // ✅ Controles táctiles (movimiento continuo y suave)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          top: 0,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final delta =
                  details.delta.dx / MediaQuery.of(context).size.width;
              setState(() {
                _personajeX += delta * 1.5;
                _personajeX = _personajeX.clamp(0.05, 0.95);
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPantallaFinal() {
    final ganaste = _vidas > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ganaste ? '🏆' : '😢', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              ganaste ? '¡Se acabó el tiempo!' : '¡Lombriz cansada!',
              style: const TextStyle(
                  fontFamily: 'Fredoka', fontSize: 28, color: AppTheme.verde),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Puntuación final: $_puntuacion ⭐',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Vidas restantes: ${'❤️' * _vidas}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            // ✅ Botón "Jugar de nuevo" (NO muestra anuncio)
            ElevatedButton(
              onPressed: _iniciarJuego,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('🔄 Jugar de nuevo',
                  style: TextStyle(fontSize: 20)),
            ),
            // ✅ Botón "Salir" (MUESTRA anuncio)
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _salirConAnuncio, // ✅ Muestra anuncio
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.grey.shade300,
              ),
              child: const Text('🚪 Salir',
                  style: TextStyle(fontSize: 16, color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }
}
