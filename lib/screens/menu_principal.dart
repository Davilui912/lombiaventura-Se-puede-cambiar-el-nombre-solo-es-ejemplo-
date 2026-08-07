import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lombriaventura/screens/juegos/alimenta_lombriz_cayendo.dart';
import 'package:lombriaventura/screens/juegos/selector_nivel_alimenta.dart';
import 'package:lombriaventura/screens/login_screen.dart';
import '../config/theme.dart';
import '../services/actividad_service.dart';
import 'chat_ia_screen.dart';
import 'diario/nueva_entrada.dart';
import 'juegos/selector_nivel_cayendo.dart';
import 'juegos/clasifica_residuos.dart';
import 'juegos/alimenta_la_lombriz.dart';
import 'tienda/ventas_lombrices.dart';
import 'tienda/ventas_atomizador.dart';
import 'tienda/ventas_historial.dart';
import 'tienda/ventas_humus.dart';
import 'tienda/capacitacion.dart';
import '../../services/monedas_service.dart';
import 'juegos/memorama.dart';
import 'logros.dart';
import 'modulo_educativo.dart';
import '../services/retos_service.dart';
import 'recordatorios.dart';
import 'tienda/accesorios_screen.dart';
import 'avisos.dart';
import 'tienda/problemas_matematicos.dart';
import 'perfil_screen.dart';
import 'admin_screen.dart';
import 'retos_screen.dart';
import '../services/recordatorios_service.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  final ActividadService _actividadService = ActividadService();

  int _categoriaAbierta = -1;
  int _contadorToques = 0;
  bool _mostrarBanner = true;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
    _actividadService.registrarActividad();

    //  Esperar 3 segundos antes de verificar recordatorios
    Future.delayed(const Duration(seconds: 3), () {
      _verificarRecordatorios();
    });

    _inicializarRecordatorios();
  }

  Future<void> _inicializarRecordatorios() async {
    //  Verificar si el Reto 1 está completado antes de activar recordatorios
    final retosService = RetosService();
    await retosService.init();

    if (retosService.estaCompletadoReto1()) {
      final recordatorioService = RecordatoriosService();
      await recordatorioService.init();
      recordatorioService.programarRecordatorioDiario();
      recordatorioService.programarRecordatorioLixiviado();
    }
  }

  void _verificarRecordatorios() async {
    //  Verificar si el Reto 1 está completado antes de mostrar recordatorios
    final retosService = RetosService();
    await retosService.init();

    if (!retosService.estaCompletadoReto1()) return;

    final service = RecordatoriosService();
    await service.init();
    if (service.hayPendientes()) {
      final pendientes = service.obtenerPendientes();
      if (pendientes.isNotEmpty && mounted) {
        _mostrarAlertaRecordatorio(pendientes.first);
      }
    }
  }

  void _mostrarAlertaRecordatorio(Map<String, dynamic> rec) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(rec['icono'], style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(rec['titulo'], style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(rec['mensaje'], style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () {
              RecordatoriosService().marcarVisto(rec['id']);
              Navigator.pop(ctx);
            },
            child: const Text('✅ ¡Hecho!'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordatoriosScreen()),
              );
            },
            child: const Text('Ver todos 📋'),
          ),
        ],
      ),
    );
  }

  void _irAPantalla(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  Future<void> _verificarSesion() async {
    final configBox = await Hive.openBox('configuracion');
    final loginExitoso = configBox.get('login_exitoso', defaultValue: false);

    if (!loginExitoso) {
      // Si no hay sesión, redirigir al login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
    }
  }

  void _abrirPanelAdmin() {
    _contadorToques++;
    if (_contadorToques >= 5) {
      _contadorToques = 0;
      _irAPantalla(const AdminScreen());
    }
    Future.delayed(const Duration(seconds: 3), () {
      _contadorToques = 0;
    });
  }

  Future<int> _obtenerMonedas() async {
    try {
      // ✅ Usar MonedasService en lugar de acceder directamente al box
      final monedas = MonedasService().obtenerMonedas();
      print('🪙 Monedas en menú: $monedas');
      return monedas;
    } catch (e) {
      print('Error al obtener monedas: $e');
      return 0;
    }
  }

  Widget _buildTituloAdmin() {
    return GestureDetector(
      onTap: _abrirPanelAdmin,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_lombriaventura.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.bug_report,
                    size: 30,
                    color: AppTheme.verde,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '¡Hola, Lombrikid!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionJuego(
      String titulo,
      String subtitulo,
      IconData? icon, // 1. Le agregamos el '?' para que pueda ser nulo
      VoidCallback onTap,
      Color color,
      {Widget? customIcon} // 2. Agregamos el widget personalizado como opción
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              // 3. Agregamos un Center y le decimos: "¿Hay customIcon? Úsalo. Si no, usa el icono normal"
              child: Center(
                child: customIcon ?? Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.negro,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmenuJuegos() {
    final Color colorJuegos = const Color(0xFF6DB467);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        // Fondo blanco
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // Borde verde claro más definido
        border:
            Border.all(color: colorJuegos.withValues(alpha: 0.4), width: 1.5),
        // Sombra suave para darle profundidad
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorJuegos.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            // ⬅️ Cambiamos el icono de Flutter por un emoji centrado
            child: const Center(
              child: Text('🎮', style: TextStyle(fontSize: 20)),
            ),
          ),
          title: const Text(
            'Juegos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          trailing: Icon(Icons.keyboard_arrow_down, color: colorJuegos),
          children: [
            // ⬅️ Usamos _buildOpcion en lugar de _buildOpcionJuego
            _buildOpcion(
              'Clasifica residuos',
              'Aprende a separar los residuos',
              '♻️', // Emoji para reciclar
              () => _irAPantalla(const ClasificaResiduosScreen()),
              color: colorJuegos,
            ),
            _buildOpcion(
              'Bocados Sorpresa',
              'Arrastra a la lombriz para comer los alimentos buenos',
              '🍎', // Emoji de manzanita
              () => _irAPantalla(const SelectorNivelAlimentaScreen()),
              color: colorJuegos,
            ),
            _buildOpcion(
              'Lluvia Deliciosa',
              'Atrapa la comida que cae y evita los aparatos electrónicos',
              '🧺', // Emoji de canasta
              () => _irAPantalla(const SelectorNivelCayendoScreen()),
              color: colorJuegos,
            ),
            _buildOpcion(
              'Memorama ecológico',
              'Encuentra las parejas',
              '🃏', // Emoji de cartas
              () => _irAPantalla(const MemoramaScreen()),
              color: colorJuegos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmenu({
    required String titulo,
    required IconData icon,
    required Color color,
    required List<Widget> opciones,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: opciones,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoria({
    required String titulo,
    required String subtitulo,
    required Color color,
    required Color color2,
    required int index,
    required List<Widget> opciones,
    IconData? icon,
    String? iconImage,
  }) {
    final abierta = _categoriaAbierta == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _categoriaAbierta = abierta ? -1 : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [color, color2],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: iconImage != null
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              iconImage,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  icon ?? Icons.help_outline,
                                  color: Colors.white,
                                  size: 34,
                                );
                              },
                            ),
                          )
                        : Icon(
                            icon ?? Icons.help_outline,
                            color: Colors.white,
                            size: 34,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: abierta ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            if (abierta)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: opciones,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcion(
      String titulo,
      String subtitulo,
      String emoji, // ⬅️ ¡Ahora pide directamente el emoji!
      VoidCallback onTap,
      {Color color = Colors.grey} // Color opcional para los bordes y flecha
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                // ⬅️ Aquí mostramos el emoji directamente
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.cafe),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildTituloAdmin(),
        actions: [
          // Mostrar monedas en el AppBar
          FutureBuilder<int>(
            future: _obtenerMonedas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const SizedBox(
                    width: 30,
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data! > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    //Sombra solida hacia abajo = profundidad 3D
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8860B),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      //Fondo amarillo dorado
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(20),
                      //Borde inferior que refuerza la profundidad
                      border: Border.all(
                        color: const Color(0xFFB8860B), // dorado oscuro
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Color(0xFFB8860B), //icono dorado oscuro
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Color(0xFF7B5100), // texto cafe dorado
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_3, color: Colors.white),
            onPressed: () => _irAPantalla(const PerfilScreen()),
            tooltip: 'Mi perfil',
          ),
        ],
        backgroundColor: AppTheme.verde,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80, // ✅ Espacio para el botón flotante
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ==================== APRENDIZAJE ====================
// ==================== APRENDIZAJE ====================
                    _buildCategoria(
                      titulo: 'Aprendizaje',
                      subtitulo: 'Descubre y aprende',
                      color: const Color(0xFF43A047),
                      color2: const Color(0xFF66BB6A),
                      iconImage: 'assets/images/icons/icono_aprendizaje.png',
                      index: 0,
                      opciones: [
                        _buildOpcion(
                          'Conoce a las lombrices',
                          'Aprende sobre la lombriz roja californiana',
                          '🐛', // ⬅️ Emoji directo
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '🪱 Conoce a las lombrices',
                            descripcion:
                                'Las lombrices son pequeñas pero poderosas aliadas del planeta.',
                            informacion:
                                '🐛 ¡Hola! Soy la lombriz sabia, una lombriz roja californiana. '
                                'Somos las mejores para hacer composta porque comemos muy rápido.\n\n'
                                '🌱 ¿CÓMO NACEMOS?\n'
                                'Nos juntamos en pareja y compartimos una parte de nuestro cuerpo. '
                                'Ponemos huevitos dentro de capullos ¡Cada 10 días! De cada capullo '
                                'pueden nacer entre 2 y 5 lombrices bebés. Las bebés tardan 2 o 3 '
                                'meses en ser adultas (lo sabrás cuando veas un anillo en nuestro cuerpo).\n\n'
                                '🍎 ¿QUÉ COMEMOS? (¡ATENCIÓN!)\n'
                                'NO comemos residuos frescos. Tienen que esperar unos días a que '
                                'se fermenten. Nos encanta: cáscaras de frutas/verduras EN TROZOS '
                                'PEQUEÑOS, restos de café, hojas secas, cartón mojado, '
                                'cáscara de huevo triturada.\n\n'
                                '🚫 ¡NUNCA NOS DES! Carnes, huesos, lácteos, cítricos en exceso, '
                                'sal, aceites, plásticos. Eso nos enferma o nos puede matar.\n\n'
                                '🏠 NUESTRO HOGAR PERFECTO\n'
                                '• Temperatura: 15°C - 25°C (sin frío ni calor extremos)\n'
                                '• Humedad: como una esponja escurrida (prueba del puño)\n'
                                '• Un recipiente con drenaje para que salga el lixiviado\n'
                                '• Malla para que no entren moscas\n\n'
                                '💧 ¿QUÉ ES EL LIXIVIADO?\n'
                                'Es el líquido que sale de la composta. ¡Es súper nutritivo! '
                                'Se mezcla con 10 partes de agua y se echa a las plantas. '
                                'Cuidado: el lixiviado de la basura común SÍ es tóxico, por eso '
                                'separamos los residuos.\n\n'
                                '🌟 ¿SABÍAS QUÉ?\n'
                                '• No tenemos dientes, por eso corta nuestra comida chiquita\n'
                                '• Podemos comer la mitad de nuestro peso cada día\n'
                                '• Ayudamos a reducir la basura que contamina el agua y el suelo',
                            puntosClave: [
                              {
                                'emoji': '🪱',
                                'titulo': 'Lombriz californiana',
                                'descripcion':
                                    'La especie ideal para compostaje, come su peso en un día'
                              },
                              {
                                'emoji': '🌍',
                                'titulo': 'Viven en la tierra',
                                'descripcion':
                                    'Necesitan humedad y oscuridad para sobrevivir'
                              },
                              {
                                'emoji': '🍎',
                                'titulo': 'Qué comen',
                                'descripcion':
                                    'Restos de frutas, verduras, cáscaras de huevo y café'
                              },
                              {
                                'emoji': '✨',
                                'titulo': 'Beneficios',
                                'descripcion':
                                    'Producen humus, el mejor fertilizante natural'
                              },
                            ],
                          )),
                          color: const Color(0xFF43A047),
                        ),
                        _buildOpcion(
                          '¿Qué es la lombricomposta?',
                          'Beneficios y proceso',
                          '♻️',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '♻️ ¿Qué es la lombricomposta?',
                            descripcion:
                                'La lombricomposta es un abono natural creado por lombrices que transforman residuos orgánicos en el mejor fertilizante para las plantas.',
                            informacion:
                                'La lombricomposta, también llamada vermicomposta, es el resultado de la descomposición de residuos orgánicos por lombrices californianas. '
                                'Estas lombrices comen los restos de comida y los convierten en humus, un abono rico en nutrientes.\n\n'
                                'Es 100% natural, no contamina y ayuda a reducir la basura que va a los tiraderos.',
                            puntosClave: [
                              {
                                'emoji': '🪱',
                                'titulo': 'Hecho por lombrices',
                                'descripcion':
                                    'Las lombrices californianas son las protagonistas'
                              },
                              {
                                'emoji': '🌱',
                                'titulo': 'Abono natural',
                                'descripcion':
                                    'Aporta nitrógeno, fósforo y potasio a las plantas'
                              },
                              {
                                'emoji': '♻️',
                                'titulo': 'Cero contaminación',
                                'descripcion':
                                    'Reduce hasta 50% de basura orgánica en casa'
                              },
                              {
                                'emoji': '💧',
                                'titulo': 'Produce lixiviado',
                                'descripcion':
                                    'Un líquido nutritivo para regar plantas'
                              },
                            ],
                          )),
                        ),
                        _buildOpcion(
                          'Aprende a hacerla',
                          'Paso a paso en casa',
                          '🛠️',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '🛠️ Aprende a hacerla',
                            descripcion:
                                'Crear tu propia lombricomposta es muy fácil. Solo necesitas seguir estos pasos y tener paciencia.',
                            informacion:
                                'Puedes hacer lombricomposta de dos formas:\n\n'
                                'Opción 1: Con estiércol de animales herbívoros (conejo, vaca, caballo).\n'
                                'Opción 2: Con residuos de cocina (cáscaras, restos de frutas y verduras).\n\n'
                                'En ambos casos necesitas un contenedor con agujeros para ventilación, tierra, fibra de coco y lombrices californianas.',
                            puntosClave: [
                              {
                                'emoji': '📦',
                                'titulo': '1. Prepara el contenedor',
                                'descripcion':
                                    'Haz agujeros para que respiren las lombrices'
                              },
                              {
                                'emoji': '🥥',
                                'titulo': '2. Agrega sustrato',
                                'descripcion':
                                    'Fibra de coco y tierra húmeda como cama'
                              },
                              {
                                'emoji': '🪱',
                                'titulo': '3. Coloca las lombrices',
                                'descripcion':
                                    'Ponlas sobre la cama y deja que se adapten'
                              },
                              {
                                'emoji': '🍎',
                                'titulo': '4. Añade residuos',
                                'descripcion':
                                    'Cáscaras de frutas, verduras y restos de café'
                              },
                              {
                                'emoji': '💧',
                                'titulo': '5. Mantén la humedad',
                                'descripcion':
                                    'Rocía agua para que esté húmedo, no empapado'
                              },
                              {
                                'emoji': '⏳',
                                'titulo': '6. Espera 2-3 meses',
                                'descripcion':
                                    'Cosecha el humus cuando esté oscuro y suave'
                              },
                            ],
                          )),
                        ),
                        _buildOpcion(
                          'Materiales necesarios',
                          'Lo que ocupas para empezar',
                          '📋',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '📋 Materiales necesarios',
                            descripcion:
                                'No necesitas muchas cosas para empezar tu lombricomposta. ¡Seguro ya tienes varias en casa!',
                            informacion:
                                'Los materiales básicos son económicos y fáciles de conseguir. '
                                'Lo más importante son las lombrices californianas, que son diferentes a las lombrices de jardín.',
                            puntosClave: [
                              {
                                'emoji': '📦',
                                'titulo': 'Contenedor',
                                'descripcion':
                                    'De plástico o madera, con agujeros para ventilación'
                              },
                              {
                                'emoji': '🪱',
                                'titulo': 'Lombrices californianas',
                                'descripcion':
                                    'Las mejores para composta, comen su peso en un día'
                              },
                              {
                                'emoji': '🥥',
                                'titulo': 'Fibra de coco',
                                'descripcion':
                                    'Sirve como cama y retiene humedad'
                              },
                              {
                                'emoji': '🪨',
                                'titulo': 'Tierra',
                                'descripcion':
                                    'Tierra de jardín o composta como base'
                              },
                              {
                                'emoji': '🍂',
                                'titulo': 'Material seco',
                                'descripcion':
                                    'Hojas secas, cartón sin tinta, aserrín (carbono)'
                              },
                              {
                                'emoji': '🍎',
                                'titulo': 'Residuos orgánicos',
                                'descripcion':
                                    'Cáscaras, restos de frutas y verduras (nitrógeno)'
                              },
                            ],
                          )),
                        ),
                        _buildOpcion(
                          'Balance 80/20',
                          'Nitrógeno y carbono',
                          '⚖️',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '⚖️ Balance 80/20',
                            descripcion:
                                'Para una composta saludable necesitas equilibrar materiales verdes (nitrógeno) y materiales secos (carbono).',
                            informacion:
                                'La regla es 80% material seco (carbono) y 20% material verde (nitrógeno).\n\n'
                                'Demasiado nitrógeno = mal olor y moscas.\n'
                                'Demasiado carbono = proceso muy lento.\n\n'
                                'El equilibrio perfecto hace felices a las lombrices y produce el mejor humus.',
                            puntosClave: [
                              {
                                'emoji': '🍂',
                                'titulo': '80% CARBONO (seco)',
                                'descripcion':
                                    'Hojas secas, cartón, aserrín, papel sin tinta'
                              },
                              {
                                'emoji': '🍎',
                                'titulo': '20% NITRÓGENO (verde)',
                                'descripcion':
                                    'Cáscaras, restos de frutas, verduras, café'
                              },
                              {
                                'emoji': '👃',
                                'titulo': '¿Huele mal?',
                                'descripcion':
                                    'Agrega más material seco (carbono)'
                              },
                              {
                                'emoji': '🐌',
                                'titulo': '¿Muy lento?',
                                'descripcion':
                                    'Agrega más material verde (nitrógeno)'
                              },
                            ],
                          )),
                        ),
                        _buildOpcion(
                          'Lixiviado',
                          'El oro líquido de la composta',
                          '💧',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '💧 Lixiviado',
                            descripcion:
                                'El lixiviado es un líquido oscuro que se produce durante la lombricomposta. ¡Es oro líquido para tus plantas!',
                            informacion:
                                'El lixiviado es el exceso de agua que escurre de la composta cargado de nutrientes.\n\n'
                                'Se recolecta en la parte baja del contenedor y se diluye en agua para regar plantas.\n\n'
                                'Proporción: 1 parte de lixiviado por 10 partes de agua.',
                            puntosClave: [
                              {
                                'emoji': '💧',
                                'titulo': '¿Qué es?',
                                'descripcion':
                                    'Líquido rico en nutrientes que escurre de la composta'
                              },
                              {
                                'emoji': '🪣',
                                'titulo': 'Recolecta',
                                'descripcion':
                                    'Usa un contenedor con llave en la parte inferior'
                              },
                              {
                                'emoji': '🧪',
                                'titulo': 'Diluye',
                                'descripcion':
                                    '1 taza de lixiviado por 10 tazas de agua'
                              },
                              {
                                'emoji': '🌻',
                                'titulo': 'Usa en plantas',
                                'descripcion':
                                    'Riega tus macetas y jardín con esta mezcla'
                              },
                            ],
                          )),
                        ),
                        _buildOpcion(
                          'Cuidados',
                          'Mantén felices a tus lombrices',
                          '💚',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '💚 Cuidados',
                            descripcion:
                                'Las lombrices son seres vivos que necesitan cuidados básicos. ¡No te preocupes, es muy sencillo!',
                            informacion: 'Los 3 cuidados esenciales:\n\n'
                                '1. HUMEDAD: La composta debe estar húmeda como una esponja exprimida.\n'
                                '2. TEMPERATURA: Entre 15°C y 25°C, protegidas del sol directo.\n'
                                '3. ALIMENTACIÓN: Una vez por semana, en pequeñas cantidades.',
                            puntosClave: [
                              {
                                'emoji': '💧',
                                'titulo': 'Humedad ideal',
                                'descripcion':
                                    'Como esponja exprimida. Rocía agua si está seco'
                              },
                              {
                                'emoji': '🌡️',
                                'titulo': 'Temperatura',
                                'descripcion':
                                    '15-25°C. No exponer al sol directo ni frío extremo'
                              },
                              {
                                'emoji': '🍎',
                                'titulo': 'Alimentación',
                                'descripcion':
                                    '1 vez por semana. Pica los residuos en trozos pequeños'
                              },
                              {
                                'emoji': '🚫',
                                'titulo': 'NO dar',
                                'descripcion':
                                    'Carne, lácteos, cítricos en exceso, cebolla, ajo, plástico'
                              },
                            ],
                          )),
                        ),
                        _buildOpcion(
                          'Emprendimiento',
                          'Gana dinero ayudando al planeta',
                          '💰',
                          () => _irAPantalla(ModuloEducativoScreen(
                            titulo: '💰 Emprendimiento',
                            descripcion:
                                '¿Sabías que puedes ganar dinero con tu lombricomposta? ¡Aprende a vender y ayudar al planeta!',
                            informacion: 'Puedes vender:\n\n'
                                '• Composta (humus): \$50-100 MXN por kilo\n'
                                '• Lixiviado: \$30-50 MXN por litro\n'
                                '• Lombrices: \$100-200 MXN por 100 lombrices\n\n'
                                'Ideal para vender en tu escuela, colonia o redes sociales.',
                            puntosClave: [
                              {
                                'emoji': '🛍️',
                                'titulo': 'Vende composta',
                                'descripcion':
                                    'Empaca en bolsas de 1kg y vende a vecinos y jardineros'
                              },
                              {
                                'emoji': '🧴',
                                'titulo': 'Vende lixiviado',
                                'descripcion':
                                    'Embasa en botellas recicladas como fertilizante líquido'
                              },
                              {
                                'emoji': '🪱',
                                'titulo': 'Vende lombrices',
                                'descripcion':
                                    'Cuando tengas muchas, separa y vende paquetes'
                              },
                              {
                                'emoji': '📱',
                                'titulo': 'Promoción',
                                'descripcion':
                                    'Toma fotos bonitas y comparte en WhatsApp o Facebook'
                              },
                            ],
                          )),
                        ),
                      ],
                    ),
                    // ==================== MIS JUEGOS ====================
                    _buildCategoria(
                      titulo: 'Mis juegos',
                      subtitulo: 'Cuida tu composta',
                      color: const Color(0xFFFFA726),
                      color2: const Color(0xFFFFCA28),
                      iconImage: 'assets/images/icons/icono_composta.png',
                      index: 1,
                      opciones: [
                       /*_buildOpcion(
                            'Avisos importantes',
                            'Cuida a tus lombrices',
                            '⚠️',
                            () => _irAPantalla(const AvisosScreen()),
                            color: const Color(0xFFFFA726)),*/
                        /*_buildOpcion(
                            '¿Cómo va mi composta?', 
                            'Compara y revisa tu composta', 
                            '🔄', 
                            () => _irAPantalla(const ComparaCompostaScreen()),
                            color: const Color(0xFFFFA726)),*/

                        // ✅ Submenú de juegos (mejorado)
                        _buildSubmenuJuegos(),
                      ],
                    ),
                    // ==================== PROGRESO ====================
                    _buildCategoria(
                      titulo: 'Progreso',
                      subtitulo: 'Revisa tus logros',
                      color: const Color(0xFF42A5F5),
                      color2: const Color(0xFF64B5F6),
                      iconImage: 'assets/images/icons/icono_progreso.png',
                      index: 2,
                      opciones: [
                        _buildOpcion('Mis logros', 'Insignias y medallas', '🏆',
                            () => _irAPantalla(const LogrosScreen()),
                            color: const Color(0xFF42A5F5)),
                        _buildOpcion('Retos', 'Completa los desafíos', '🚩',
                            () => _irAPantalla(const RetosScreen()),
                            color: const Color(0xFF42A5F5)),
                        _buildOpcion(
                            'Recordatorios',
                            'Alertas y cuidados',
                            '🔔',
                            () => _irAPantalla(const RecordatoriosScreen()),
                            color: const Color(0xFF42A5F5)),
                      ],
                    ),
                    // ==================== MI NEGOCIO REAL ====================
                    _buildCategoria(
                      titulo: 'Mi negocio real',
                      subtitulo: 'Vende y capacita',
                      color: const Color(0xFFFF7043),
                      color2: const Color(0xFFFF8A65),
                      iconImage: 'assets/images/icons/icono_negocio.png',
                      index: 3,
                      opciones: [
                        _buildOpcion(
                            'Vender lombrices',
                            'Precio: \$2.50 c/u',
                            '🏷️',
                            () => _irAPantalla(const VentasLombricesScreen()),
                            color: const Color(0xFFFF7043)),
                        _buildOpcion(
                            'Vender humus', 
                            'Precio: \$10 por bolsita',
                            '🌱', () => _irAPantalla(const VentasHumusScreen()),
                            color: const Color(0xFFFF7043)),
                        _buildOpcion(
                            'Vender lixiviado',
                            'Precio: \$25',
                            '💦',
                            () => _irAPantalla(const VentasAtomizadorScreen()),
                            color: const Color(0xFFFF7043)),
                        _buildOpcion(
                            'Ventas totales',
                            'Historial de ingresos',
                            '🧾',
                            () => _irAPantalla(const VentasHistorialScreen()),
                            color: const Color(0xFFFF7043)),
                        _buildOpcion('Mi diario', 'Registra tu avance', '📝',
                            () => _irAPantalla(const NuevaEntradaScreen()),
                            color: const Color(0xFFFFA726)),
                        _buildOpcion('Accesorios', 'Personaliza a tu lombriz',
                            '🛍️', () => _irAPantalla(const AccesoriosScreen()),
                            color: const Color(0xFFFF7043)),
                        _buildOpcion(
                            'Venta de capacitación',
                            'Capacita a otros niños',
                            '🎓',
                            () => _irAPantalla(const CapacitacionScreen()),
                            color: const Color(0xFFFF7043)),
                        _buildOpcion(
                            'Matematicas de negocios',
                            'Gana monedas resolviendo',
                            '🧮',
                            () => _irAPantalla(
                                const ProblemasMatematicosScreen()),
                            color: const Color(0xFFFF7043)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            // ✅ Banner promocional fijo al final
            if (_mostrarBanner)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/banner_promocional.png',
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.verde, AppTheme.verdeClaro],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '¡Descubre más en Lombriaventura!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mostrarBanner = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      floatingActionButton: _categoriaAbierta == -1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 120.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  //Sombra sólida desplazada hacia abajo
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF388E3C), // verde oscuro
                      offset: const Offset(0, 5), // desplazamiento hacia abajo
                      blurRadius: 0, // sin difuminado = sombra sólida
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatIAScreen()),
                    );
                  },
                  backgroundColor: AppTheme.verde,
                  elevation: 0, // ← quitamos la sombra original de Flutter
                  hoverElevation: 0, // ← sin elevación al hacer hover
                  focusElevation: 0,
                  highlightElevation: 0, // ← sin elevación al presionar
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    //Borde inferior grueso que refuerza la profundidad
                    side: const BorderSide(
                      color: Color(0xFF388E3C), // verde oscuro
                      width: 0,
                    ),
                  ),
                  icon: const Icon(Icons.chat_sharp, color: Colors.white),
                  label: const Text(
                    'Pregúntale a la lombriz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
