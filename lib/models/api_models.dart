// ============================================================
// 1. USUARIO
// ============================================================
class Usuario {
  final String uid;
  final String nombre;
  final String nombreUsuario;
  final String email;
  final String password;
  final String preguntaSeguridad;
  final String respuestaSeguridad;
  final int? edad;
  final String? ciudad;
  final String? genero;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.nombreUsuario,
    required this.email,
    required this.password,
    required this.preguntaSeguridad,
    required this.respuestaSeguridad,
    this.edad,
    this.ciudad,
    this.genero,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      uid: json['uid'] ?? '',
      nombre: json['nombre'] ?? '',
      nombreUsuario: json['nombre_usuario'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      preguntaSeguridad: json['pregunta_seguridad'] ?? '',
      respuestaSeguridad: json['respuesta_seguridad'] ?? '',
      edad: json['edad'],
      ciudad: json['ciudad'],
      genero: json['genero'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nombre': nombre,
      'nombre_usuario': nombreUsuario,
      'email': email,
      'password': password,
      'pregunta_seguridad': preguntaSeguridad,
      'respuesta_seguridad': respuestaSeguridad,
      if (edad != null) 'edad': edad,
      if (ciudad != null) 'ciudad': ciudad,
      if (genero != null) 'genero': genero,
    };
  }
}

// ============================================================
// 2. ENTRADA DIARIO
// ============================================================
class EntradaDiario {
  final String id;
  final DateTime fecha;
  final String? nota;
  final List<String> fotosRutas;
  final String estado;
  final int? humedad;
  final String? temperatura;
  final String? tipoResiduo;
  final double? produccionComposta;
  final double? produccionLixiviado;
  final String? temperaturaTexto;

  EntradaDiario({
    required this.id,
    required this.fecha,
    this.nota,
    this.fotosRutas = const [],
    this.estado = '😊',
    this.humedad,
    this.temperatura,
    this.tipoResiduo,
    this.produccionComposta,
    this.produccionLixiviado,
    this.temperaturaTexto,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'nota': nota,
      'fotosRutas': fotosRutas,
      'estado': estado,
      'humedad': humedad,
      'temperatura': temperatura,
      'tipoResiduo': tipoResiduo,
      'produccionComposta': produccionComposta,
      'produccionLixiviado': produccionLixiviado,
      'temperaturaTexto': temperaturaTexto,
    };
  }

  factory EntradaDiario.fromJson(Map<String, dynamic> map) {
    return EntradaDiario(
      id: map['id'],
      fecha: DateTime.parse(map['fecha']),
      nota: map['nota'],
      fotosRutas: List<String>.from(map['fotosRutas'] ?? []),
      estado: map['estado'] ?? '😊',
      humedad: map['humedad'],
      temperatura: map['temperatura'],
      tipoResiduo: map['tipoResiduo'],
      produccionComposta: map['produccionComposta']?.toDouble(),
      produccionLixiviado: map['produccionLixiviado']?.toDouble(),
      temperaturaTexto: map['temperaturaTexto'],
    );
  }
}

// ============================================================
// 3. VENTA
// ============================================================
class Venta {
  final String id;
  final String producto;
  final int cantidad;
  final double precioUnitario;
  final int totalGanado;
  final String? descripcion;

  Venta({
    required this.id,
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.totalGanado,
    this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'producto': producto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total_ganado': totalGanado,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'],
      producto: json['producto'],
      cantidad: json['cantidad'],
      precioUnitario: json['precio_unitario']?.toDouble(),
      totalGanado: json['total_ganado'],
      descripcion: json['descripcion'],
    );
  }
}

// ============================================================
// 4. LOGRO
// ============================================================
class Logro {
  final String id;
  final String tipo;
  final String nombre;
  final String? descripcion;

  Logro({
    required this.id,
    required this.tipo,
    required this.nombre,
    this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  factory Logro.fromJson(Map<String, dynamic> json) {
    return Logro(
      id: json['id'],
      tipo: json['tipo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }
}

// ============================================================
// 5. RETO
// ============================================================
class Reto {
  final String id;
  final String retoId;
  final bool completado;
  final int? medicion;
  final String? fotoUrl;

  Reto({
    required this.id,
    required this.retoId,
    required this.completado,
    this.medicion,
    this.fotoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reto_id': retoId,
      'completado': completado,
      if (medicion != null) 'medicion': medicion,
      if (fotoUrl != null) 'foto_url': fotoUrl,
    };
  }

  factory Reto.fromJson(Map<String, dynamic> json) {
    return Reto(
      id: json['id'],
      retoId: json['reto_id'],
      completado: json['completado'] ?? false,
      medicion: json['medicion'],
      fotoUrl: json['foto_url'],
    );
  }
}

// ============================================================
// 6. RECORDATORIO
// ============================================================
class Recordatorio {
  final String id;
  final String titulo;
  final String? mensaje;
  final bool visto;

  Recordatorio({
    required this.id,
    required this.titulo,
    this.mensaje,
    this.visto = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      if (mensaje != null) 'mensaje': mensaje,
      'visto': visto,
    };
  }

  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    return Recordatorio(
      id: json['id'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      visto: json['visto'] ?? false,
    );
  }
}

// ============================================================
// 7. CAPACITACION
// ============================================================
class Capacitacion {
  final String id;
  final String nombreCapacitado;
  final int? edadCapacitado;
  final String? municipio;
  final String? estado;
  final String? pais;
  final String? invitadoPor;
  final int monedasGanadas;

  Capacitacion({
    required this.id,
    required this.nombreCapacitado,
    this.edadCapacitado,
    this.municipio,
    this.estado,
    this.pais,
    this.invitadoPor,
    this.monedasGanadas = 50,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_capacitado': nombreCapacitado,
      if (edadCapacitado != null) 'edad_capacitado': edadCapacitado,
      if (municipio != null) 'municipio': municipio,
      if (estado != null) 'estado': estado,
      if (pais != null) 'pais': pais,
      if (invitadoPor != null) 'invitado_por': invitadoPor,
      'monedas_ganadas': monedasGanadas,
    };
  }

  factory Capacitacion.fromJson(Map<String, dynamic> json) {
    return Capacitacion(
      id: json['id'],
      nombreCapacitado: json['nombre_capacitado'],
      edadCapacitado: json['edad_capacitado'],
      municipio: json['municipio'],
      estado: json['estado'],
      pais: json['pais'],
      invitadoPor: json['invitado_por'],
      monedasGanadas: json['monedas_ganadas'] ?? 50,
    );
  }
}