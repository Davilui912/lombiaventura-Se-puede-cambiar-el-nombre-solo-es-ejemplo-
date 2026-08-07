import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/logros_service.dart';

class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  final LogrosService _logrosService = LogrosService();
  List<Map<String, dynamic>> _insignias = [];
  int _estrellas = 0;
  int _ganadas = 0;
  int _total = 0;
  bool _ecoHeroe = false;

  @override
  void initState() {
    super.initState();
    _cargarLogros();
  }

  void _cargarLogros() {
    setState(() {
      _insignias = _logrosService.obtenerInsignias();
      _estrellas = _logrosService.obtenerEstrellas();
      _ganadas = _logrosService.contarInsigniasGanadas();
      _total = _logrosService.totalInsignias;
      _ecoHeroe = _logrosService.esEcoHeroe();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Mis Logros'),
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
        child: SingleChildScrollView(
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
                _buildCabecera(),
                const SizedBox(height: 20),
                _buildProgreso(),
                const SizedBox(height: 20),
                _buildSeccionInsignias(),
                const SizedBox(height: 20),
                if (_ecoHeroe) _buildCertificado(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCabecera() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.amarillo, AppTheme.amarillo.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.amarillo.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_estrellas',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: AppTheme.cafe,
                ),
              ),
              const Text(
                'Estrellas ganadas',
                style: TextStyle(fontSize: 14, color: AppTheme.cafe),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgreso() {
    final porcentaje = _total > 0 ? _ganadas / _total : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Fredoka'),
              ),
              Text(
                '$_ganadas de $_total',
                style: const TextStyle(fontSize: 16, color: AppTheme.cafe),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 20,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.verde),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(porcentaje * 100).toInt()}% completado',
            style: const TextStyle(fontSize: 14, color: AppTheme.cafe),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionInsignias() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏅 Insignias',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Fredoka', color: AppTheme.cafe),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _insignias.length,
          itemBuilder: (context, index) {
            return _buildInsignia(_insignias[index]);
          },
        ),
      ],
    );
  }

  Widget _buildInsignia(Map<String, dynamic> insignia) {
    final ganada = insignia['ganada'] == true;

    return Container(
      decoration: BoxDecoration(
        color: ganada ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: ganada ? AppTheme.verde : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: ganada
            ? [BoxShadow(color: AppTheme.verde.withValues(alpha: 0.2), blurRadius: 6)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ganada ? insignia['emoji'] : '🔒',
            style: TextStyle(fontSize: 35, color: ganada ? null : Colors.grey[400]),
          ),
          const SizedBox(height: 6),
          Text(
            insignia['nombre'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ganada ? AppTheme.cafe : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ganada ? '¡Ganada!' : 'Bloqueada',
            style: TextStyle(
              fontSize: 9,
              color: ganada ? AppTheme.verde : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificado() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.verde, AppTheme.azulCielo],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.verde.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 10),
          const Text(
            '¡CERTIFICADO!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Fredoka',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Eco Héroe',
            style: TextStyle(fontSize: 22, color: AppTheme.amarillo, fontFamily: 'Fredoka'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '¡Felicitaciones! Has completado todas las misiones y te has convertido en un verdadero guardián del planeta. 🌍',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Certificado guardado! 📜')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar certificado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.verde,
            ),
          ),
        ],
      ),
    );
  }
}