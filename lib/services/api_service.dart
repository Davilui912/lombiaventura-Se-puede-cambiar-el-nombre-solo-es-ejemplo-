import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/api_models.dart';
import 'api_config.dart';

class ApiResult<T> {
  final T? data;
  final String? error;
  bool get ok => error == null;

  ApiResult.ok(this.data) : error = null;
  ApiResult.error(this.error) : data = null;
}

class ApiService {
  final String _base = ApiConfig.baseUrl;
  final Map<String, String> _headers = ApiConfig.headers;
  final Duration _timeout = ApiConfig.timeout;

  Uri _uri(String path) => Uri.parse('$_base$path');

  ApiResult<T> _handle<T>(
    http.Response res,
    T Function(dynamic) parse,
  ) {
    try {
      dynamic body;
      if (res.bodyBytes.isNotEmpty) {
        body = jsonDecode(utf8.decode(res.bodyBytes));
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResult.ok(parse(body));
      }
      final msg = body is Map
          ? body['detail'] ?? 'Error ${res.statusCode}'
          : 'Error ${res.statusCode}';
      return ApiResult.error(msg.toString());
    } catch (e) {
      return ApiResult.error('Error al procesar la respuesta: $e');
    }
  }

  ApiResult<T> _catch<T>(Object e) =>
      ApiResult.error('Sin conexión o tiempo de espera agotado: $e');

  // ─── USUARIOS ───

