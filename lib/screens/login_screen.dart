import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme.dart';
import 'menu_principal.dart';
import 'registro_screen.dart';
import 'recuperar_password_screen.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../models/api_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verificarSesionYDescargar();
  }

  Future<void> _verificarSesionYDescargar() async {
    try {
      final box = await Hive.openBox('configuracion');
      final loginExitoso = box.get('login_exitoso', defaultValue: false);

      if (loginExitoso) {
        _irAlMenu();
        return;
      }

      await _descargarDatosIniciales();
    } catch (e) {
      print('❌ Error en verificación inicial: $e');
    }
  }

  Future<void> _descargarDatosIniciales() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final syncService = SyncService();

      if (!await syncService.tieneInternet()) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Sin conexión a internet. Usa datos guardados localmente.';
        });
        return;
      }

      print('🌐 Descargando datos iniciales desde la API...');

      final usuariosResult = await ApiService().obtenerTodosUsuarios();
      if (usuariosResult.ok && usuariosResult.data != null) {
        final usuariosBox = await Hive.openBox('usuarios');
        await usuariosBox.put('lista', usuariosResult.data!.map((u) => u.toJson()).toList());
        print('✅ Usuarios descargados: ${usuariosResult.data!.length}');
      }

      final configBox = await Hive.openBox('configuracion');
      final usuarioActual = configBox.get('usuario_actual');
      if (usuarioActual != null) {
        final diarioResult = await ApiService().obtenerDiario(usuarioActual);
        if (diarioResult.ok && diarioResult.data != null) {
          final diarioBox = await Hive.openBox('diario');
          await diarioBox.put('lista', diarioResult.data!.map((e) => e.toJson()).toList());
          print('✅ Diario descargado: ${diarioResult.data!.length}');
        }
      }

      final ventasResult = await ApiService().obtenerTodasVentas();
      if (ventasResult.ok && ventasResult.data != null) {
        final ventasBox = await Hive.openBox('historial_ventas');
        await ventasBox.put('lista', ventasResult.data!.map((v) => v.toJson()).toList());
        print('✅ Ventas descargadas: ${ventasResult.data!.length}');
      }

      final logrosResult = await ApiService().obtenerTodosLogros();
      if (logrosResult.ok && logrosResult.data != null) {
        final logrosBox = await Hive.openBox('logros');
        await logrosBox.put('lista', logrosResult.data!.map((l) => l.toJson()).toList());
        print('✅ Logros descargados: ${logrosResult.data!.length}');
      }

      setState(() {
        _isDownloading = false;
        _errorMessage = '✅ Datos descargados correctamente. ¡Ya puedes iniciar sesión!';
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });

      print('✅ Descarga de datos iniciales completada');
    } catch (e) {
      print('❌ Error descargando datos: $e');
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Error al descargar datos. Intenta de nuevo.';
      });
    }
  }

  Future<void> _iniciarSesion() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu nombre de usuario');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final box = await Hive.openBox('configuracion');
      final nombreUsuario = _usernameController.text.trim();
      final passwordIngresada = _passwordController.text.trim();

      print('🔍 Buscando usuario: $nombreUsuario');

      // ✅ BUSCAR EN HIVE PRIMERO (datos descargados)
      final usuariosBox = await Hive.openBox('usuarios');
      final usuariosLista = usuariosBox.get('lista', defaultValue: []);
      
      Usuario? usuarioEncontrado;
      for (var item in usuariosLista) {
        if (item['nombre_usuario'] == nombreUsuario) {
          usuarioEncontrado = Usuario.fromJson(item);
          break;
        }
      }

      if (usuarioEncontrado != null) {
        final passwordGuardada = box.get('usuario_password');
        if (passwordGuardada == passwordIngresada || usuarioEncontrado.password == passwordIngresada) {
          print('✅ Login exitoso desde datos locales');
          await box.put('usuario_uid', usuarioEncontrado.uid);
          await box.put('usuario_actual', usuarioEncontrado.nombreUsuario);
          await box.put('usuario_nombre', usuarioEncontrado.nombre);
          await box.put('usuario_password', passwordIngresada);
          await box.put('login_exitoso', true);
          _irAlMenu();
          return;
        } else {
          setState(() {
            _errorMessage = 'Contraseña incorrecta';
            _isLoading = false;
          });
          return;
        }
      }

      // ✅ Si no está en Hive, buscar en API (online)
      final syncService = SyncService();
      if (await syncService.tieneInternet()) {
        print('🌐 Buscando usuario en API por nombre: $nombreUsuario');

        try {
          final result = await ApiService().loginUsuario(
            nombreUsuario: nombreUsuario,
            password: passwordIngresada,
          );

          if (result.ok && result.data != null) {
            final usuario = result.data!;
            print('✅ Usuario encontrado en API: ${usuario.nombreUsuario}');

            await box.put('usuario_uid', usuario.uid);
            await box.put('usuario_actual', usuario.nombreUsuario);
            await box.put('usuario_nombre', usuario.nombre);
            await box.put('usuario_password', passwordIngresada);
            await box.put('login_exitoso', true);

            final usuariosBox2 = await Hive.openBox('usuarios');
            final listaActual = usuariosBox2.get('lista', defaultValue: []);
            listaActual.add(usuario.toJson());
            await usuariosBox2.put('lista', listaActual);

            _irAlMenu();
            return;
          } else {
            setState(() {
              _errorMessage = result.error ?? 'Usuario o contraseña incorrectos';
              _isLoading = false;
            });
            return;
          }
        } catch (e) {
          print('⚠️ Error buscando por nombre: $e');
          setState(() {
            _errorMessage = 'Error al conectar con el servidor';
            _isLoading = false;
          });
          return;
        }
      } else {
        setState(() {
          _errorMessage = 'Usuario no encontrado en datos locales. Conéctate a internet para sincronizar.';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('❌ Error en login: $e');
      setState(() {
        _errorMessage = 'Error al iniciar sesión: $e';
        _isLoading = false;
      });
    }
  }

  void _irAlMenu() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MenuPrincipal()),
      (route) => false,
    );
  }

  void _irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
  }

  void _irARecuperarPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecuperarPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.verde, AppTheme.fondo],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_lombriaventura.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bug_report, size: 60, color: AppTheme.verde),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lombriaventura',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '¡Bienvenido de vuelta!',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        if (_isDownloading)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Descargando datos...',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_errorMessage != null && !_isDownloading)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _errorMessage!.startsWith('✅')
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _errorMessage!.startsWith('✅') ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de usuario',
                            prefixIcon: const Icon(Icons.person, color: AppTheme.verde),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock, color: AppTheme.verde),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _irARecuperarPassword,
                              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppTheme.verde)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isDownloading) ? null : _iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.verde,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Ingresar', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes cuenta?'),
                            TextButton(
                              onPressed: _irARegistro,
                              child: const Text('Regístrate', style: TextStyle(color: AppTheme.verde)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}