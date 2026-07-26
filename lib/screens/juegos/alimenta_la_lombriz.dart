import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lombriaventura/screens/juegos/dificultad_config.dart';
import '../../config/theme.dart';
import '../../services/monedas_service.dart';
import '../../services/accesorios_service.dart';
import '../../services/musica_fondo_service.dart';
import '../../services/sonido_service.dart';
import '../../widgets/lombriz_con_accesorio.dart';

class AlimentaLaLombrizScreen extends StatefulWidget {
  final Dificultad dificultad;

  const AlimentaLaLombrizScreen({
    super.key,
    required this.dificultad,
  });

  @override
  State<AlimentaLaLombrizScreen> createState() => _AlimentaLaLombrizScreenState();
}

class _AlimentaLaLombrizScreenState extends State<AlimentaLaLombrizScreen> {
  late ConfigNivel _config;
  final MusicaFondoService _musica = MusicaFondoService();
  final SonidoService _sonido = SonidoService();

  // Variables del juego
  double _comida1X = 0, _comida1Y = 0;
  bool _comida1Visible = false;
  Map<String, dynamic> _comida1Data = {};

  double _comida2X = 0, _comida2Y = 0;
  bool _comida2Visible = false;
  Map<String, dynamic> _comida2Data = {};

  double _lombrizX = 0, _lombrizY = 0;
  double _puntuacion = 0;
  
  bool _cargandoPersonaje = true;
  bool _mostrandoInstrucciones = true;
  bool _juegoIniciado = false;
  bool _gameOver = false;
  bool _victoria = false;
  
  // SOLUCIÓN LIMPIA AL BUG DE MÚLTIPLES COMIDAS
  bool _generandoComida = false; 
  
  bool _botonesDialogoHabilitados = false;
  
  double _tiempoComidaRestante = 0;
  Timer? _comidaTimer;
  Timer? _tiempoVisibleTimer;

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
      _musica.iniciar('audio/musica_alimenta.mp3');
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
      _generandoComida = false;
      _comida1Visible = false;
      _comida2Visible = false;

