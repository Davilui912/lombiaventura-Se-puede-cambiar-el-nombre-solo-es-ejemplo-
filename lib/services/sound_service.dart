import 'package:audioplayers/audioplayers.dart';

/// Servicio de audio para feedback sonoro.
/// Usa una sola instancia en toda la app (singleton).
class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  // Controla si el sonido está habilitado (el usuario puede silenciarlo)
  bool _habilitado = true;
  bool get habilitado => _habilitado;

  void toggleSonido() => _habilitado = !_habilitado;

  Future<void> _reproducir(String archivo) async {
    if (!_habilitado) return;
    try {
      await _player.stop(); // detiene cualquier sonido previo
      await _player.play(AssetSource('sounds/$archivo'));
    } catch (e) {
      // Si falla el audio no debe romper la app
      print('SoundService error: $e');
    }
  }

  // ── Acciones específicas ──────────────────────────

  Future<void> retoCompletado() => _reproducir('reto_completado.mp3');

  Future<void> monedasGanadas() => _reproducir('monedas.mp3');

  void dispose() => _player.dispose();
}
