import 'package:flutter/material.dart';
import '../../services/monedas_service.dart';

class VentasHistorialScreen extends StatefulWidget {
  const VentasHistorialScreen({super.key});

  @override
  State<VentasHistorialScreen> createState() => _VentasHistorialScreenState();
}

class _VentasHistorialScreenState extends State<VentasHistorialScreen> {
  final MonedasService _monedasService = MonedasService();
  List<Map<String, dynamic>> _historial = [];
  int _totalGanado = 0;
  int _totalVentas = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    
    try {
      await _monedasService.init();
      
      final historialCompleto = _monedasService.obtenerHistorialVentas();
      
      final ventas = historialCompleto.where((item) => 
        (item['descripcion'] as String).contains('Vendiste')
      ).toList();
      
      setState(() {
        _historial = ventas;
        _totalGanado = ventas.fold(0, (sum, item) => sum + (item['cantidad'] as int));
        _totalVentas = ventas.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando historial: $e');
      setState(() {
        _historial = [];
        _totalGanado = 0;
        _totalVentas = 0;
        _isLoading = false;
      });
    }
  }

  String _extraerCantidad(String descripcion) {
    final parts = descripcion.split(' ');
    for (var part in parts) {
      final numero = int.tryParse(part);
      if (numero != null) {
        return part;
      }
    }
    return '?';
  }

  String _obtenerProducto(String descripcion) {
    if (descripcion.contains('lombriz')) {
      return '🪱 Lombrices';
    } else if (descripcion.contains('atomizador')) {
      return '💧 Atomizador lixiviado';
    } else if (descripcion.contains('humus')) {
      return '🌱 Bolsita de humus';
    } else {
      return '📦 Producto';
    }
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha desconocida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Ventas y ganancias'),
        backgroundColor: Colors.orange,
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
                      // Resumen de ventas y ganancias
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.orange.shade400, Colors.orange.shade700],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Ventas totales
                            Column(
                              children: [
                                const Text(
                                  '📦 Ventas',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_totalVentas',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // Ganancias totales
                            Column(
                              children: [
                                const Text(
                                  '💰 Ganancias',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$$_totalGanado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Lista de ventas con detalles
                      if (_historial.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay ventas registradas aún.\n¡Vende lombrices, atomizadores o humus!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _historial.length,
                          itemBuilder: (context, index) {
                            final venta = _historial[index];
                            final cantidadGanada = venta['cantidad'] as int;
                            final descripcion = venta['descripcion'] as String;
                            final producto = _obtenerProducto(descripcion);
                            final cantidadVendida = _extraerCantidad(descripcion);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                  child: const Icon(Icons.attach_money, color: Colors.orange),
                                ),
                                title: Text(producto),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatearFecha(venta['fecha']),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (cantidadVendida != '?')
                                      Text(
                                        'Cantidad: $cantidadVendida',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+\$$cantidadGanada',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Ganancia: \$$cantidadGanada',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
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