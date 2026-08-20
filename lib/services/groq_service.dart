import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config.dart';

class GroqService {
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // ✅ Usar la clave desde config.dart
  static const String _apiKey = AppConfig.groqApiKey;
  
  // ✅ Modelo activo actual
  static const String _modeloActual = 'openai/gpt-oss-20b';
  
  static int _preguntasHoy = 0;
  static String _ultimaFecha = '';
  
  GroqService();
  
  bool _puedePreguntarHoy() {
    final hoy = DateTime.now().toString().substring(0, 10);
    if (_ultimaFecha != hoy) {
      _preguntasHoy = 0;
      _ultimaFecha = hoy;
    }
    return _preguntasHoy < 30;
  }
  
  void _registrarPregunta() {
    _preguntasHoy++;
  }
  
  int get preguntasRestantesHoy => 30 - _preguntasHoy;
  
  Future<bool> _tieneInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  Future<String> preguntarALola(String pregunta) async {
    if (pregunta.trim().isEmpty) {
      return '¡Hola! Dime tu pregunta y te ayudaré. 🪱';
    }
    
    if (!_puedePreguntarHoy()) {
      return '🌟 ¡Guau! Ya hiciste 30 preguntas hoy. ¡Qué curioso eres! Regresa mañana. 🪱';
    }
    
    if (!await _tieneInternet()) {
      return _respuestaOffline(pregunta);
    }
    
    _registrarPregunta();
    
    try {
      final respuesta = await _preguntarGroq(pregunta);
      if (respuesta.isNotEmpty) {
        return respuesta;
      }
      return _respuestaOffline(pregunta);
    } catch (e) {
      print('Error en Groq: $e');
      return _respuestaOffline(pregunta);
    }
  }
  
  Future<String> _preguntarGroq(String pregunta) async {
    final promptSistema = '''
Eres una lombriz roja californiana simpática y sabia.
Ayudas a niños de 6 a 12 años en la app "Lombriaventura".
Siempre te diriges a los niños como "Lombrikid" en tus respuestas.

INSTRUCCIONES:
1. Responde con total naturalidad a saludos (como "hola", "buenos días"), despedidas y preguntas de cortesía.
2. Responde también sobre lombrices, lombricomposta, composta, reciclaje, plantas, precios de lombrices, dónde comprarlas, materiales para su hábitat, cuidados generales, sobre matematicas de negocio y matematicas en general.
3. Si la pregunta se sale completamente de estos temas o del proyecto ( deportes, videojuegos ajenos, etc.), responde amablemente: "🌱 ¡Uy! Esa pregunta se sale de mi túnel de tierra. Mejor pregúntame sobre lombrices, composta o dónde conseguirnos."
4. Respuestas ALEGRES, con EMOJIS, máximo 4 oraciones.
5. Habla en PRIMERA PERSONA como lombriz sabia y amigable.
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _modeloActual,
        'messages': [
          {'role': 'system', 'content': promptSistema},
          {'role': 'user', 'content': pregunta},
        ],
        'temperature': 0.6,
        'max_completion_tokens': 500,
        'top_p': 0.95,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final respuesta = data['choices'][0]['message']['content'].trim();
      return respuesta.isNotEmpty ? respuesta : _respuestaOffline(pregunta);
    } else {
      print('Error Groq: ${response.statusCode} - ${response.body}');
      return _respuestaOffline(pregunta);
    }
  }
  
  // ========== RESPUESTAS OFFLINE (RESPALDO) ==========
  
  String _respuestaOffline(String pregunta) {
    final preguntaLower = pregunta.toLowerCase();
    
    if (preguntaLower.contains('comen') || preguntaLower.contains('aliment')) {
      return '🍎 ¡Nos encantan las cáscaras de frutas y verduras! Hay que cortarlas en trozos pequeños y esperar días a que se fermenten. 🪱';
    }
    
    if (preguntaLower.contains('temperatura')) {
      return '🌡️ Estamos felices entre 15°C y 25°C. Si hace mucho frío o calor, podemos enfermarnos. ❄️🔥';
    }
    
    if (preguntaLower.contains('humedad')) {
      return '💧 La humedad ideal es como una esponja escurrida. Prueba del puño: aprieta y debe quedar como plastilina. 🖐️';
    }
    
    if (preguntaLower.contains('lixiviado')) {
      return '💧 El lixiviado es el líquido de la composta. ¡Es súper nutritivo! Se mezcla con 10 partes de agua. 🌱';
    }
    
    return '📚 ¡Buena pregunta, Lombrikid! Revisa los módulos educativos de Lombriaventura. 🌱✨';
  }
}