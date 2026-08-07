import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/theme.dart';
import '../../services/monedas_service.dart';

class CapacitacionScreen extends StatefulWidget {
  const CapacitacionScreen({super.key});

  @override
  State<CapacitacionScreen> createState() => _CapacitacionScreenState();
}

class _CapacitacionScreenState extends State<CapacitacionScreen> {
  final MonedasService _monedasService = MonedasService();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _paisController = TextEditingController();
  final TextEditingController _invitadoPorController = TextEditingController();
  
  List<Map<String, dynamic>> _capacitados = [];
  int _totalGanado = 0;
  int _monedas = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await _monedasService.init();
    await _cargarCapacitados();
    
    setState(() {
      _monedas = _monedasService.obtenerMonedas();
      _calcularTotalGanado();
    });
  }

  Future<void> _cargarCapacitados() async {
    try {
      final box = await Hive.openBox('capacitaciones');
      final rawList = box.get('capacitados', defaultValue: <Map<String, dynamic>>[]);
      
      // ✅ CONVERTIR CORRECTAMENTE CADA MAP
      final List<Map<String, dynamic>> listaConvertida = [];
      for (var item in rawList) {
        if (item is Map) {
          final map = <String, dynamic>{};
          item.forEach((key, value) {
            map[key.toString()] = value;
          });
          listaConvertida.add(map);
        }
      }
      
      setState(() {
        _capacitados = listaConvertida;
      });
      print('📊 Capacitados cargados: ${_capacitados.length}');
    } catch (e) {
      print('❌ Error cargando capacitados: $e');
      setState(() {
        _capacitados = [];
      });
    }
  }

  void _calcularTotalGanado() {
    _totalGanado = _capacitados.length * 50;
  }

  Future<void> _guardarCapacitado() async {
    // Validar campos
    if (_nombreController.text.trim().isEmpty) {
      _mostrarError('Ingresa el nombre completo');
      return;
    }
    if (_edadController.text.trim().isEmpty) {
      _mostrarError('Ingresa la edad');
      return;
    }
    if (_municipioController.text.trim().isEmpty) {
      _mostrarError('Ingresa el municipio');
      return;
    }
    if (_estadoController.text.trim().isEmpty) {
      _mostrarError('Ingresa el estado');
      return;
    }
    if (_paisController.text.trim().isEmpty) {
      _mostrarError('Ingresa el país');
      return;
    }

    try {
      // ✅ 1. Crear el objeto capacitado
      final nuevoCapacitado = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'edad': _edadController.text.trim(),
        'municipio': _municipioController.text.trim(),
        'estado': _estadoController.text.trim(),
        'pais': _paisController.text.trim(),
        'invitadoPor': _invitadoPorController.text.trim().isEmpty ? 'Nadie' : _invitadoPorController.text.trim(),
        'fecha': DateTime.now().toIso8601String(),
      };

      // ✅ 2. Guardar en Hive
      final box = await Hive.openBox('capacitaciones');
      
      // ✅ Obtener lista existente y convertir correctamente
      final rawList = box.get('capacitados', defaultValue: <Map<String, dynamic>>[]);
      final List<Map<String, dynamic>> lista = [];
      for (var item in rawList) {
        if (item is Map) {
          final map = <String, dynamic>{};
          item.forEach((key, value) {
            map[key.toString()] = value;
          });
          lista.add(map);
        }
      }
      
      // ✅ Agregar nuevo
      lista.add(nuevoCapacitado);
      
      // ✅ Guardar lista actualizada
      await box.put('capacitados', lista);
      print('✅ Capacitado guardado: ${nuevoCapacitado['nombre']}');

      // ✅ 3. Dar monedas
      await _monedasService.agregarMonedas(50);
      
      // ✅ 4. Limpiar formulario
      _nombreController.clear();
      _edadController.clear();
      _municipioController.clear();
      _estadoController.clear();
      _paisController.clear();
      _invitadoPorController.clear();

      // ✅ 5. Recargar datos
      await _cargarCapacitados();
      
      setState(() {
        _monedas = _monedasService.obtenerMonedas();
        _calcularTotalGanado();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Capacitación registrada! Ganaste 50 monedas 🪙'),
          backgroundColor: AppTheme.verde,
        ),
      );
    } catch (e) {
      print('❌ Error al guardar capacitado: $e');
      _mostrarError('Error al guardar. Intenta de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 Capacitación'),
        backgroundColor: Colors.orange,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB8860B),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFB8860B),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: const Color(0xFFB8860B),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_monedas',
                    style: const TextStyle(
                      color: Color(0xFF7B5100),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange,
                      width: 2,
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_add), text: 'Registrar'),
                    Tab(icon: Icon(Icons.history), text: 'Historial'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Pestaña Registrar
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade700,
                                  ],
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
                              child: const Column(
                                children: [
                                  Icon(Icons.school, size: 48, color: Colors.white),
                                  SizedBox(height: 8),
                                  Text(
                                    '🌟 ¡Comparte tu conocimiento!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Capacita a otros niños y gana 50 monedas por cada uno 🪙',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '📝 Datos del capacitado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cafe,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildCampo('👤 Nombre completo', _nombreController, Icons.person),
                            const SizedBox(height: 12),
                            _buildCampo('🎂 Edad', _edadController, Icons.cake, keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            _buildCampo('📍 Municipio', _municipioController, Icons.location_city),
                            const SizedBox(height: 12),
                            _buildCampo('🗺️ Estado', _estadoController, Icons.map),
                            const SizedBox(height: 12),
                            _buildCampo('🌍 País', _paisController, Icons.public),
                            const SizedBox(height: 12),
                            _buildCampo('👥 ¿Quién te invitó? (Opcional)', _invitadoPorController, Icons.people),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _guardarCapacitado,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.orange.withValues(alpha: 0.3),
                                ),
                                child: const Text(
                                  '🎓 Registrar capacitación',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Pestaña Historial
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: _capacitados.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    '📭 No hay capacitaciones registradas aún',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '¡Comienza a capacitar y gana monedas! 🪙',
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            const Text(
                                              '🎓 Capacitados',
                                              style: TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            Text(
                                              '${_capacitados.length}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey.shade300,
                                        ),
                                        Column(
                                          children: [
                                            const Text(
                                              '🪙 Monedas ganadas',
                                              style: TextStyle(fontSize: 14, color: Colors.grey),
                                            ),
                                            Text(
                                              '${_capacitados.length * 50}',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _capacitados.length,
                                    itemBuilder: (context, index) {
                                      final item = _capacitados[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.orange.withValues(alpha: 0.2),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            item['nombre'],
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text(
                                            '${item['edad']} años • ${item['municipio']}, ${item['estado']}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.amber.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.monetization_on,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '+50',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.amber,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}