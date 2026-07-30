import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/monedas_service.dart';
import '../../services/diario_service.dart';
import '../../services/sound_service.dart';

class NuevaEntradaScreen extends StatefulWidget {
  const NuevaEntradaScreen({super.key});

  @override
  State<NuevaEntradaScreen> createState() => _NuevaEntradaScreenState();
}

class _NuevaEntradaScreenState extends State<NuevaEntradaScreen> {
  final DiarioService _diarioService = DiarioService();
  final TextEditingController _notaController = TextEditingController();

  // Temperatura y Humedad
  int _humedad = 5;
  int _temperaturaValor = 5; // 1 al 10 en el Slider
  String _temperaturaSeleccionada = '🌤️ Buen clima';

  // ✅ Composta y Lixiviado (Declarados solo una vez)
  final TextEditingController _compostaController = TextEditingController();
  final TextEditingController _lixiviadoController = TextEditingController();
  bool _mostrarComposta = false;
  bool _mostrarLixiviado = false;

  // ✅ Tipo de residuo
  String _tipoResiduo = 'Mixto';
  final List<String> _tiposResiduo = [
    'Frutas',
    'Verduras',
    'Cáscaras',
    'Café',
    'Mixto'
  ];

  // ✅ Estado de ánimo
  String _estadoSeleccionado = '😊';
  final List<Map<String, String>> _estados = [
    {'emoji': '😊', 'label': '¡Excelente!'},
    {'emoji': '😐', 'label': 'Regular'},
    {'emoji': '😟', 'label': 'Necesita ayuda'},
  ];

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _verificarDiaMes();
  }

  void _verificarDiaMes() {
    final hoy = DateTime.now();
    // ✅ Composta y Lixiviado solo el día 1 del mes
    if (hoy.day == 1) {
      _mostrarComposta = true;
      _mostrarLixiviado = true;
    } else {
      _mostrarComposta = false;
      _mostrarLixiviado = false;
    }
  }

  @override
  void dispose() {
    _notaController.dispose();
    _compostaController.dispose();
    _lixiviadoController.dispose();
    super.dispose();
  }

  Future<void> _guardarEntrada() async {
    if (_notaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📝 Escribe qué le diste de comer a tus lombrices'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    await _diarioService.guardarEntrada(
      fotosRutas: [], // ✅ Sin fotos
      nota: _notaController.text.isNotEmpty ? _notaController.text : null,
      estado: _estadoSeleccionado,
      humedad: null, // ✅ Sin humedad enviada en este formato antiguo
      temperaturaTexto: _temperaturaSeleccionada,
      tipoResiduo: _tipoResiduo,
      produccionComposta:
          _mostrarComposta && _compostaController.text.isNotEmpty
              ? double.tryParse(_compostaController.text)
              : null,
      produccionLixiviado:
          _mostrarLixiviado && _lixiviadoController.text.isNotEmpty
              ? double.tryParse(_lixiviadoController.text)
              : null,
    );

    await MonedasService().ganarPorActividad('diario');

    if (mounted) {
      SoundService.instance.monedasGanadas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Entrada guardada! +5 monedas 🪙'),
          backgroundColor: AppTheme.verde,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final esDia1 = hoy.day == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Nueva entrada'),
        backgroundColor: AppTheme.verde,
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardarEntrada,
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Estado de ánimo
                const Text('🌱 ¿Cómo va?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _estados.map((estado) {
                    final sel = _estadoSeleccionado == estado['emoji'];
                    return GestureDetector(
                      onTap: () => setState(
                          () => _estadoSeleccionado = estado['emoji']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.verde.withValues(alpha: 0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? AppTheme.verde : Colors.grey[300]!,
                              width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(estado['emoji']!,
                                style: const TextStyle(fontSize: 30)),
                            Text(estado['label']!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: sel
                                        ? AppTheme.verde
                                        : Colors.grey[600])),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ✅ "¿Qué le di de comer?"
                const Text('🍽️ ¿Qué le di de comer?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 10),
                TextField(
                  controller: _notaController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Ej: Hoy les di cáscaras de plátano, manzana y restos de café ☕',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Tipo de residuo
                const Text('🍎 Tipo de residuo',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tiposResiduo.map((tipo) {
                    final sel = _tipoResiduo == tipo;
                    return ChoiceChip(
                      label: Text(tipo,
                          style: const TextStyle(color: Colors.black)),
                      selected: sel,
                      selectedColor: AppTheme.verde.withValues(alpha: 0.3),
                      onSelected: (_) => setState(() => _tipoResiduo = tipo),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Humedad
                const Text('💧 Humedad',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Seco',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: _humedad.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: AppTheme.verde,
                        label: '$_humedad/10',
                        onChanged: (val) =>
                            setState(() => _humedad = val.round()),
                      ),
                    ),
                    const Text('Empapado',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Center(
                  child: Text(
                    _humedad <= 3
                        ? '🟡 Muy seco'
                        : _humedad <= 6
                            ? '🟢 Ideal'
                            : _humedad <= 8
                                ? '🟡 Húmedo'
                                : '🔴 Muy mojado',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                const SizedBox(height: 12),

                // Temperatura
                const Text('🌡️ Temperatura',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Frío',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Expanded(
                      child: Slider(
                        value: _temperaturaValor.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: AppTheme.verde,
                        label: '$_temperaturaValor/10',
                        onChanged: (val) {
                          setState(() {
                            _temperaturaValor = val.round();
                            // Actualiza el texto según el valor del Slider para pasarlo al backend
                            if (_temperaturaValor <= 3) {
                              _temperaturaSeleccionada = '❄️ Frío';
                            } else if (_temperaturaValor <= 6)
                              _temperaturaSeleccionada = '🌤️ Buen clima';
                            else
                              _temperaturaSeleccionada = '☀️ Caliente';
                          });
                        },
                      ),
                    ),
                    const Text('Caliente',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Center(
                  child: Text(
                    _temperaturaValor <= 3
                        ? '🟡 Muy frio'
                        : _temperaturaValor <= 6
                            ? '🟢 Ideal'
                            : _temperaturaValor <= 8
                                ? '🟡 Caliente'
                                : '🔴 Muy caliente',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                // ✅ Mensaje informativo si NO es día 1
                if (!esDia1) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '📅 La composta y el lixiviado se registran el día 1 de cada mes.',
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ✅ Campos de composta y lixiviado (solo día 1)
                if (esDia1) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    '📊 Registro mensual',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solo disponible el día 1 de cada mes',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Composta
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🪱 Composta (puños)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.cafe)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _compostaController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ej: 2',
                                suffixText: 'puos',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Lixiviado
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💧 Lixiviado (cuch.)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.cafe)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _lixiviadoController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Ej: 3',
                                suffixText: 'cuch.',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 30),

                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarEntrada,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.verde,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(color: Colors.white))
                        : const Text('💾 Guardar entrada',
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
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
