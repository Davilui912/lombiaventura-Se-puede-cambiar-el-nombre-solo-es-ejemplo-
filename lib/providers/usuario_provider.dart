import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';

/// Estado global del usuario autenticado.
/// Úsalo con Provider o con Consumer<UsuarioProvider> en tus widgets.
///
/// Ejemplo de acceso:
///   final provider = context.read<UsuarioProvider>();
///   await provider.cargarPerfil(uid);
class UsuarioProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Usuario? _usuario;
  List<EntradaDiario> _diario = [];
  List<Reto> _retos = [];
  List<Logro> _logros = [];
  List<Recordatorio> _recordatorios = [];
  List<Capacitacion> _capacitaciones = [];
  List<Venta> _ventas = [];

  bool _cargando = false;
  String? _error;

  // ─── Getters
  Usuario? get usuario => _usuario;
  List<EntradaDiario> get diario => _diario;
  List<Reto> get retos => _retos;
  List<Logro> get logros => _logros;
  List<Recordatorio> get recordatorios => _recordatorios;
  List<Capacitacion> get capacitaciones => _capacitaciones;
  List<Venta> get ventas => _ventas;
  bool get cargando => _cargando;
  String? get error => _error;

  // Recordatorios no vistos — útil para mostrar badge de notificación
  int get recordatoriosSinVer => _recordatorios.where((r) => !r.visto).length;

  // ─── Carga de datos
  /// Carga el perfil del usuario y todos sus datos desde la API.
  /// Llámalo una vez después del login.
  Future<void> cargarPerfil(String uid) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    // Cargamos todo en paralelo para no esperar una por una
    final resultados = await Future.wait([
      _api.obtenerUsuario(uid),
      _api.obtenerDiario(uid),
      _api.obtenerRetos(uid),
      _api.obtenerLogros(uid),
      _api.obtenerRecordatorios(uid),
      _api.obtenerCapacitaciones(uid),
      _api.obtenerVentas(uid),
    ]);

    if (resultados[0].ok) _usuario = resultados[0].data as Usuario?;
    if (resultados[1].ok) {
      _diario = resultados[1].data as List<EntradaDiario>? ?? [];
    }
    if (resultados[2].ok) _retos = resultados[2].data as List<Reto>? ?? [];
    if (resultados[3].ok) _logros = resultados[3].data as List<Logro>? ?? [];
    if (resultados[4].ok) {
      _recordatorios = resultados[4].data as List<Recordatorio>? ?? [];
    }
    if (resultados[5].ok) {
      _capacitaciones = resultados[5].data as List<Capacitacion>? ?? [];
    }
    if (resultados[6].ok) _ventas = resultados[6].data as List<Venta>? ?? [];

    _cargando = false;
    notifyListeners();
  }

  // ─── Acciones

  Future<String?> agregarEntradaDiario({
    required String uid,
    String? nota,
    String? estado,
    String? temperatura,
    String? tipoResiduo,
  }) async {
    final result = await _api.crearEntradaDiario(
      uid: uid,
      nota: nota,
      estado: estado,
      temperatura: temperatura,
      tipoResiduo: tipoResiduo,
    );
    if (result.ok) {
      _diario = [result.data!, ..._diario]; // agrega al inicio
      notifyListeners();
      return null;
    }
    return result.error;
  }

  Future<String?> completarReto(int retoId) async {
    final result = await _api.completarReto(retoId);
    if (result.ok) {
      // Reemplaza el reto actualizado en la lista local
      _retos = _retos.map((r) => r.id == retoId ? result.data! : r).toList();
      notifyListeners();

      await SoundService.instance.retoCompletado(); // feedback sonoro

      return null;
    }
    return result.error;
  }

  Future<String?> marcarRecordatorioVisto(int id) async {
    final result = await _api.marcarRecordatorioVisto(id);
    if (result.ok) {
      _recordatorios =
          _recordatorios.map((r) => r.id == id ? result.data! : r).toList();
      notifyListeners();
      return null;
    }
    return result.error;
  }

  Future<String?> registrarVenta({
    required String uid,
    required String producto,
    required int cantidad,
    required double precioUnitario,
    required int totalGanado,
  }) async {
    final result = await _api.crearVenta(
      uid: uid,
      producto: producto,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      totalGanado: totalGanado,
    );
    if (result.ok) {
      _ventas = [result.data!, ..._ventas];
      notifyListeners();

      await SoundService.instance.monedasGanadas(); // feedback sonoro

      return null;
    }
    return result.error;
  }

  Future<String?> agregarCapacitacion({
    required String uid,
    required String nombreCapacitado,
    int? edadCapacitado,
    String? municipio,
    String? estado,
    String? pais,
  }) async {
    final result = await _api.crearCapacitacion(
      uid: uid,
      nombreCapacitado: nombreCapacitado,
      edadCapacitado: edadCapacitado,
      municipio: municipio,
      estado: estado,
      pais: pais,
    );
    if (result.ok) {
      _capacitaciones = [result.data!, ..._capacitaciones];
      notifyListeners();
      return null;
    }
    return result.error;
  }

  /// Limpia el estado al hacer logout
  void limpiar() {
    _usuario = null;
    _diario = [];
    _retos = [];
    _logros = [];
    _recordatorios = [];
    _capacitaciones = [];
    _ventas = [];
    _error = null;
    notifyListeners();
  }
}
