import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../services/sync_service.dart';

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
  String? _uidUsuario;
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final ApiService _apiService = ApiService();
  final SyncService _syncService = SyncService();

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
      Map<String, dynamic>? usuarioEncontrado;
      String? uidEncontrado;
      String? preguntaSeguridad;
      
      // ✅ 1. Buscar en la lista de usuarios de Hive
      final usuariosBox = await Hive.openBox('usuarios');
      final listaUsuarios = usuariosBox.get('lista', defaultValue: <Map<String, dynamic>>[]);
      
      print('📦 Buscando en Hive: $usuario');
      
      for (var item in listaUsuarios) {
        if (item['nombre_usuario'] == usuario) {
          usuarioEncontrado = item;
          uidEncontrado = item['uid'];
          preguntaSeguridad = item['pregunta_seguridad'];
          print('✅ Encontrado en Hive: pregunta=$preguntaSeguridad');
          break;
        }
      }

      // ✅ 2. Si NO está en Hive, buscar en API
      if (usuarioEncontrado == null) {
        if (await _syncService.tieneInternet()) {
          print('🌐 Buscando usuario en API: $usuario');
          
          try {
            final result = await _apiService.obtenerUsuario(usuario);
            
            if (result.ok && result.data != null) {
              final user = result.data!;
              print('✅ Usuario encontrado en API: ${user.nombreUsuario}');
              print('✅ Pregunta de seguridad en API: ${user.preguntaSeguridad}');
              
              usuarioEncontrado = {
                'uid': user.uid,
                'nombre': user.nombre,
                'nombre_usuario': user.nombreUsuario,
                'email': user.email,
                'password': user.password ?? '',
                'pregunta_seguridad': user.preguntaSeguridad,
                'respuesta_seguridad': user.respuestaSeguridad,
                'edad': user.edad,
                'ciudad': user.ciudad,
                'genero': user.genero,
                'fecha_registro': DateTime.now().toIso8601String(),
              };
              uidEncontrado = user.uid;
              preguntaSeguridad = user.preguntaSeguridad;
              
              // ✅ Guardar en Hive para futuras consultas
              final listaActualizada = List<Map<String, dynamic>>.from(listaUsuarios);
              listaActualizada.add(usuarioEncontrado!);
              await usuariosBox.put('lista', listaActualizada);
              print('✅ Usuario sincronizado de API a Hive');
            } else {
              setState(() {
                _errorMessage = 'No existe una cuenta con este usuario';
                _isLoading = false;
              });
              return;
            }
          } catch (e) {
            print('❌ Error en API: $e');
            setState(() {
              _errorMessage = 'Error al buscar usuario: $e';
              _isLoading = false;
            });
            return;
          }
        } else {
          setState(() {
            _errorMessage = 'No tienes internet y el usuario no está en tu dispositivo';
            _isLoading = false;
          });
          return;
        }
      }

      // ✅ 3. Si encontramos el usuario, mostrar la pregunta de seguridad
      if (usuarioEncontrado != null && uidEncontrado != null) {
        _uidUsuario = uidEncontrado;
        _preguntaSeguridad = preguntaSeguridad;
        
        print('✅ UID: $_uidUsuario');
        print('✅ Pregunta de seguridad: $_preguntaSeguridad');
        
        // ✅ Verificar si tiene pregunta de seguridad
        if (_preguntaSeguridad == null || _preguntaSeguridad!.isEmpty) {
          setState(() {
            _errorMessage = '⚠️ Este usuario no tiene pregunta de seguridad.\n'
                'Regístrate nuevamente para configurar una.';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudo encontrar el usuario';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Error en verificación: $e');
      setState(() {
        _errorMessage = 'Error al verificar: $e';
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

    if (_uidUsuario == null) {
      setState(() => _errorMessage = 'Error: No se encontró el usuario');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ 1. Verificar en Hive primero (rápido)
      final usuariosBox = await Hive.openBox('usuarios');
      final listaUsuarios = usuariosBox.get('lista', defaultValue: <Map<String, dynamic>>[]);
      
      bool respuestaCorrecta = false;
      String? respuestaGuardada;
      
      for (var item in listaUsuarios) {
        if (item['uid'] == _uidUsuario) {
          respuestaGuardada = item['respuesta_seguridad'];
          print('🔍 Respuesta guardada en Hive: $respuestaGuardada');
          break;
        }
      }
      
      // Si está en Hive, verificar localmente
      if (respuestaGuardada != null) {
        respuestaCorrecta = respuesta.toLowerCase() == respuestaGuardada.toLowerCase();
        print('📝 Comparando: $respuesta == $respuestaGuardada -> $respuestaCorrecta');
      }
      
      // ✅ 2. Si no está en Hive o la respuesta es incorrecta, verificar en API
      if (!respuestaCorrecta && await _syncService.tieneInternet()) {
        print('🌐 Verificando respuesta en API...');
        
        try {
          final result = await _apiService.verificarSeguridad(
            uid: _uidUsuario!,
            respuestaSeguridad: respuesta,
          );
          
          if (result.ok) {
            respuestaCorrecta = true;
            print('✅ Respuesta verificada en API');
          } else {
            print('❌ Respuesta incorrecta en API: ${result.error}');
          }
        } catch (e) {
          print('⚠️ Error en API: $e');
        }
      }
      
      if (respuestaCorrecta) {
        setState(() {
          _step = 3;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '❌ Respuesta incorrecta. Intenta de nuevo.';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Error en verificación: $e');
      setState(() {
        _errorMessage = 'Error al verificar respuesta: $e';
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
      // ✅ Actualizar en Hive (configuración)
      final configBox = await Hive.openBox('configuracion');
      await configBox.put('usuario_password', nuevaPassword);
      
      // ✅ Actualizar en la lista de usuarios de Hive
      final usuariosBox = await Hive.openBox('usuarios');
      final listaUsuarios = usuariosBox.get('lista', defaultValue: <Map<String, dynamic>>[]);
      
      bool encontrado = false;
      for (var i = 0; i < listaUsuarios.length; i++) {
        if (listaUsuarios[i]['uid'] == _uidUsuario) {
          listaUsuarios[i]['password'] = nuevaPassword;
          encontrado = true;
          break;
        }
      }
      
      if (encontrado) {
        await usuariosBox.put('lista', listaUsuarios);
        print('✅ Contraseña actualizada en Hive');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Contraseña cambiada exitosamente!'),
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

  Widget _buildStepIndicator(int number, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppTheme.verde : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppTheme.verde : Colors.grey.shade500,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: active ? AppTheme.verde : Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: AppTheme.verde,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Indicador de pasos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(1, 'Usuario', _step >= 1),
                        _buildStepLine(_step >= 2),
                        _buildStepIndicator(2, 'Seguridad', _step >= 2),
                        _buildStepLine(_step >= 3),
                        _buildStepIndicator(3, 'Nueva', _step >= 3),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.verde.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.verde.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '📌 Pregunta:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _preguntaSeguridad ?? '¿Cuál es tu color favorito?',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                          helperText: 'Ingresa la respuesta que configuraste al registrarte',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _step = 1;
                                  _errorMessage = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('⬅️ Atrás'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
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
                          helperText: 'Usa al menos 4 caracteres',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _step = 2;
                                  _errorMessage = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('⬅️ Atrás'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _cambiarPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.verde,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                                  : const Text('Cambiar', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}