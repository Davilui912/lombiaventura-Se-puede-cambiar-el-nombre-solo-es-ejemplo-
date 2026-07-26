import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/theme.dart';
import '../../services/monedas_service.dart';
import '../../services/accesorios_service.dart';
import '../../services/musica_fondo_service.dart';
import '../../services/sonido_service.dart';
import '../../widgets/lombriz_con_accesorio.dart';
import 'dificultad_config.dart';

class ComidaCayendo {
  double x;
  double y;
  Map<String, dynamic> data;
  bool activa;

  ComidaCayendo({required this.x, required this.y, required this.data, this.activa = true});
}

class AlimentaLombrizCayendoScreen extends StatefulWidget {
  final Dificultad dificultad;

  const AlimentaLombrizCayendoScreen({
    super.key,
    required this.dificultad,
  });

  @override
  State<AlimentaLombrizCayendoScreen> createState() => _AlimentaLombrizCayendoScreenState();
}

class _AlimentaLombrizCayendoScreenState extends State<AlimentaLombrizCayendoScreen> {
  late ConfigNivel _config;
  final MusicaFondoService _musica = MusicaFondoService();
  final SonidoService _sonido = SonidoService();

  double _lombrizX = 0;
  double _puntuacion = 0;
  
  bool _cargandoPersonaje = true;
  bool _mostrandoInstrucciones = true;
  bool _juegoIniciado = false;
  bool _gameOver = false;
  bool _victoria = false;
  bool _botonesDialogoHabilitados = false;

  List<ComidaCayendo> _comidasEnPantalla = [];
  Timer? _gravedadTimer;
  Timer? _spawnTimer;
  final double _radioColision = 55.0;
  
  String _personaje = 'Lombriz';
  String? _accesorioEquipado;
  
  final List<Map<String, dynamic>> _comidasBuenas = [
    {'emoji': '🍎', 'nombre': 'Manzana', 'puntos': 5},
    {'emoji': '🍌', 'nombre': 'Plátano', 'puntos': 5},
    {'emoji': '🥕', 'nombre': 'Zanahoria', 'puntos': 5},
    {'emoji': '🍉', 'nombre': 'Sandía', 'puntos': 5},
    {'emoji': '🍇', 'nombre': 'Uvas', 'puntos': 5},
    {'emoji': '🍓', 'nombre': 'Fresa', 'puntos': 5},
    {'emoji': '🥭', 'nombre': 'Mango', 'puntos': 5},
    {'emoji': '🍍', 'nombre': 'Piña', 'puntos': 5},
    {'emoji': '🥝', 'nombre': 'Kiwi', 'puntos': 5},
    {'emoji': '🍑', 'nombre': 'Durazno', 'puntos': 5},
  ];
  
  final List<Map<String, dynamic>> _comidasMalas = [
      {'emoji': '💻', 'nombre': 'Computadora', 'puntos': -5},
      {'emoji': '📱', 'nombre': 'Teléfono', 'puntos': -5},
      {'emoji': '🎮', 'nombre': 'Videojuego', 'puntos': -5}, 
      {'emoji': '📺', 'nombre': 'Televisión', 'puntos': -5},
    ];

