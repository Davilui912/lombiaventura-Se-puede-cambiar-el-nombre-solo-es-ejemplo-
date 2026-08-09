import 'package:hive_flutter/hive_flutter.dart';

class RecordatoriosService {
  static const String _boxName = 'recordatorios';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // Tipos de recordatorio
  final List<Map<String, dynamic>> _recordatoriosBase = [
    // ✅ NOTIFICACIONES DIARIAS (NUEVAS)
    {
      'id': 'alimentar_diario',
      'titulo': '🍎 Alimentar lombrices',
      'mensaje': '¡Es momento de alimentar a tus lombrices! Recuerda darles cáscaras de frutas y verduras en trozos pequeños. 🪱',
      'frecuenciaDias': 7,
      'icono': '🍎',
    },
    {
      'id': 'humedad_diario',
      'titulo': '💧 Revisar humedad',
      'mensaje': 'Revisa la humedad de tu composta. Debe sentirse como una esponja exprimida. Si está seca, rocía un poco de agua. 💦',
      'frecuenciaDias': 1,
      'icono': '💧',
    },
    {
      'id': 'temperatura_diario',
      'titulo': '🌡️ Revisar temperatura',
      'mensaje': 'Revisa la temperatura de tu composta. Debe estar entre 15°C y 25°C. Si hace mucho frío o calor, protégela. 🌤️',
      'frecuenciaDias': 1,
      'icono': '🌡️',
    },
    
    {
      'id': 'olor',
      'titulo': '💧 Mal Olor',
      'mensaje': 'La lombricomposta no tiene malos olores, así que agrega más material seco.',
      'frecuenciaDias': 1,
      'icono': '💧',
    },
    // Recordatorios existentes
    {
      'id': 'insectos',
      'titulo': '💧 Insectos',
      'mensaje': 'Si observas moscas dentro del recipiente, cubrela con una malla.',
      'frecuenciaDias': 1,
      'icono': '💧',
    },
    {
      'id': 'foto',
      'titulo': '📸 Foto de progreso',
      'mensaje': 'Toma una foto de tu composta para ver cómo crece. ¡En unos meses verás el cambio!',
      'frecuenciaDias': 7,
      'icono': '📸',
    },
    {
      'id': 'consejo',
      'titulo': '🌱 Consejo ecológico',
      'mensaje': '¿Sabías que las lombrices pueden comer el tamaño de su peso en un día? ¡Son súper trabajadoras!',
      'frecuenciaDias': 1,
      'icono': '💡',
    },
  ];

  // Obtener recordatorios pendientes para hoy
  List<Map<String, dynamic>> obtenerPendientes() {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    List<Map<String, dynamic>> pendientes = [];

    for (var recordatorio in _recordatoriosBase) {
      final ultimaVez = _box.get('ultimo_${recordatorio['id']}', defaultValue: '');

      if (ultimaVez.isEmpty) {
        pendientes.add(recordatorio);
      } else {
        final ultimaFecha = DateTime.parse(ultimaVez);
        final diferencia = DateTime.now().difference(ultimaFecha).inDays;

        if (diferencia >= (recordatorio['frecuenciaDias'] as int)) {
          pendientes.add(recordatorio);
        }
      }
    }

    return pendientes;
  }

  // Marcar recordatorio como visto
  Future<void> marcarVisto(String id) async {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    await _box.put('ultimo_$id', hoy);
  }

  // Verificar si hay recordatorios pendientes
  bool hayPendientes() {
    return obtenerPendientes().isNotEmpty;
  }

  // Contar pendientes
  int contarPendientes() {
    return obtenerPendientes().length;
  }

  // ✅ Notificación diaria para registrar el diario
  void programarRecordatorioDiario() {
    final hoy = DateTime.now().toString().substring(0, 10);
    final ultimoRecordatorio = _box.get('ultimo_recordatorio_diario', defaultValue: '');

    if (ultimoRecordatorio != hoy) {
      _box.put('ultimo_recordatorio_diario', hoy);

      final pendientes = _box.get('pendientes', defaultValue: <Map<String, dynamic>>[]);
      pendientes.add({
        'id': 'diario_${DateTime.now().millisecondsSinceEpoch}',
        'titulo': '📝 Registra tu diario',
        'mensaje': '¡No olvides registrar cómo va tu composta hoy! Toma una foto y escribe tu nota. 🌱',
        'icono': '📝',
        'fecha': DateTime.now().toIso8601String(),
      });
      _box.put('pendientes', pendientes);
    }
  }

  // ✅ Recordatorio mensual para lixiviado (CORREGIDO)
  void programarRecordatorioLixiviado() {
    final hoy = DateTime.now();
    final dia = hoy.day;
    final mes = hoy.month;
    final anio = hoy.year;  // ✅ Sin ñ

    if (dia == 1) {
      final pendientes = obtenerPendientes();

      final yaEnviado = pendientes.any((item) =>
        item['id'] == 'lixiviado_${mes}_$anio'  // ✅ Interpolación correcta
      );

      if (!yaEnviado) {
        pendientes.add({
          'id': 'lixiviado_${mes}_$anio',  // ✅ Interpolación correcta
          'titulo': '💧 Registrar lixiviado',
          'mensaje': '¡Es momento de revisar y registrar tu lixiviado! Recuerda que solo se produce una vez al mes. Abre "Mi diario" y registra cuántas cucharadas obtuviste. 🌱',
          'icono': '💧',
          'fecha': DateTime.now().toIso8601String(),
        });
        _box.put('pendientes', pendientes);
      }
    }
  }
}