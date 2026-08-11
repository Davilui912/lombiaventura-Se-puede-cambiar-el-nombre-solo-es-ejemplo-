import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/theme.dart';

class ModuloEducativoScreen extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final String informacion;
  final List<Map<String, String>> puntosClave;
  final String? videoAsset;

  const ModuloEducativoScreen({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.informacion,
    required this.puntosClave,
    this.videoAsset,
  });

  @override
  State<ModuloEducativoScreen> createState() => _ModuloEducativoScreenState();
}

class _ModuloEducativoScreenState extends State<ModuloEducativoScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _inicializarVideo();
  }

  void _inicializarVideo() {
    if (widget.videoAsset != null) {
      _videoController = VideoPlayerController.asset(widget.videoAsset!)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.setLooping(true);
          _videoController!.play();
        }).catchError((error) {
          print('Error al cargar video: $error');
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: AppTheme.verde,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ DESCRIPCIÓN (cuadro amarillo con gorro de graduación)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.amarillo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 30)), // ✅ Cambiado a gorro
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Bienvenido al curso de lombricomposta! 🌱\n'
                      'Mira los videos en orden y completa cada uno para avanzar. '
                      'Al terminar un video, aparecerá una ✓ que te permitirá continuar.\n\n'
                      '🎓 ¡Completa todo el curso y recibe tu certificado virtual y monedas! 🪙',
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ INFORMACIÓN (con video dentro)
            const Text(
              '📖 Información',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.cafe,
              ),
            ),
            const SizedBox(height: 12),
            
            // ✅ VIDEO (dentro de la sección de información)
            if (widget.videoAsset != null && _isVideoInitialized) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppTheme.verde,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.replay,
                      color: AppTheme.verde,
                      size: 24,
                    ),
                    onPressed: () {
                      _videoController!.seekTo(Duration.zero);
                      _videoController!.play();
                    },
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _formatearDuracion(
                        _videoController!.value.position.inSeconds),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Text(' / ', style: TextStyle(fontSize: 12)),
                  Text(
                    _formatearDuracion(
                        _videoController!.value.duration.inSeconds),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ✅ TEXTO DE INFORMACIÓN
            Text(
              widget.informacion,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            // ✅ Puntos clave
            const Text(
              '✨ Puntos clave',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.cafe,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.puntosClave.map((punto) => _buildPuntoClave(
                  punto['emoji'] ?? '📌',
                  punto['titulo'] ?? '',
                  punto['descripcion'] ?? '',
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPuntoClave(String emoji, String titulo, String descripcion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearDuracion(int segundos) {
    final minutos = segundos ~/ 60;
    final segundosRestantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
  }
}