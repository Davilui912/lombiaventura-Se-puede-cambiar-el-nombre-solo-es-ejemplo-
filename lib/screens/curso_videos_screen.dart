import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme.dart';

class CursoVideosScreen extends StatefulWidget {
  const CursoVideosScreen({super.key});

  @override
  State<CursoVideosScreen> createState() => _CursoVideosScreenState();
}

class _CursoVideosScreenState extends State<CursoVideosScreen> {
  // ✅ Lista de 7 videos
  final List<Map<String, String>> _videos = [
    {
      'id': 'video_1',
      'titulo': 'Video 1',
      'asset': 'assets/videos/lombriz_intro.mp4',
      'descripcion': 'Introducción a las lombrices',
    },
    {
      'id': 'video_2',
      'titulo': 'Video 2',
      'asset': 'assets/videos/video2.mp4',
      'descripcion': '¿Qué es la lombricomposta?',
    },
    {
      'id': 'video_3',
      'titulo': 'Video 3',
      'asset': 'assets/videos/video3.mp4',
      'descripcion': 'Materiales necesarios',
    },
    {
      'id': 'video_4',
      'titulo': 'Video 4',
      'asset': 'assets/videos/video4.mp4',
      'descripcion': 'Preparando el hogar de las lombrices',
    },
    {
      'id': 'video_5',
      'titulo': 'Video 5',
      'asset': 'assets/videos/video5.mp4',
      'descripcion': 'Alimentación y cuidados',
    },
    {
      'id': 'video_6',
      'titulo': 'Video 6',
      'asset': 'assets/videos/video6.mp4',
      'descripcion': 'Cosechando humus y lixiviado',
    },
    {
      'id': 'video_7',
      'titulo': 'Video 7',
      'asset': 'assets/videos/video7.mp4',
      'descripcion': 'Emprendimiento con lombrices',
    },
  ];

  List<bool> _vistos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    final box = await Hive.openBox('progreso_videos');
    _vistos = List.generate(_videos.length, (index) {
      return box.get(_videos[index]['id']!, defaultValue: false);
    });
    setState(() => _isLoading = false);
  }

  Future<void> _marcarVisto(int index) async {
    final box = await Hive.openBox('progreso_videos');
    setState(() {
      _vistos[index] = !_vistos[index];
    });
    await box.put(_videos[index]['id']!, _vistos[index]);
    
    if (_vistos.every((v) => v == true)) {
      _mostrarCertificado();
    }
  }

  void _mostrarCertificado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎓 ¡Felicidades!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📜 Has completado todos los videos del curso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.verde.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.verde, width: 2),
              ),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    '¡Lombrikid Experto!',
                    style: TextStyle(
                      color: AppTheme.verde,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Has completado el curso de lombricomposta',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎁 +50 monedas por completar el curso',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verde,
            ),
            child: const Text('🎉 ¡Ver certificado!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _videos.length;
    final completados = _vistos.where((v) => v == true).length;
    final progreso = total > 0 ? (completados / total * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 Curso de Lombricomposta'),
        backgroundColor: AppTheme.verde,
        actions: [
          if (completados == total && total > 0)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.verified, color: Colors.white),
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
                    children: [
                      // ✅ Progreso
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
                                Text(
                                  '📊 Progreso',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.verde,
                                  ),
                                ),
                                Text(
                                  '$completados / $total videos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.verde,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progreso / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.verde),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$progreso% completado',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Lista de videos
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          final visto = _vistos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: visto ? AppTheme.verde.withValues(alpha: 0.2) : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    visto ? Icons.check_circle : Icons.play_arrow,
                                    color: visto ? AppTheme.verde : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              title: Text(
                                video['titulo']!,
                                style: TextStyle(
                                  fontWeight: visto ? FontWeight.normal : FontWeight.bold,
                                  decoration: visto ? TextDecoration.lineThrough : null,
                                  color: visto ? Colors.grey : AppTheme.negro,
                                ),
                              ),
                              subtitle: Text(
                                video['descripcion']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: Checkbox(
                                value: visto,
                                onChanged: (_) => _marcarVisto(index),
                                activeColor: AppTheme.verde,
                              ),
                              onTap: () => _abrirVideo(index),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ✅ Botón de certificado
                      if (completados == total && total > 0)
                        ElevatedButton(
                          onPressed: _mostrarCertificado,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            '🎓 Ver Certificado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _abrirVideo(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: _videos[index],
          onMarkComplete: () => _marcarVisto(index),
        ),
      ),
    );
  }
}

// ==================== VIDEO PLAYER ====================
class VideoPlayerScreen extends StatefulWidget {
  final Map<String, String> video;
  final VoidCallback onMarkComplete;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.onMarkComplete,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _wasMarked = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    _controller = VideoPlayerController.asset(widget.video['asset']!)
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller!.setLooping(true);
        _controller!.play();
      }).catchError((e) {
        print('Error al cargar video: $e');
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _markComplete() {
    if (!_wasMarked) {
      _wasMarked = true;
      widget.onMarkComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ ¡Video marcado como visto!'),
          backgroundColor: AppTheme.verde,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video['titulo']!),
        backgroundColor: AppTheme.verde,
        actions: [
          TextButton(
            onPressed: _markComplete,
            child: const Text(
              '✅ Marcar visto',
              style: TextStyle(color: Colors.white, fontSize: 14),
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
        child: Center(
          child: _isInitialized
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppTheme.verde,
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_controller!.value.isPlaying) {
                                _controller!.pause();
                              } else {
                                _controller!.play();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.replay, color: AppTheme.verde, size: 28),
                          onPressed: () {
                            _controller!.seekTo(Duration.zero);
                            _controller!.play();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Toca "Marcar visto" cuando termines el video',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}