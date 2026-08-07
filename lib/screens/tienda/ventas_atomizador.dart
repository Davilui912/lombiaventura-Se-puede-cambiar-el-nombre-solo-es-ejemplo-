import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/monedas_service.dart';

class VentasAtomizadorScreen extends StatefulWidget {
  const VentasAtomizadorScreen({super.key});

  @override
  State<VentasAtomizadorScreen> createState() => _VentasAtomizadorScreenState();
}

class _VentasAtomizadorScreenState extends State<VentasAtomizadorScreen> {
  final MonedasService _monedasService = MonedasService();
  int _cantidad = 1;
  int _monedas = 0;

  @override
  void initState() {
    super.initState();
    _cargarMonedas();
  }

  Future<void> _cargarMonedas() async {
    await _monedasService.init();
    setState(() {
      _monedas = _monedasService.obtenerMonedas();
    });
  }

  Future<void> _vender() async {
    final cantidad = _cantidad;
    final precioTotal = cantidad * 25;
    
    await _monedasService.agregarMonedas(precioTotal);
    await _monedasService.agregarVenta(
      cantidad: precioTotal,
      descripcion: 'Vendiste $cantidad atomizador(es) 💧',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Vendiste $cantidad atomizador(es)! Ganaste $precioTotal monedas 🪙'),
          backgroundColor: AppTheme.verde,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vender lixiviado'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💧', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text(
                  'Precio: \$25 c/u',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text('Cantidad a vender:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, size: 40),
                      onPressed: () => setState(() {
                        if (_cantidad > 1) _cantidad--;
                      }),
                    ),
                    Container(
                      width: 80,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_cantidad',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 40),
                      onPressed: () => setState(() => _cantidad++),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Total: \$${_cantidad * 25} MXN',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _vender,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Registrar venta',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}