import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lombriaventura/services/sync_service.dart';
import '../config/theme.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _respuestaController = TextEditingController();
  final TextEditingController _nuevaPasswordController = TextEditingController();
  
  int _step = 1;
  String? _preguntaSeguridad;
  Usuario? _usuarioEncontrado;
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _respuestaController.dispose();
    _nuevaPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verificarUsuario() async {
    final usuario = _usuarioController.text.trim();
    if (usuario.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu nombre de usuario');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ 1. Buscar en Hive primero
      final usuariosBox = await Hive.openBox('usuarios');
      final listaUsuarios = usuariosBox.get('lista', defaultValue: <Map<String, dynamic>>[]);
      
      Map<String, dynamic>? usuarioData;
      for (var item in listaUsuarios) {
        if (item['nombre_usuario'] == usuario) {
          usuarioData = item;
          break;
        }
      }

      // ✅ 2. Si no está en Hive, buscar en API
      if (usuarioData == null) {
        final syncService = SyncService();
        if (await syncService.tieneInternet()) {
          final result = await ApiService().obtenerUsuario(usuario);
          if (result.ok && result.data != null) {
            _usuarioEncontrado = result.data;
            _preguntaSeguridad = _usuarioEncontrado?.preguntaSeguridad ?? '¿Cuál es tu color favorito?';
            setState(() {
              _step = 2;
              _isLoading = false;
            });
            return;
          }
        }
        setState(() {
          _errorMessage = 'No existe una cuenta con este usuario';
          _isLoading = false;
        });
        return;
      }

      // ✅ 3. Si está en Hive, obtener datos
      _usuarioEncontrado = Usuario.fromJson(usuarioData);
      _preguntaSeguridad = _usuarioEncontrado?.preguntaSeguridad ?? '¿Cuál es tu color favorito?';
      setState(() {
        _step = 2;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al verificar. Intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _verificarRespuesta() async {
    final respuesta = _respuestaController.text.trim();
    if (respuesta.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu respuesta de seguridad');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final respuestaCorrecta = _usuarioEncontrado?.respuestaSeguridad ?? '';
      if (respuesta.toLowerCase() == respuestaCorrecta.toLowerCase()) {
        setState(() {
          _step = 3;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Respuesta incorrecta';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al verificar respuesta';
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarPassword() async {
    final nuevaPassword = _nuevaPasswordController.text.trim();
    if (nuevaPassword.length < 4) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 4 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ 1. Actualizar en Hive
      final configBox = await Hive.openBox('configuracion');
      await configBox.put('usuario_password', nuevaPassword);
      
      // ✅ 2. Actualizar en la lista de usuarios de Hive
      final usuariosBox = await Hive.openBox('usuarios');
      final listaUsuarios = usuariosBox.get('lista', defaultValue: <Map<String, dynamic>>[]);
      
      for (var i = 0; i < listaUsuarios.length; i++) {
        if (listaUsuarios[i]['nombre_usuario'] == _usuarioEncontrado?.nombreUsuario) {
          listaUsuarios[i]['password'] = nuevaPassword;
          break;
        }
      }
      await usuariosBox.put('lista', listaUsuarios);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraseña cambiada exitosamente'),
            backgroundColor: AppTheme.verde,
          ),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cambiar la contraseña: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: AppTheme.verde,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_step == 1) ...[
                  const Text(
                    '👤 Ingresa tu usuario',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Te haremos una pregunta de seguridad', style: TextStyle(color: Colors.grey)),
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verificarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.verde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Continuar', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
                
                if (_step == 2) ...[
                  const Text(
                    '🔐 Pregunta de seguridad',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.verde.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _preguntaSeguridad ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
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
                    controller: _respuestaController,
                    decoration: InputDecoration(
                      labelText: 'Tu respuesta',
                      prefixIcon: const Icon(Icons.security, color: AppTheme.verde),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verificarRespuesta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.verde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Verificar', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
                
                if (_step == 3) ...[
                  const Text(
                    '🔑 Nueva contraseña',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Crea una nueva contraseña para tu cuenta', style: TextStyle(color: Colors.grey)),
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
                    controller: _nuevaPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña (mínimo 4 caracteres)',
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cambiarPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.verde,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}