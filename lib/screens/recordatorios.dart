import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/recordatorios_service.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  late RecordatoriosService _service;
  List<Map<String, dynamic>> _pendientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializarServicio();
  }

  Future<void> _inicializarServicio() async {
    _service = RecordatoriosService();
    await _service.init();
    _cargarPendientes();
  }

  void _cargarPendientes() {
    setState(() {
      _pendientes = _service.obtenerPendientes();
      _isLoading = false;
    });
  }

  Future<void> _marcarVisto(String id) async {
    await _service.marcarVisto(id);
    _cargarPendientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏰ Recordatorios'),
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
            : _pendientes.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 30),
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
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppTheme.verde),
                          SizedBox(height: 16),
                          Text(
                            '¡No hay recordatorios pendientes!',
                            style: TextStyle(fontSize: 18, color: AppTheme.verde),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendientes.length,
                            itemBuilder: (context, index) {
                              final item = _pendientes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Text(
                                    item['icono'] ?? '📌',
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  title: Text(
                                    item['titulo'] ?? 'Recordatorio',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(item['mensaje'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.check_circle, color: AppTheme.verde),
                                    onPressed: () => _marcarVisto(item['id']),
                                  ),
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