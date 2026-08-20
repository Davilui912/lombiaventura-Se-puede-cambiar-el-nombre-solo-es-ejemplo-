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
  // ✅ Lista de 6 videos
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
      'asset': 'assets/videos/Escena2.mp4',
      'descripcion': '¿Qué es la lombricomposta?',
    },
    {
      'id': 'video_3',
      'titulo': 'Video 3',
      'asset': 'assets/videos/Escena3.mp4',
      'descripcion': '¿Por qué somos importantes las lombrices?',
    },
    {
      'id': 'video_4',
      'titulo': 'Video 4',
      'asset': 'assets/videos/Escena4.mp4',
      'descripcion': '¿Qué comemos las lombrices?',
    },
    {
      'id': 'video_5',
      'titulo': 'Video 5',
      'asset': 'assets/videos/Escena5.mp4',
      'descripcion': 'Cuidados de las lombrices',
    },
    {
      'id': 'video_6',
      'titulo': 'Video 6',
      'asset': 'assets/videos/Escena6.mp4',
      'descripcion': 'Nuestro hogar para las lombrices',
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
    
    if (!_vistos[index]) {
      setState(() {
        _vistos[index] = true;
      });
      await box.put(_videos[index]['id']!, true);
      
      if (_vistos.every((v) => v == true)) {
        _mostrarCertificado();
      }
    }
  }

  void _mostrarCertificado() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CertificadoScreen(),
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
      // ✅ FONDO EN EL BODY (cubre toda la pantalla)
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
                padding: const EdgeInsets.all(12),
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
                      // ✅ Progreso
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.verde.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
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
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$completados / $total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.verde,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progreso / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.verde),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$progreso% completado',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ✅ Lista de videos
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          final visto = _vistos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: visto ? AppTheme.verde.withValues(alpha: 0.2) : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    visto ? Icons.check_circle : Icons.play_arrow,
                                    color: visto ? AppTheme.verde : Colors.grey.shade600,
                                    size: 18,
                                  ),
                                ),
                              ),
                              title: Text(
                                video['titulo']!,
                                style: TextStyle(
                                  fontWeight: visto ? FontWeight.normal : FontWeight.w600,
                                  decoration: visto ? TextDecoration.lineThrough : null,
                                  color: visto ? Colors.grey : AppTheme.negro,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                video['descripcion']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: visto ? AppTheme.verde.withValues(alpha: 0.2) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    visto ? Icons.check : Icons.play_arrow,
                                    color: visto ? AppTheme.verde : Colors.grey.shade400,
                                    size: visto ? 16 : 14,
                                  ),
                                ),
                              ),
                              onTap: () => _abrirVideo(index),
                              dense: true,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ✅ Botón de certificado
                      if (completados == total && total > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _mostrarCertificado,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text(
                              '🎓 Ver Certificado',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 4),
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
          yaVisto: _vistos[index],
        ),
      ),
    );
  }
}

// ==================== VIDEO PLAYER ====================
class VideoPlayerScreen extends StatefulWidget {
  final Map<String, String> video;
  final VoidCallback onMarkComplete;
  final bool yaVisto;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.onMarkComplete,
    this.yaVisto = false,
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
        _controller!.setLooping(false);
        _controller!.play();
        
        if (!widget.yaVisto) {
          _controller!.addListener(() {
            if (_controller!.value.position >= _controller!.value.duration &&
                _controller!.value.duration > Duration.zero &&
                !_wasMarked) {
              _markComplete();
            }
          });
        }
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
          content: Text('✅ ¡Video completado!'),
          backgroundColor: AppTheme.verde,
        ),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video['titulo']!),
        backgroundColor: AppTheme.verde,
        actions: [
          if (widget.yaVisto)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Visto',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      // ✅ FONDO EN EL BODY DEL VIDEO PLAYER
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
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: _isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
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
                              _wasMarked = false;
                              _controller!.seekTo(Duration.zero);
                              _controller!.play();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.yaVisto
                            ? '✅ Ya completaste este video. ¡Míralo de nuevo si quieres!'
                            : 'El video se marcará automáticamente cuando termine',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.yaVisto ? AppTheme.verde : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
      ),
    );
  }
}

// ==================== CERTIFICADO SCREEN ====================
class CertificadoScreen extends StatelessWidget {
  const CertificadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('🎓 Certificado'),
        backgroundColor: AppTheme.verde,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
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
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.amber.shade300, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎓',
                  style: TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 10),
                Text(
                  'CERTIFICADO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.verde,
                    letterSpacing: 2,
                  ),
                ),
                const Divider(
                  color: AppTheme.verde,
                  thickness: 2,
                  indent: 40,
                  endIndent: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Se otorga el presente certificado a',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Lombrikid!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por haber completado exitosamente el\nCurso de Lombricomposta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.verde.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🏆 ¡Lombrikid Experto!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.verde,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.verde,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '✅ Cerrar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
}