  @override
  void initState() {
    super.initState();
    _config = obtenerConfiguracion(widget.dificultad);
    _cargarPersonajeYAccesorio();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _musica.iniciar('audio/musica_cayendo.mp3');
    });
  }

  Future<void> _cargarPersonajeYAccesorio() async {
    try {
      final configBox = await Hive.openBox('configuracion');
      _personaje = configBox.get('personaje', defaultValue: 'Lombriz');
      final accesoriosService = AccesoriosService();
      await accesoriosService.init();
      final equipados = accesoriosService.obtenerEquipados(_personaje);
      
      setState(() {
        _accesorioEquipado = equipados['gorra'] ?? equipados['lentes'] ?? equipados['collar'] ?? equipados['sombrero'];
        _cargandoPersonaje = false;
      });
    } catch (e) {
      setState(() => _cargandoPersonaje = false);
    }
  }

  void _iniciarJuego() {
    setState(() {
      _mostrandoInstrucciones = false;
      _puntuacion = 0;
      _gameOver = false;
      _victoria = false;
      _juegoIniciado = true;
      _comidasEnPantalla.clear();
      _lombrizX = (MediaQuery.of(context).size.width / 2) - 50;
    });

    _gravedadTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_juegoIniciado || _gameOver) return;
      setState(() {
        final height = MediaQuery.of(context).size.height;
        for (var comida in _comidasEnPantalla) {
          if (comida.activa) {
            comida.y += _config.velocidadComida; 
            if (comida.y > height) comida.activa = false;
          }
        }
        _comidasEnPantalla.removeWhere((c) => !c.activa);
        _verificarColision();
      });
    });

    double spawnRate = widget.dificultad == Dificultad.dificil ? 800 : 1200; 
    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnRate.toInt()), (timer) {
      if (!_juegoIniciado || _gameOver) return;
      _generarComidaIndividual();
    });
  }

  void _generarComidaIndividual() {
    final screenWidth = MediaQuery.of(context).size.width;
    double startX = 20 + Random().nextDouble() * (screenWidth - 80);
    
    bool esBuena = Random().nextDouble() > 0.4; // 60% de probabilidad de buena, 40% de mala
    Map<String, dynamic> data = esBuena 
        ? _comidasBuenas[Random().nextInt(_comidasBuenas.length)] 
        : _comidasMalas[Random().nextInt(_comidasMalas.length)];
    
    data['tipo'] = esBuena ? 'buena' : 'mala';

    _comidasEnPantalla.add(ComidaCayendo(x: startX, y: -50, data: data));
  }

  void _moverLombriz(DragUpdateDetails details) {
    if (_gameOver || !_juegoIniciado) return;
    setState(() {
      _lombrizX = (_lombrizX + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 100);
    });
  }

  void _verificarColision() {
    final screenHeight = MediaQuery.of(context).size.height;
    final double lombrizY = screenHeight * 0.70;
    final centroLombrizX = _lombrizX + 50;
    final centroLombrizY = lombrizY + 50;

    for (var comida in _comidasEnPantalla) {
      if (!comida.activa) continue;

      final centroComidaX = comida.x + 25;
      final centroComidaY = comida.y + 25;
      final distancia = (centroLombrizX - centroComidaX).abs() + (centroLombrizY - centroComidaY).abs();

      if (distancia < _radioColision) {
        comida.activa = false;
        final puntos = comida.data['puntos'] as int;
        _puntuacion += puntos;

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(puntos > 0 ? '✅ ¡${comida.data['nombre']}! +$puntos' : '❌ ¡Cuidado! $puntos'),
          backgroundColor: puntos > 0 ? AppTheme.verde : Colors.red,
          duration: const Duration(milliseconds: 300),
        ));

        if (_puntuacion >= _config.puntosParaGanar || _puntuacion < -20) {
          _finalizarJuego(_puntuacion >= _config.puntosParaGanar);
          return; 
        }
      }
    }
  }

  void _finalizarJuego(bool esVictoria) {
    _juegoIniciado = false;
    _botonesDialogoHabilitados = false;
    _gravedadTimer?.cancel();
    _spawnTimer?.cancel();

    setState(() {
      if (esVictoria) {
        _victoria = true;
        _gameOver = true;
        _sonido.victoria(); 
      } else {
        _gameOver = true;
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _botonesDialogoHabilitados = true);
    });

    _mostrarDialogoFin();
  }

  void _mostrarDialogoFin() {
    final monedas = _victoria ? _config.monedasGanadas : 0;
    if (monedas > 0) MonedasService().agregarMonedas(monedas);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Timer.periodic(const Duration(milliseconds: 500), (timer) {
            if (_botonesDialogoHabilitados && mounted) {
              setStateDialog(() {});
              timer.cancel();
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(_victoria ? '🎉 ¡Ganaste!' : '💔 Fin del juego', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Puntos: ${_puntuacion.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (monedas > 0) ...[
                  const SizedBox(height: 10),
                  Text('💰 +$monedas monedas', style: const TextStyle(fontSize: 20, color: Colors.amber, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: _botonesDialogoHabilitados ? () {
                  _musica.detener(); // Detenemos música al salir
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                } : null,
                child: const Text('Volver'),
              ),
              ElevatedButton(
                onPressed: _botonesDialogoHabilitados ? () {
                  Navigator.pop(ctx);
                  _iniciarJuego(); 
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.verdeClaro),
                child: const Text('🔄 Reintentar'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_juegoIniciado || _gameOver) {
      _musica.detener();
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ ¿Salir del juego?'),
        content: const Text('Perderás tu progreso. ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Salir')),
        ],
      ),
    );
    
    if (result == true) {
      _musica.detener(); // Detenemos música si confirma salida
    }
    return result ?? false;
  }

  @override
  void dispose() {
    _gravedadTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  // WIDGET AUXILIAR PARA LA COMIDA CAYENDO
  Widget _construirComida(String emoji) {
    // PARA QUITAR EL FONDO BLANCO: 
    // Quita el 'Container' y su 'BoxDecoration', y deja únicamente el widget 'Text'.
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 30)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoPersonaje) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.verde,
          leading: BackButton(onPressed: () async {
            if (await _onWillPop()) Navigator.pop(context);
          }),
          title: Text('${_config.emoji} ${_config.nombre}', style: const TextStyle(fontSize: 16)),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/images/fondo.png'), fit: BoxFit.cover),
          ),
          child: _mostrandoInstrucciones
          ? Center(
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📖 Instrucciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      const Text('1. Arrastra a la lombriz para atrapar la comida.\n2. ¡Cuidado con los aparatos electrónicos que caen!\n3. Alcanza los puntos para ganar.', textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.verde, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                        onPressed: _iniciarJuego,
                        child: const Text('▶️ JUGAR', style: TextStyle(fontSize: 18, color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                if (_juegoIniciado) Positioned(
                  left: _lombrizX, top: MediaQuery.of(context).size.height * 0.70,
                  child: GestureDetector(
                    onPanUpdate: _moverLombriz,
                    child: LombrizConAccesorio(size: 100, accesorioId: _accesorioEquipado),
                  ),
                ),
                ..._comidasEnPantalla.where((c) => c.activa).map((comida) => Positioned(
                  left: comida.x, top: comida.y,
                  child: _construirComida(comida.data['emoji']), // Usamos el widget con el fondo blanco
                )),
                Positioned(
                  top: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), 
                    child: Text('Puntos: ${_puntuacion.toInt()} / ${_config.puntosParaGanar}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
        ),
      ),
    );
  }
}