import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme.dart';
import 'login_screen.dart';
import 'menu_principal.dart';
import '../utils/textos_constantes.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _respuestaSeguridadController = TextEditingController();
  
  String? _preguntaSeguridad;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmar = true;
  String? _errorMessage;
  bool _privacidadAceptada = false;

  final List<String> _preguntasSeguridad = [
    '¿Cómo se llamaba tu primera mascota?',
    '¿Cuál es el nombre de tu mejor amigo?',
    '¿Qué color te gusta más?',
    '¿Cuál es tu comida favorita?',
    '¿Cómo se llama tu escuela?',
  ];

  void _mostrarAvisoPrivacidad(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('🔒 Aviso de Privacidad'),
        content: SingleChildScrollView(
          child: Text(
            TextosConstantes.avisoPrivacidad,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _registrarUsuario() async {
    if (!_privacidadAceptada) {
      setState(() => _errorMessage = 'Debes aceptar el Aviso de Privacidad para continuar');
      return;
    }

    if (_usuarioController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu nombre de usuario');
      return;
    }
    if (_nombreController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu nombre completo');
      return;
    }
    if (_passwordController.text.length < 4) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 4 caracteres');
      return;
    }
    if (_passwordController.text != _confirmarController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }
    if (_edadController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu edad');
      return;
    }
    if (_ciudadController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu ciudad');
      return;
    }
    if (_preguntaSeguridad == null) {
      setState(() => _errorMessage = 'Elige una pregunta de seguridad');
      return;
    }
    if (_respuestaSeguridadController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa la respuesta de seguridad');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = DateTime.now().millisecondsSinceEpoch.toString();
      final syncService = SyncService();

      // ✅ 1. Guardar en Hive SIEMPRE
      final configBox = await Hive.openBox('configuracion');
      await configBox.put('usuario_uid', uid);
      await configBox.put('usuario_actual', _usuarioController.text.trim());
      await configBox.put('usuario_nombre', _nombreController.text.trim());
      await configBox.put('usuario_password', _passwordController.text.trim());
      await configBox.put('usuario_edad', _edadController.text.trim());
      await configBox.put('usuario_ciudad', _ciudadController.text.trim());
      await configBox.put('usuario_pregunta_seguridad', _preguntaSeguridad);
      await configBox.put('usuario_respuesta_seguridad', _respuestaSeguridadController.text.trim());
      await configBox.put('usuario_fecha_registro', DateTime.now().toIso8601String());
      await configBox.put('privacidad_aceptada', true);
      await configBox.put('login_exitoso', true);

      print('✅ Usuario guardado en Hive: ${_usuarioController.text.trim()}');

      // ✅ 2. Guardar en API (con pregunta y respuesta de seguridad)
      if (await syncService.tieneInternet()) {
        print('🌐 Guardando usuario en API...');
        final result = await ApiService().crearUsuario(
          uid: uid,
          nombre: _nombreController.text.trim(),
          nombreUsuario: _usuarioController.text.trim(),
          email: '${_usuarioController.text.trim()}@lombriaventura.com',
          preguntaSeguridad: _preguntaSeguridad!,
          respuestaSeguridad: _respuestaSeguridadController.text.trim(),
          edad: int.tryParse(_edadController.text.trim()),
          ciudad: _ciudadController.text.trim(),
          genero: null,
        );

        if (result.ok) {
          print('✅ Usuario guardado en API');
        } else {
          await syncService.guardarUsuarioPendiente({
            'uid': uid,
            'nombre': _nombreController.text.trim(),
            'nombreUsuario': _usuarioController.text.trim(),
            'email': '${_usuarioController.text.trim()}@lombriaventura.com',
            'preguntaSeguridad': _preguntaSeguridad,
            'respuestaSeguridad': _respuestaSeguridadController.text.trim(),
            'edad': int.tryParse(_edadController.text.trim()),
            'ciudad': _ciudadController.text.trim(),
            'genero': null,
          });
          print('💾 Usuario guardado en pendientes (API falló)');
        }
      } else {
        await syncService.guardarUsuarioPendiente({
          'uid': uid,
          'nombre': _nombreController.text.trim(),
          'nombreUsuario': _usuarioController.text.trim(),
          'email': '${_usuarioController.text.trim()}@lombriaventura.com',
          'preguntaSeguridad': _preguntaSeguridad,
          'respuestaSeguridad': _respuestaSeguridadController.text.trim(),
          'edad': int.tryParse(_edadController.text.trim()),
          'ciudad': _ciudadController.text.trim(),
          'genero': null,
        });
        print('💾 Usuario guardado en pendientes (sin internet)');
      }

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MenuPrincipal()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al registrar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: AppTheme.verde,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📝 Registro',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para comenzar',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _usuarioController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon: const Icon(Icons.person, color: AppTheme.verde),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'Este será tu nombre para iniciar sesión',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: const Icon(Icons.badge, color: AppTheme.verde),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña (mínimo 4 caracteres)',
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.verde),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _confirmarController,
                  obscureText: _obscureConfirmar,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.verde),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmar ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _edadController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Edad',
                    prefixIcon: const Icon(Icons.cake, color: AppTheme.verde),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _ciudadController,
                  decoration: InputDecoration(
                    labelText: 'Ciudad',
                    prefixIcon: const Icon(Icons.location_city, color: AppTheme.verde),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('🔐 Pregunta de seguridad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _preguntaSeguridad,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Selecciona una pregunta'),
                    ),
                    isExpanded: true,
                    items: _preguntasSeguridad.map((pregunta) {
                      return DropdownMenuItem(
                        value: pregunta,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(pregunta, overflow: TextOverflow.ellipsis),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _preguntaSeguridad = value),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _respuestaSeguridadController,
                  decoration: InputDecoration(
                    labelText: 'Respuesta',
                    prefixIcon: const Icon(Icons.security, color: AppTheme.verde),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: 'Esta respuesta te ayudará a recuperar tu contraseña',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        value: _privacidadAceptada,
                        onChanged: (value) {
                          setState(() {
                            _privacidadAceptada = value ?? false;
                          });
                        },
                        activeColor: AppTheme.verde,
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                          children: [
                            const TextSpan(text: 'He leído y acepto el '),
                            TextSpan(
                              text: 'Aviso de Privacidad',
                              style: const TextStyle(
                                color: AppTheme.verde,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _mostrarAvisoPrivacidad(context);
                                },
                            ),
                            const TextSpan(text: ' y el tratamiento de mis datos personales.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_privacidadAceptada ? null : _registrarUsuario,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.verde,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                        : const Text('Registrarse', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Iniciar sesión', style: TextStyle(color: AppTheme.verde)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}