      _lombrizX = MediaQuery.of(context).size.width / 2 - 50;
      _lombrizY = MediaQuery.of(context).size.height / 2 - 50;
    });

    _generarComidas();
  }

  void _generarComidas() {
    if (_gameOver || _victoria || !_juegoIniciado) return;

    _comidaTimer?.cancel();
    _tiempoVisibleTimer?.cancel();
    
    // Aquí reiniciamos el ciclo asegurando que ya no se está "generando" nada extra
    _generandoComida = false; 

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    _comida1Data = _comidasBuenas[DateTime.now().millisecondsSinceEpoch % _comidasBuenas.length];
    _comida1Data['tipo'] = 'buena';
    _comida2Data = _comidasMalas[DateTime.now().millisecondsSinceEpoch % _comidasMalas.length];
    _comida2Data['tipo'] = 'mala';

    setState(() {
      _comida1X = 30 + (screenWidth - 80) * (0.1 + 0.8 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000);
      _comida1Y = 50 + (screenHeight - 200) * (0.1 + 0.8 * ((DateTime.now().millisecondsSinceEpoch + 300) % 1000) / 1000);
      _comida1Visible = true;

      _comida2X = 30 + (screenWidth - 80) * (0.1 + 0.8 * ((DateTime.now().millisecondsSinceEpoch + 500) % 1000) / 1000);
      _comida2Y = 50 + (screenHeight - 200) * (0.1 + 0.8 * ((DateTime.now().millisecondsSinceEpoch + 800) % 1000) / 1000);
      _comida2Visible = true;

      _tiempoComidaRestante = _config.tiempoVisibleComida;
    });

    _tiempoVisibleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_gameOver || _victoria || !_juegoIniciado) {
        timer.cancel();
        return;
      }
      setState(() {
        _tiempoComidaRestante -= 0.1;
        if (_tiempoComidaRestante <= 0) {
          _comida1Visible = false;
          _comida2Visible = false;
          timer.cancel();
          
          if (!_generandoComida) {
            _generandoComida = true;
            Future.delayed(const Duration(milliseconds: 400), _generarComidas);
          }
        }
      });
    });
  }

  void _moverLombriz(DragUpdateDetails details) {
    if (_gameOver || _victoria || !_juegoIniciado) return;

    setState(() {
      _lombrizX = (_lombrizX + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width - 100);
      _lombrizY = (_lombrizY + details.delta.dy).clamp(0.0, MediaQuery.of(context).size.height - 150);
    });

    _verificarColision();
  }

  void _verificarColision() {
    if (_gameOver || _victoria || !_juegoIniciado) return;

    final centroLombrizX = _lombrizX + 50;
    final centroLombrizY = _lombrizY + 50;

    // Al agregar los "return", evitamos evaluar ambas si se tocan a la vez
    if (_comida1Visible) {
      if ((centroLombrizX - (_comida1X + 25)).abs() + (centroLombrizY - (_comida1Y + 25)).abs() < _radioColision) {
        _comerComida(_comida1Data);
        return; 
      }
    }

    if (_comida2Visible) {
      if ((centroLombrizX - (_comida2X + 25)).abs() + (centroLombrizY - (_comida2Y + 25)).abs() < _radioColision) {
        _comerComida(_comida2Data);
        return;
      }
    }
  }

  void _comerComida(Map<String, dynamic> comida) {
    final puntos = comida['puntos'] as int;

    setState(() {
      _puntuacion += puntos;
      _comida1Visible = false;
      _comida2Visible = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(comida['tipo'] == 'buena' ? '✅ ¡${comida['nombre']}! +$puntos pts' : '❌ ¡${comida['nombre']} no es buena! $puntos pts'),
      backgroundColor: comida['tipo'] == 'buena' ? AppTheme.verde : Colors.red,
      duration: const Duration(milliseconds: 400),
    ));

    if (_puntuacion >= _config.puntosParaGanar || _puntuacion < -20) {
      _finalizarJuego(_puntuacion >= _config.puntosParaGanar);
      return;
    } 

    // Aquí evitamos que se dupliquen los ciclos de generación
    if (!_generandoComida) {
      _generandoComida = true;
      _comidaTimer?.cancel();
      _tiempoVisibleTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 300), _generarComidas);
    }
  }

  void _finalizarJuego(bool esVictoria) {
    _juegoIniciado = false;
    _botonesDialogoHabilitados = false;
    _comidaTimer?.cancel();
    _tiempoVisibleTimer?.cancel();
    
    setState(() {
      if (esVictoria) {
        _victoria = true;
        _gameOver = true;
        _sonido.victoria(); // SONIDO DE VICTORIA
      } else {
        _gameOver = true;
        // _sonido.derrota(); 
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _botonesDialogoHabilitados = true);
    });

    _mostrarDialogoFinJuego(esVictoria);
  }

  void _mostrarDialogoFinJuego(bool esVictoria) {
    final monedas = esVictoria ? _config.monedasGanadas : 0;
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
            title: Text(esVictoria ? '🎉 ¡Ganaste!' : '💔 Fin del juego', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(esVictoria ? '¡Alcanzaste la meta!' : 'Puntuación demasiado baja.', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('Puntos: ${_puntuacion.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  _iniciarJuego(); // LA MÚSICA SIGUE
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
    if (!_juegoIniciado || _gameOver || _victoria) {
      _musica.detener(); // Detenemos la música si sale antes de jugar
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ ¿Salir del juego?'),
        content: const Text('Si sales, perderás tu progreso actual. ¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (result == true) {
      _musica.detener(); // Detenemos la música si confirma la salida
    }
    return result ?? false;
  }

  @override
  void dispose() {
    _comidaTimer?.cancel();
    _tiempoVisibleTimer?.cancel();
    super.dispose();
  }

  // WIDGET AUXILIAR PARA LA COMIDA
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
                      const Text('1. Arrastra a la lombriz para comer los alimentos buenos.\n2. ¡Evita comer aparatos electrónicos!\n3. Gana puntos antes de que desaparezcan.', textAlign: TextAlign.center),
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
                  left: _lombrizX, top: _lombrizY,
                  child: GestureDetector(
                    onPanUpdate: _moverLombriz,
                    child: LombrizConAccesorio(size: 100, accesorioId: _accesorioEquipado),
                  ),
                ),
                if (_comida1Visible) Positioned(
                  left: _comida1X, top: _comida1Y,
                  child: _construirComida(_comida1Data['emoji']),
                ),
                if (_comida2Visible) Positioned(
                  left: _comida2X, top: _comida2Y,
                  child: _construirComida(_comida2Data['emoji']),
                ),
                Positioned(
                  top: 20, left: 20, right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Text('Puntos: ${_puntuacion.toInt()} / ${_config.puntosParaGanar}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        width: 100, height: 10,
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (_tiempoComidaRestante / _config.tiempoVisibleComida).clamp(0.0, 1.0),
                          child: Container(decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(5))),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
        ),
      ),
    );
  }
}