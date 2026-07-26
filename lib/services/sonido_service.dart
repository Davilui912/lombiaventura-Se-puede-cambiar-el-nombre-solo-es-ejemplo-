import 'package:audioplayers/audioplayers.dart';

class SonidoService {
  static final SonidoService _instance = SonidoService._internal();
  factory SonidoService() => _instance;
  SonidoService._internal();

  final AudioPlayer _player = AudioPlayer();

  Future<void> reproducir(String archivo) async {
    try {
      await _player.play(AssetSource('audio/$archivo'));
    } catch (e) {
      print('❌ Error reproduciendo sonido: $e');
    }
  }

  Future<void> victoria() async {
    await reproducir('victoria.mp3');
  }

  Future<void> derrota() async {
    await reproducir('derrota.mp3');
  }

  void dispose() {
    _player.dispose();
  }
}