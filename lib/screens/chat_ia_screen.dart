import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/theme.dart';
import '../services/groq_service.dart';
import '../services/conversacion_service.dart';
import '../services/accesorios_service.dart';
import '../services/tts_service.dart'; 
import '../models/conversacion.dart';
import 'historial_chat_screen.dart';

class ChatIAScreen extends StatefulWidget {
  final String? conversacionId;
  const ChatIAScreen({super.key, this.conversacionId});

  @override
  State<ChatIAScreen> createState() => _ChatIAScreenState();
}

class _ChatIAScreenState extends State<ChatIAScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroqService _iaService = GroqService();
  final TTSService _ttsService = TTSService(); // ✅ NUEVO: Google Cloud TTS
  final SpeechToText _speechToText = SpeechToText();
  
  List<Map<String, String>> _mensajes = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _vozAutomatica = true;
  
  String? _conversacionActualId;
  String _conversacionTitulo = '';

  late ConversacionService _convService;
  String _personaje = 'Lola';
  Map<String, String?> _accesoriosEquipados = {};
  
  @override
  void initState() {
    super.initState();
    _cargarPersonaje();
    _initServices();
    _cargarAccesorios();
    _initSpeech();
    _cargarConversacion();
  }

  Future<void> _cargarPersonaje() async {
    final box = await Hive.openBox('configuracion');
    final personaje = box.get('personaje', defaultValue: 'Lola');
    setState(() {
      _personaje = personaje;
    });
  }

  Future<void> _initServices() async {
    _convService = await ConversacionService.getInstance();
  }
  
  Future<void> _cargarAccesorios() async {
    final accesoriosService = AccesoriosService();
    await accesoriosService.init();
    setState(() {
      _accesoriosEquipados = accesoriosService.obtenerEquipados(_personaje);
    });
  }
  
  Future<void> _cargarConversacion() async {
    if (widget.conversacionId != null) {
      final conversacion = await _convService.obtenerPorId(widget.conversacionId!);
      if (conversacion != null) {
        setState(() {
          _mensajes = List.from(conversacion.mensajes);
          _conversacionActualId = conversacion.id;
          _conversacionTitulo = conversacion.titulo;
        });
        _scrollToBottom();
        return;
      }
    }
    _agregarMensajeBienvenida();
  }
  
  void _agregarMensajeBienvenida() {
    _mensajes = [{
      'role': 'lola',
      'content': '¡Hola, Lombrikid! 🪱 Soy la lombriz sabia.\n\nPregúntame sobre lombrices, composta y cómo cuidar el planeta. ¡Estoy aquí para ayudarte! 🌱✨\n\n🔊 Puedes activar o desactivar mi voz con el botón de la esquina.',
    }];
    _conversacionActualId = null;
    _conversacionTitulo = '';
  }
    
  Future<void> _guardarConversacion() async {
    try {
      if (_mensajes.isEmpty) return;
      if (_mensajes.length <= 1) return;
      
      final id = _conversacionActualId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final titulo = _conversacionTitulo.isEmpty && _mensajes.length > 1
          ? _convService.generarTitulo(_mensajes[1]['content'] ?? 'Nueva conversación')
          : _conversacionTitulo;
      
      final conversacion = Conversacion(
        id: id,
        titulo: titulo,
        fecha: DateTime.now(),
        mensajes: List.from(_mensajes),
      );
      
      await _convService.guardarConversacion(conversacion);
      
      _conversacionActualId ??= id;
      if (_conversacionTitulo.isEmpty && _mensajes.length > 1) {
        _conversacionTitulo = titulo;
      }
    } catch (e) {
      print('Error guardando conversación: $e');
    }
  }

  // ==================== TTS CON GOOGLE CLOUD ====================

  /// ✅ Limpia el texto de emojis y caracteres especiales
  String _limpiarTextoParaTTS(String texto) {
    final regex = RegExp(
      r'[^A-Za-zÁÉÍÓÚáéíóúÑñÜü\s.,;:!?¡¿0-9]',
      unicode: true,
    );

    String textoLimpio = texto.replaceAll(regex, '');
    textoLimpio = textoLimpio.replaceAll(RegExp(r'\n+'), '. ');
    textoLimpio = textoLimpio.replaceAll(RegExp(r'\s+'), ' ');
    textoLimpio = textoLimpio.replaceAll(RegExp(r'[*_#~]'), '');
    textoLimpio = textoLimpio.replaceAll(RegExp(r'https?://[^\s]+'), '');
    
    return textoLimpio.trim();
  }

  // ==================== FIN TTS ====================

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _enviarMensaje({String? preguntaTexto}) async {
    final pregunta = preguntaTexto ?? _controller.text.trim();
    if (pregunta.isEmpty) return;
    
    // ✅ Si está hablando, detener
    if (_isSpeaking) {
      await _detenerLectura();
    }
    
    setState(() {
      _mensajes.add({'role': 'user', 'content': pregunta});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();
    
    String respuesta = '';
    try {
      respuesta = await _iaService.preguntarALola(pregunta);
    } catch (e) {
      print('Error al obtener respuesta: $e');
      respuesta = '';
    }
    
    if (respuesta.isNotEmpty) {
      setState(() {
        _mensajes.add({'role': 'lola', 'content': respuesta});
      });
    } else {
      setState(() {
        _mensajes.add({
          'role': 'lola',
          'content': 'Lo siento, no pude procesar tu pregunta. ¿Puedes intentar de nuevo? 🪱'
        });
      });
    }
    
    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
    
    _guardarConversacion().catchError((e) {
      print('Error guardando: $e');
    });
    
    // ✅ Esperar un momento antes de leer
    if (_vozAutomatica && respuesta.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _leerRespuesta(respuesta);
    }
  }
  
  Future<void> _leerRespuesta(String texto) async {
    // ✅ Si ya está hablando, detener primero
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // ✅ Limpiar el texto antes de leerlo
    final textoLimpio = _limpiarTextoParaTTS(texto);
    
    if (textoLimpio.isEmpty) {
      print('⚠️ Texto vacío después de limpiar, no se lee');
      return;
    }
    
    print('🔊 Texto original: $texto');
    print('🔊 Texto limpiado: $textoLimpio');
    
    setState(() => _isSpeaking = true);
    
    try {
      // ✅ Usar Google Cloud TTS
      final exito = await _ttsService.speak(textoLimpio);
      if (!exito) {
        setState(() => _isSpeaking = false);
        print('⚠️ Error al generar voz con Google Cloud TTS');
      }
    } catch (e) {
      print('❌ Error al hablar: $e');
      setState(() => _isSpeaking = false);
    }
  }
  
  Future<void> _detenerLectura() async {
    try {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
      print('🔇 Lectura detenida');
    } catch (e) {
      print('❌ Error al detener: $e');
    }
  }
  
  Future<void> _escucharPregunta() async {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }
    
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _isListening = false;
              _controller.text = result.recognizedWords;
            });
            _enviarMensaje(preguntaTexto: result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        localeId: 'es-MX',
      );
    }
  }
  
  void _nuevaConversacion() {
    setState(() {
      _mensajes = [];
      _conversacionActualId = null;
      _conversacionTitulo = '';
      _agregarMensajeBienvenida();
    });
  }
  
  void _verHistorial() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistorialChatScreen()),
    );
    if (result != null && result is String) {
      _cargarConversacionPorId(result);
    }
  }
  
  Future<void> _cargarConversacionPorId(String id) async {
    final conversacion = await _convService.obtenerPorId(id);
    if (conversacion != null) {
      setState(() {
        _mensajes = List.from(conversacion.mensajes);
        _conversacionActualId = conversacion.id;
        _conversacionTitulo = conversacion.titulo;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ttsService.dispose(); // ✅ Liberar recursos de TTS
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preguntasRestantes = _iaService.preguntasRestantesHoy;
    
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Lombriz_IA',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.verde,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$preguntasRestantes/30',
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(_vozAutomatica ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() => _vozAutomatica = !_vozAutomatica);
              if (!_vozAutomatica && _isSpeaking) _detenerLectura();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _nuevaConversacion,
            tooltip: 'Nueva conversación',
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _verHistorial,
            tooltip: 'Historial',
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
        child: Column(
          children: [
            if (!_vozAutomatica)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.grey.shade200,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_off, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Voz desactivada', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _mensajes.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _mensajes.length && _isLoading) {
                        return _buildLoadingIndicator();
                      }
                      final mensaje = _mensajes[index];
                      return _buildMensaje(
                        mensaje['content']!,
                        esUsuario: mensaje['role'] == 'user',
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMensaje(String texto, {required bool esUsuario}) {
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: esUsuario ? AppTheme.verde : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: esUsuario ? const Radius.circular(20) : Radius.zero,
            bottomRight: esUsuario ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: esUsuario ? Colors.white : AppTheme.cafe,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              if (!esUsuario)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up, size: 18),
                        color: AppTheme.verde,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: _isSpeaking ? _detenerLectura : () => _leerRespuesta(texto),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSpeaking ? '🔴 Leyendo...' : '🔊 Escuchar',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
  
  Widget _buildLoadingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.verde),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : AppTheme.cafe),
            onPressed: _escucharPregunta,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Escribe tu pregunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _enviarMensaje(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.verde),
            onPressed: () => _enviarMensaje(),
          ),
        ],
      ),
    );
  }
}