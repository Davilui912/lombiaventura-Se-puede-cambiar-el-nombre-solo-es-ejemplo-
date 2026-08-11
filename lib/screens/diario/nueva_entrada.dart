import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/actividad_service.dart';
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

  // Temperatura y Humedad
  int _humedad = 5;
  int _temperaturaValor = 5;
  String _temperaturaSeleccionada = '🌤️ Buen clima';

  // ✅ Nuevos campos para moscas y mal olor
  bool _tieneMoscas = false;
  bool _tieneMalOlor = false;

  // ✅ Tipo de residuo (múltiple selección)
  final List<String> _tiposResiduo = [
    'Frutas',
    'Verduras',
    'Cáscaras',
    'Café',
    'Hojas',
    'Estiércol'
  ];
  final List<bool> _tiposSeleccionados = [];

  // ✅ Estado de ánimo
  String _estadoSeleccionado = '😊';
  final List<Map<String, String>> _estados = [
    {'emoji': '😊', 'label': '¡Excelente!'},
    {'emoji': '😐', 'label': 'Regular'},
    {'emoji': '😟', 'label': 'Necesita ayuda'},
  ];

  bool _guardando = false;

  // ✅ Control de días para alimentación, composta y lixiviado
  int _diasDesdeUltimaAlimentacion = 0;
  int _diasDesdeUltimaCompostaLixiviado = 0;

  @override
  void initState() {
    super.initState();
    _inicializarTipos();
    _calcularDias();
  }

  void _inicializarTipos() {
    _tiposSeleccionados.clear();
    for (var i = 0; i < _tiposResiduo.length; i++) {
      _tiposSeleccionados.add(false);
    }
  }

  void _calcularDias() {
    _diasDesdeUltimaAlimentacion = 5; // Ejemplo
    _diasDesdeUltimaCompostaLixiviado = 45; // Ejemplo
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _guardarEntrada() async {
    // ✅ Validar si tiene moscas y mostrar advertencia
    if (_tieneMoscas) {
      _mostrarDialogoMoscas();
      return;
    }

    // ✅ Validar si tiene mal olor y mostrar advertencia
    if (_tieneMalOlor) {
      _mostrarDialogoMalOlor();
      return;
    }

    // ✅ Verificar que al menos un tipo de residuo esté seleccionado
    final tiposSeleccionados = _obtenerTiposSeleccionados();
    if (tiposSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecciona al menos un tipo de residuo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    await _diarioService.guardarEntrada(
      fotosRutas: [],
      nota: 'Alimentación registrada',
      estado: _estadoSeleccionado,
      humedad: null,
      temperaturaTexto: _temperaturaSeleccionada,
      tipoResiduo: tiposSeleccionados.join(', '),
      produccionComposta: null,
      produccionLixiviado: null,
    );

    await ActividadService().registrarActividad();
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

  List<String> _obtenerTiposSeleccionados() {
    final tipos = <String>[];
    for (var i = 0; i < _tiposResiduo.length; i++) {
      if (_tiposSeleccionados[i]) {
        tipos.add(_tiposResiduo[i]);
      }
    }
    return tipos;
  }

  void _mostrarDialogoMoscas() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🪰 ¡Moscas detectadas!'),
        content: const Text(
          'Cubrela con una malla para que no entren más moscas.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _tieneMoscas = false);
            },
            child: const Text('✅ Corregir'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoMalOlor() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('👃 ¡Mal olor detectado!'),
        content: const Text(
          'Agrega más material seco (hojas secas, cartón, aserrín) para equilibrar.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _tieneMalOlor = false);
            },
            child: const Text('✅ Corregir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool puedeAlimentar = _diasDesdeUltimaAlimentacion >= 7;
    final bool puedeCompostaLixiviado = _diasDesdeUltimaCompostaLixiviado >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Mi diario'),
        backgroundColor: AppTheme.verde,
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

                // ✅ Tipo de residuo (MÚLTIPLE SELECCIÓN)
                const Text('🍎 Tipo de residuo (puedes seleccionar varios)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_tiposResiduo.length, (index) {
                    return FilterChip(
                      label: Text(
                        _tiposResiduo[index],
                        style: TextStyle(
                          color: _tiposSeleccionados[index]
                              ? AppTheme.verde
                              : Colors.black87,
                          fontWeight: _tiposSeleccionados[index]
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: _tiposSeleccionados[index],
                      onSelected: (selected) {
                        setState(() {
                          _tiposSeleccionados[index] = selected;
                        });
                      },
                      selectedColor: AppTheme.verde.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.verde,
                      backgroundColor: Colors.grey.shade50,
                      side: BorderSide(
                        color: _tiposSeleccionados[index]
                            ? AppTheme.verde
                            : Colors.grey.shade300,
                        width: _tiposSeleccionados[index] ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // ✅ MOSCAS
                const Text('🪰 ¿Hay moscas dentro del recipiente?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tieneMoscas = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_tieneMoscas
                                ? AppTheme.verde.withValues(alpha: 0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_tieneMoscas
                                  ? AppTheme.verde
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon(
                              //   Icons.check_circle,
                              //   color: !_tieneMoscas
                              //       ? AppTheme.verde
                              //       : Colors.grey.shade400,
                              //   size: 20,
                              // ),
                              const SizedBox(width: 8),
                              Text(
                                'No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_tieneMoscas
                                      ? AppTheme.verde
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _tieneMoscas = true);
                          _mostrarDialogoMoscas();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tieneMoscas
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tieneMoscas
                                  ? Colors.red
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon(
                              //   Icons.cancel,
                              //   color: _tieneMoscas
                              //       ? Colors.red
                              //       : Colors.grey.shade400,
                              //   size: 20,
                              // ),
                              const SizedBox(width: 8),
                              Text(
                                'Sí',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tieneMoscas
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_tieneMoscas)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '💡 Cubrela con una malla para que no entren más moscas.',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ✅ MAL OLOR
                const Text('👃 ¿Tiene mal olor?',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cafe)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tieneMalOlor = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_tieneMalOlor
                                ? AppTheme.verde.withValues(alpha: 0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_tieneMalOlor
                                  ? AppTheme.verde
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon(
                              //   Icons.check_circle,
                              //   color: !_tieneMalOlor
                              //       ? AppTheme.verde
                              //       : Colors.grey.shade400,
                              //   size: 20,
                              // ),
                              const SizedBox(width: 8),
                              Text(
                                'No',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_tieneMalOlor
                                      ? AppTheme.verde
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _tieneMalOlor = true);
                          _mostrarDialogoMalOlor();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tieneMalOlor
                                ? Colors.red.withValues(alpha: 0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tieneMalOlor
                                  ? Colors.red
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon(
                              //   Icons.cancel,
                              //   color: _tieneMalOlor
                              //       ? Colors.red
                              //       : Colors.grey.shade400,
                              //   size: 20,
                              // ),
                              const SizedBox(width: 8),
                              Text(
                                'Sí',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _tieneMalOlor
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_tieneMalOlor)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '💡 Agrega más material seco (hojas secas, cartón, aserrín) para equilibrar.',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ✅ Alimentación cada 7 días
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: puedeAlimentar
                        ? AppTheme.verde.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: puedeAlimentar
                          ? AppTheme.verde.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        puedeAlimentar
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: puedeAlimentar ? AppTheme.verde : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🍽️ Alimentación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: puedeAlimentar
                                    ? AppTheme.verde
                                    : Colors.orange,
                              ),
                            ),
                            Text(
                              puedeAlimentar
                                  ? '✅ ¡Puedes alimentar a tus lombrices hoy!'
                                  : '⏳ Próxima alimentación en ${7 - _diasDesdeUltimaAlimentacion} días',
                              style: TextStyle(
                                fontSize: 12,
                                color: puedeAlimentar
                                    ? AppTheme.verde
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Composta y Lixiviado cada 2 meses
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: puedeCompostaLixiviado
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: puedeCompostaLixiviado
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        puedeCompostaLixiviado
                            ? Icons.check_circle
                            : Icons.calendar_today,
                        color:
                            puedeCompostaLixiviado ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📊 Composta y Lixiviado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: puedeCompostaLixiviado
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                            Text(
                              puedeCompostaLixiviado
                                  ? '✅ ¡Ya puedes registrar tu composta y lixiviado!'
                                  : '⏳ Próximo registro en ${60 - _diasDesdeUltimaCompostaLixiviado} días',
                              style: TextStyle(
                                fontSize: 12,
                                color: puedeCompostaLixiviado
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Humedad
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

                // ✅ Temperatura
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
                            if (_temperaturaValor <= 3) {
                              _temperaturaSeleccionada = '❄️ Frío';
                            } else if (_temperaturaValor <= 6) {
                              _temperaturaSeleccionada = '🌤️ Buen clima';
                            } else {
                              _temperaturaSeleccionada = '☀️ Caliente';
                            }
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