  Future<ApiResult<Usuario>> crearUsuario({
    required String uid,
    required String nombre,
    required String nombreUsuario,
    required String email,
    int? edad,
    String? ciudad,
    String? genero,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/usuarios'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'nombre': nombre,
              'nombre_usuario': nombreUsuario,
              'email': email,
              if (edad != null) 'edad': edad,
              if (ciudad != null) 'ciudad': ciudad,
              if (genero != null) 'genero': genero,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => Usuario.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<Usuario>> obtenerUsuario(String nombreUsuario) async {
    try {
      final res = await http
          .get(_uri('/usuarios'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List;
        for (var item in data) {
          if (item['nombre_usuario'] == nombreUsuario) {
            return ApiResult.ok(Usuario.fromJson(item));
          }
        }
        return ApiResult.error('Usuario no encontrado');
      } else {
        return ApiResult.error('Error al obtener usuarios');
      }
    } catch (e) {
      return _catch(e);
    }
  }

  /// ✅ Obtener todos los usuarios (para descarga inicial)
  Future<ApiResult<List<Usuario>>> obtenerTodosUsuarios() async {
    try {
      final res = await http
          .get(_uri('/usuarios'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Usuario.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  /// ✅ LOGIN CORREGIDO - Valida en Hive, no en API
  Future<ApiResult<Usuario>> loginUsuario({
    required String nombreUsuario,
    required String password,
  }) async {
    try {
      // ✅ 1. Buscar en Hive primero
      final box = await Hive.openBox('configuracion');
      final usuarioGuardado = box.get('usuario_actual');
      final passwordGuardada = box.get('usuario_password');

      print('🔍 Buscando en Hive: usuario=$usuarioGuardado');
      print('🔍 Contraseña en Hive: $passwordGuardada');
      print('🔍 Contraseña ingresada: $password');

      // ✅ 2. Validar en Hive
      if (usuarioGuardado == nombreUsuario && passwordGuardada == password) {
        print('✅ Contraseña válida desde Hive');

        // ✅ 3. Obtener datos de la API (sin contraseña)
        final res = await http
            .get(_uri('/usuarios'), headers: _headers)
            .timeout(_timeout);

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = jsonDecode(res.body) as List;
          for (var item in data) {
            if (item['nombre_usuario'] == nombreUsuario) {
              final usuarioApi = Usuario.fromJson(item);
              // ✅ 4. Combinar datos API + contraseña de Hive
              return ApiResult.ok(Usuario(
                uid: usuarioApi.uid,
                nombre: usuarioApi.nombre,
                nombreUsuario: usuarioApi.nombreUsuario,
                email: usuarioApi.email,
                password: password, // ✅ Usar contraseña de Hive
                edad: usuarioApi.edad,
                ciudad: usuarioApi.ciudad,
                genero: usuarioApi.genero,
              ));
            }
          }
          return ApiResult.error('Usuario no encontrado en API');
        }
        return ApiResult.error('Error al obtener datos de API');
      }

      // ✅ Si no está en Hive o contraseña no coincide
      print('❌ Usuario no encontrado en Hive o contraseña incorrecta');
      return ApiResult.error('Usuario o contraseña incorrectos');
    } catch (e) {
      print('❌ Error en loginUsuario: $e');
      return _catch(e);
    }
  }

  Future<ApiResult<Usuario>> obtenerUsuarioPorEmail(String email) async {
    try {
      final res = await http
          .get(_uri('/usuarios'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List;
        for (var item in data) {
          if (item['email'] == email) {
            return ApiResult.ok(Usuario.fromJson(item));
          }
        }
        return ApiResult.error('Usuario no encontrado');
      } else {
        return ApiResult.error('Error al obtener usuarios');
      }
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<bool>> eliminarUsuario(String uid) async {
    try {
      final res = await http
          .delete(_uri('/usuarios/$uid'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 204) return ApiResult.ok(true);
      return ApiResult.error('Error al eliminar usuario');
    } catch (e) {
      return _catch(e);
    }
  }

  // ─── DIARIO ───

  Future<ApiResult<EntradaDiario>> crearEntradaDiario({
    required String uid,
    String? nota,
    String? estado,
    String? temperatura,
    String? tipoResiduo,
    int? compostaPunos,
    int? lixiviadoCucharadas,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/diario'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              if (nota != null) 'nota': nota,
              if (estado != null) 'estado': estado,
              if (temperatura != null) 'temperatura': temperatura,
              if (tipoResiduo != null) 'tipo_residuo': tipoResiduo,
              if (compostaPunos != null) 'composta_punos': compostaPunos,
              if (lixiviadoCucharadas != null)
                'lixiviado_cucharadas': lixiviadoCucharadas,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => EntradaDiario.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<List<EntradaDiario>>> obtenerDiario(String uid) async {
    try {
      final res = await http
          .get(_uri('/usuarios/$uid/diario'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => EntradaDiario.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  // ─── VENTAS ───

  Future<ApiResult<Venta>> crearVenta({
    required String uid,
    required String producto,
    required int cantidad,
    required double precioUnitario,
    required int totalGanado,
    String? descripcion,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/ventas'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'producto': producto,
              'cantidad': cantidad,
              'precio_unitario': precioUnitario,
              'total_ganado': totalGanado,
              if (descripcion != null) 'descripcion': descripcion,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => Venta.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<List<Venta>>> obtenerVentas(String uid) async {
    try {
      final res = await http
          .get(_uri('/usuarios/$uid/ventas'), headers: _headers)
          .timeout(_timeout);
      return _handle(
          res, (b) => (b as List).map((e) => Venta.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  /// ✅ Obtener todas las ventas (para descarga inicial)
  Future<ApiResult<List<Venta>>> obtenerTodasVentas() async {
    try {
      final res = await http
          .get(_uri('/ventas'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Venta.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  // ─── RETOS ───

  Future<ApiResult<Reto>> crearReto({
    required String uid,
    required String retoId,
    int? medicion,
    String? fotoUrl,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/retos'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'reto_id': retoId,
              'completado': false,
              if (medicion != null) 'medicion': medicion,
              if (fotoUrl != null) 'foto_url': fotoUrl,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => Reto.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<List<Reto>>> obtenerRetos(String uid) async {
    try {
      final res = await http
          .get(_uri('/usuarios/$uid/retos'), headers: _headers)
          .timeout(_timeout);
      return _handle(
          res, (b) => (b as List).map((e) => Reto.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  /// ✅ Obtener todos los retos (para descarga inicial)
  Future<ApiResult<List<Reto>>> obtenerTodosRetos() async {
    try {
      final res = await http
          .get(_uri('/retos'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Reto.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<Reto>> completarReto(int retoId) async {
    try {
      final res = await http
          .patch(_uri('/retos/$retoId/completar'), headers: _headers)
          .timeout(_timeout);
      return _handle(res, (b) => Reto.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  // ─── LOGROS ───

  Future<ApiResult<Logro>> crearLogro({
    required String uid,
    required String tipo,
    required String nombre,
    String? descripcion,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/logros'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'tipo': tipo,
              'nombre': nombre,
              if (descripcion != null) 'descripcion': descripcion,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => Logro.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<List<Logro>>> obtenerLogros(String uid) async {
    try {
      final res = await http
          .get(_uri('/usuarios/$uid/logros'), headers: _headers)
          .timeout(_timeout);
      return _handle(
          res, (b) => (b as List).map((e) => Logro.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  /// ✅ Obtener todos los logros (para descarga inicial)
  Future<ApiResult<List<Logro>>> obtenerTodosLogros() async {
    try {
      final res = await http
          .get(_uri('/logros'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Logro.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  // ─── RECORDATORIOS ───

  Future<ApiResult<Recordatorio>> crearRecordatorio({
    required String uid,
    required String titulo,
    String? mensaje,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/recordatorios'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'titulo': titulo,
              if (mensaje != null) 'mensaje': mensaje,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => Recordatorio.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<List<Recordatorio>>> obtenerRecordatorios(String uid) async {
    try {
      final res = await http
          .get(_uri('/usuarios/$uid/recordatorios'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Recordatorio.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  /// ✅ Obtener todos los recordatorios (para descarga inicial)
  Future<ApiResult<List<Recordatorio>>> obtenerTodosRecordatorios() async {
    try {
      final res = await http
          .get(_uri('/recordatorios'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Recordatorio.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<Recordatorio>> marcarRecordatorioVisto(int id) async {
    try {
      final res = await http
          .patch(_uri('/recordatorios/$id/marcar-visto'), headers: _headers)
          .timeout(_timeout);
      return _handle(res, (b) => Recordatorio.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<bool>> eliminarRecordatorio(int id) async {
    try {
      final res = await http
          .delete(_uri('/recordatorios/$id'), headers: _headers)
          .timeout(_timeout);
      if (res.statusCode == 204) return ApiResult.ok(true);
      return ApiResult.error('Error al eliminar recordatorio');
    } catch (e) {
      return _catch(e);
    }
  }

  // ─── CAPACITACIONES ───

  Future<ApiResult<Capacitacion>> crearCapacitacion({
    required String uid,
    required String nombreCapacitado,
    int? edadCapacitado,
    String? municipio,
    String? estado,
    String? pais,
    String? invitadoPor,
    int monedasGanadas = 50,
  }) async {
    try {
      final res = await http
          .post(
            _uri('/capacitaciones'),
            headers: _headers,
            body: jsonEncode({
              'uid': uid,
              'nombre_capacitado': nombreCapacitado,
              if (edadCapacitado != null) 'edad_capacitado': edadCapacitado,
              if (municipio != null) 'municipio': municipio,
              if (estado != null) 'estado': estado,
              if (pais != null) 'pais': pais,
              if (invitadoPor != null) 'invitado_por': invitadoPor,
              'monedas_ganadas': monedasGanadas,
            }),
          )
          .timeout(_timeout);
      return _handle(res, (b) => Capacitacion.fromJson(b));
    } catch (e) {
      return _catch(e);
    }
  }

  Future<ApiResult<List<Capacitacion>>> obtenerCapacitaciones(
      String uid) async {
    try {
      final res = await http
          .get(_uri('/usuarios/$uid/capacitaciones'), headers: _headers)
          .timeout(_timeout);
      return _handle(res,
          (b) => (b as List).map((e) => Capacitacion.fromJson(e)).toList());
    } catch (e) {
      return _catch(e);
    }
  }
}