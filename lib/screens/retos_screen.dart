import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/theme.dart';
import '../services/retos_service.dart';
import '../models/reto.dart';
import '../services/recordatorios_service.dart';

class RetosScreen extends StatefulWidget {
  const RetosScreen({super.key});

  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  final RetosService _retosService = RetosService();
  List<Reto> _retos = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _ultimaFoto;

  @override
  void initState() {
    super.initState();
    _cargarRetos();
  }

  Future<void> _cargarRetos() async {
    await _retosService.init();
    setState(() {
      _retos = _retosService.obtenerRetos();
      _isLoading = false;
    });
  }

  Future<bool> _tomarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (foto != null) {
        setState(() {
          _ultimaFoto = File(foto.path);
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error al tomar foto: $e');
      return false;
    }
  }

  Future<void> _completarReto(Reto reto) async {
    final hoy = DateTime.now();
    final esDia1 = hoy.day == 1;

    if (reto.id == 'reto_humus' || reto.id == 'reto_lixiviado') {
      if (!esDia1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📅 Este reto solo está disponible el día 1 de cada mes'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (reto.id == 'reto_1') {
      _mostrarDialogoLombrices(reto);
    } else if (reto.id == 'reto_2') {
      _mostrarDialogoEcosistema(reto);
    } else if (reto.id == 'reto_humus') {
      _mostrarDialogoHumus(reto);
    } else if (reto.id == 'reto_lixiviado') {
      _mostrarDialogoLixiviado(reto);
    }
  }

  void _mostrarDialogoLombrices(Reto reto) {
    if (_retosService.estaCompletado('reto_1')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Ya completaste este reto!'),
          backgroundColor: AppTheme.verde,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🎯 ${reto.titulo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reto.descripcion),
            const SizedBox(height: 16),
            const Text(
              '¿Ya tienes lombrices?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mostrarCuantasLombrices(reto);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.verde,
                    ),
                    child: const Text('Sí'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Primero consigue lombrices y luego regresa 🪱'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCuantasLombrices(Reto reto) {
    int cantidad = 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('¿Cuántas lombrices tienes?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 40),
                      onPressed: () {
                        setState(() {
                          if (cantidad > 0) cantidad--;
                        });
                      },
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.verde),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 40),
                      onPressed: () {
                        setState(() {
                          cantidad++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cantidad == 0 ? 'Necesitas al menos 1 lombriz' : '¡Perfecto! $cantidad lombriz(es)',
                  style: TextStyle(
                    color: cantidad > 0 ? AppTheme.verde : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: cantidad > 0
                    ? () async {
                        Navigator.pop(ctx);
                        await _retosService.completarReto(reto.id);
                        _cargarRetos();
                        
                        if (reto.id == 'reto_1') {
                          final recordatorioService = RecordatoriosService();
                          await recordatorioService.init();
                          recordatorioService.programarRecordatorioDiario();
                          recordatorioService.programarRecordatorioLixiviado();
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 ¡Reto completado!'),
                            backgroundColor: AppTheme.verde,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cantidad > 0 ? AppTheme.verde : Colors.grey,
                ),
                child: Text(
                  cantidad > 0 ? 'Completar reto' : 'Agrega lombrices',
                  style: TextStyle(
                    color: cantidad > 0 ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogoHumus(Reto reto) {
    int punos = 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🌱 ${reto.titulo}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, size: 48, color: AppTheme.verde),
                const SizedBox(height: 16),
                const Text(
                  'Toma una foto de tu humus',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Cuántos punos de humus produjiste?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 40),
                      onPressed: () {
                        setState(() {
                          if (punos > 0) punos--;
                        });
                      },
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.verde),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$punos',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 40),
                      onPressed: () {
                        setState(() {
                          punos++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  punos == 0 ? 'Mide los punos de humus' : '$punos puño(s) de humus',
                  style: TextStyle(
                    color: punos > 0 ? AppTheme.verde : Colors.grey,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: punos > 0
                ? () async {
                    Navigator.pop(ctx);
                    await _retosService.completarReto(reto.id);
                    _cargarRetos();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 ¡Reto de humus completado!'),
                        backgroundColor: AppTheme.verde,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verde,
            ),
            child: const Text('Completar reto'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLixiviado(Reto reto) {
    int cucharadas = 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('💧 ${reto.titulo}'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt, size: 48, color: AppTheme.verde),
                const SizedBox(height: 16),
                const Text(
                  'Toma una foto de tu lixiviado',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Cuántas cucharadas de lixiviado recolectaste?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 40),
                      onPressed: () {
                        setState(() {
                          if (cucharadas > 0) cucharadas--;
                        });
                      },
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.verde),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cucharadas',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 40),
                      onPressed: () {
                        setState(() {
                          cucharadas++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cucharadas == 0 ? 'Mide las cucharadas de lixiviado' : '$cucharadas cucharada(s) de lixiviado',
                  style: TextStyle(
                    color: cucharadas > 0 ? AppTheme.verde : Colors.grey,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: cucharadas > 0
                ? () async {
                    Navigator.pop(ctx);
                    await _retosService.completarReto(reto.id);
                    _cargarRetos();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 ¡Reto de lixiviado completado!'),
                        backgroundColor: AppTheme.verde,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verde,
            ),
            child: const Text('Completar reto'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEcosistema(Reto reto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('📸 ${reto.titulo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 48, color: AppTheme.verde),
            const SizedBox(height: 16),
            const Text(
              'Toma una foto de tu contenedor de lombrices',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Asegúrate de que se vea bien el contenedor',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_ultimaFoto != null) ...[
              const SizedBox(height: 8),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_ultimaFoto!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final fotoTomada = await _tomarFoto();
              if (fotoTomada) {
                await _retosService.completarReto(reto.id);
                _cargarRetos();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 ¡Reto completado con foto!'),
                      backgroundColor: AppTheme.verde,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verde,
            ),
            child: const Text('📸 Tomar foto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Muestra de mi negocio'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progreso
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.verde.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.verde),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progreso',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_retosService.obtenerProgreso()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.verde,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _retosService.obtenerProgreso() / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.verde),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Lista de retos
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _retos.length,
                        itemBuilder: (context, index) {
                          final reto = _retos[index];
                          final completado = reto.completado;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: completado
                                      ? AppTheme.verde.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    completado ? '✅' : reto.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              title: Text(
                                '${reto.orden}. ${reto.titulo}',
                                style: TextStyle(
                                  fontWeight: completado ? FontWeight.normal : FontWeight.bold,
                                  color: completado ? Colors.grey : AppTheme.negro,
                                  decoration: completado ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                completado ? '¡Completado! 🎉' : reto.descripcion,
                                style: TextStyle(
                                  color: completado ? AppTheme.verde : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: completado
                                  ? const Icon(Icons.check_circle, color: AppTheme.verde)
                                  : IconButton(
                                      icon: const Icon(Icons.play_arrow, color: AppTheme.verde),
                                      onPressed: () => _completarReto(reto),
                                    ),
                              onTap: completado ? null : () => _completarReto(reto),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}