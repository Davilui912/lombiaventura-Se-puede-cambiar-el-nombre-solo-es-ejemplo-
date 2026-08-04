import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'sync_service.dart';
import '../models/api_models.dart';

class AuthService {
  final ApiService _api = ApiService();
  final SyncService _syncService = SyncService();
  
  String? _currentUid;
  Usuario? _currentUser;

  String? get currentUid => _currentUid;
  Usuario? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // ─── OBTENER USUARIO DESDE HIVE ───

  Future<Usuario?> obtenerUsuarioDesdeHive() async {
    try {
      final box = await Hive.openBox('configuracion');
      final uid = box.get('usuario_uid');
      final nombre = box.get('usuario_nombre');
      final nombreUsuario = box.get('usuario_actual');
      final email = box.get('usuario_email');
      final password = box.get('usuario_password');
      final preguntaSeguridad = box.get('usuario_pregunta_seguridad') ?? '';
      final respuestaSeguridad = box.get('usuario_respuesta_seguridad') ?? '';
      final edad = box.get('usuario_edad');
      final ciudad = box.get('usuario_ciudad');

      if (nombreUsuario != null) {
        return Usuario(
          uid: uid ?? '',
          nombre: nombre ?? '',
          nombreUsuario: nombreUsuario,
          email: email ?? '',
          password: password ?? '',
          preguntaSeguridad: preguntaSeguridad,
          respuestaSeguridad: respuestaSeguridad,
          edad: edad != null ? int.tryParse(edad.toString()) : null,
          ciudad: ciudad,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario de Hive: $e');
      return null;
    }
  }

  // ─── REGISTRO ───

  Future<({Usuario? usuario, String? error})> registrar({
    required String nombre,
    required String nombreUsuario,
    required String password,
    required String email,
    required String preguntaSeguridad,
    required String respuestaSeguridad,
    int? edad,
    String? ciudad,
    String? genero,
  }) async {
    try {
      final box = await Hive.openBox('configuracion');
      final uid = DateTime.now().millisecondsSinceEpoch.toString();

      // ✅ Guardar en Hive
      await box.put('usuario_uid', uid);
      await box.put('usuario_actual', nombreUsuario);
      await box.put('usuario_nombre', nombre);
      await box.put('usuario_password', password);
      await box.put('usuario_email', email);
      await box.put('usuario_pregunta_seguridad', preguntaSeguridad);
      await box.put('usuario_respuesta_seguridad', respuestaSeguridad);
      if (edad != null) await box.put('usuario_edad', edad.toString());
      if (ciudad != null) await box.put('usuario_ciudad', ciudad);
      await box.put('login_exitoso', true);

      final usuario = Usuario(
        uid: uid,
        nombre: nombre,
        nombreUsuario: nombreUsuario,
        email: email,
        password: password,
        preguntaSeguridad: preguntaSeguridad,
        respuestaSeguridad: respuestaSeguridad,
        edad: edad,
        ciudad: ciudad,
        genero: genero,
      );
      _currentUser = usuario;
      _currentUid = uid;

      // ✅ Guardar en API
      if (await _syncService.tieneInternet()) {
        final result = await _api.crearUsuario(
          uid: uid,
          nombre: nombre,
          nombreUsuario: nombreUsuario,
          email: email,
          preguntaSeguridad: preguntaSeguridad,
          respuestaSeguridad: respuestaSeguridad,
          edad: edad,
          ciudad: ciudad,
          genero: genero,
        );
        if (!result.ok) {
          await _syncService.guardarUsuarioPendiente({
            'uid': uid,
            'nombre': nombre,
            'nombreUsuario': nombreUsuario,
            'email': email,
            'preguntaSeguridad': preguntaSeguridad,
            'respuestaSeguridad': respuestaSeguridad,
            'edad': edad,
            'ciudad': ciudad,
            'genero': genero,
          });
        }
      }

      return (usuario: usuario, error: null);
    } catch (e) {
      return (usuario: null, error: 'Error inesperado: $e');
    }
  }

  // ─── LOGIN ───

  Future<({Usuario? usuario, String? error})> login({
    required String nombreUsuario,
    required String password,
  }) async {
    try {
      final box = await Hive.openBox('configuracion');
      final usuarioGuardado = box.get('usuario_actual');
      final passwordGuardada = box.get('usuario_password');

      if (usuarioGuardado == nombreUsuario && passwordGuardada == password) {
        final usuario = await obtenerUsuarioDesdeHive();
        if (usuario != null) {
          _currentUser = usuario;
          _currentUid = usuario.uid;
          await box.put('login_exitoso', true);
          return (usuario: usuario, error: null);
        }
      }

      // Buscar en API si no está en Hive
      if (await _syncService.tieneInternet()) {
        final result = await _api.loginUsuario(
          nombreUsuario: nombreUsuario,
          password: password,
        );
        if (result.ok && result.data != null) {
          final usuario = result.data!;
          await box.put('usuario_uid', usuario.uid);
          await box.put('usuario_actual', usuario.nombreUsuario);
          await box.put('usuario_nombre', usuario.nombre);
          await box.put('usuario_password', usuario.password);
          await box.put('usuario_email', usuario.email);
          await box.put('usuario_pregunta_seguridad', usuario.preguntaSeguridad);
          await box.put('usuario_respuesta_seguridad', usuario.respuestaSeguridad);
          if (usuario.edad != null) await box.put('usuario_edad', usuario.edad.toString());
          if (usuario.ciudad != null) await box.put('usuario_ciudad', usuario.ciudad);
          await box.put('login_exitoso', true);

          _currentUser = usuario;
          _currentUid = usuario.uid;
          return (usuario: usuario, error: null);
        }
      }

      return (usuario: null, error: 'Usuario o contraseña incorrectos');
    } catch (e) {
      return (usuario: null, error: 'Error inesperado: $e');
    }
  }

  // ─── CAMBIAR CONTRASEÑA ───

  Future<({bool success, String? error})> cambiarPassword({
    required String nuevaPassword,
  }) async {
    try {
      if (_currentUser == null) {
        return (success: false, error: 'No hay usuario autenticado');
      }

      final box = await Hive.openBox('configuracion');
      await box.put('usuario_password', nuevaPassword);

      _currentUser = Usuario(
        uid: _currentUser!.uid,
        nombre: _currentUser!.nombre,
        nombreUsuario: _currentUser!.nombreUsuario,
        email: _currentUser!.email,
        password: nuevaPassword,
        preguntaSeguridad: _currentUser!.preguntaSeguridad,
        respuestaSeguridad: _currentUser!.respuestaSeguridad,
        edad: _currentUser!.edad,
        ciudad: _currentUser!.ciudad,
        genero: _currentUser!.genero,
      );

      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: 'Error al cambiar contraseña: $e');
    }
  }

  // ─── LOGOUT ───

  Future<void> logout() async {
    final box = await Hive.openBox('configuracion');
    await box.put('login_exitoso', false);
    _currentUser = null;
    _currentUid = null;
  }

  // ─── GETTERS ───

  Usuario? get usuarioActual => _currentUser;
}