import 'package:audioplayers/audioplayers.dart';

class MusicaFondoService {
  static final MusicaFondoService _instance = MusicaFondoService._internal();
  factory MusicaFondoService() => _instance;
  MusicaFondoService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _cancionActual;
  bool _esTransicion = false; // 🛡️ Bandera para evitar llamadas simultáneas

  Future<void> iniciar(String rutaAudio) async {
    // Si ya está sonando exactamente esta canción, no hacemos nada
    if (_isPlaying && _cancionActual == rutaAudio) return;

    // Si estamos en medio de una transición, esperamos un momento
    if (_esTransicion) return;
    _esTransicion = true;

    try {
      // 1. Si ya había otra canción sonando, la detenemos y liberamos el reproductor
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        _cancionActual = null;
        // Pequeña pausa para que el canal nativo de audio respire
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 2. Configuramos la nueva pista
      _cancionActual = rutaAudio;
      await _player.setReleaseMode(ReleaseMode.loop);
      
      await _player.play(
        AssetSource(rutaAudio),
      );
      
      await _player.setVolume(0.7);
      _isPlaying = true;
      
      print('🎵 Reproduciendo música correctamente: $rutaAudio');
    } catch (e) {
      print('❌ Error al cambiar/reproducir música: $e');
      _isPlaying = false;
      _cancionActual = null;
    } finally {
      // Liberamos la bandera pase lo que pase
      _esTransicion = false;
    }
  }

  Future<void> detener() async {
    if (!_isPlaying) return;
    try {
      _isPlaying = false;
      _cancionActual = null;
      await _player.stop();
    } catch (e) {
      print('❌ Error al detener la música: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}