import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _usuario = '';
  String _nombreCompleto = '';
  String _edad = 'No especificada';
  String _ciudad = 'No especificada';
  String _fechaRegistro = '';
  String? _fotoPerfil;
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _isLoading = true);
    
    try {
      final configBox = await Hive.openBox('configuracion');
      final usuariosBox = await Hive.openBox('usuarios');
      final listaUsuarios = usuariosBox.get('lista', defaultValue: <Map<String, dynamic>>[]);
      
      final usuarioActual = configBox.get('usuario_actual', defaultValue: '');
      
      // Buscar el usuario en la lista
      Map<String, dynamic>? usuarioData;
      for (var item in listaUsuarios) {
        if (item['nombre_usuario'] == usuarioActual) {
          usuarioData = item;
          break;
        }
      }
      
      // Obtener edad y ciudad
      String edadTemp = configBox.get('usuario_edad', defaultValue: '');
      if (edadTemp.isEmpty && usuarioData != null) {
        edadTemp = usuarioData['edad']?.toString() ?? '';
      }
      
      String ciudadTemp = configBox.get('usuario_ciudad', defaultValue: '');
      if (ciudadTemp.isEmpty && usuarioData != null) {
        ciudadTemp = usuarioData['ciudad']?.toString() ?? '';
      }
      
      setState(() {
        _usuario = usuarioActual;
        _nombreCompleto = configBox.get('usuario_nombre', defaultValue: 'Lombrikid');
        _edad = edadTemp.isNotEmpty ? edadTemp : 'No especificada';
        _ciudad = ciudadTemp.isNotEmpty ? ciudadTemp : 'No especificada';
        _fechaRegistro = configBox.get('usuario_fecha_registro', defaultValue: DateTime.now().toIso8601String());
        _fotoPerfil = configBox.get('usuario_foto_perfil');
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cambiarFoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cambiar foto de perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcionFoto(
                    icon: Icons.camera_alt,
                    label: 'Cámara',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final XFile? foto = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (foto != null) {
                        _guardarFoto(foto.path);
                      }
                    },
                  ),
                  _buildOpcionFoto(
                    icon: Icons.photo_library,
                    label: 'Galería',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final XFile? foto = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (foto != null) {
                        _guardarFoto(foto.path);
                      }
                    },
                  ),
                  _buildOpcionFoto(
                    icon: Icons.delete,
                    label: 'Eliminar',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(ctx);
                      _eliminarFoto();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionFoto({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (color ?? AppTheme.verde).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? AppTheme.verde, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.negro,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarFoto(String ruta) async {
    final configBox = await Hive.openBox('configuracion');
    await configBox.put('usuario_foto_perfil', ruta);
    setState(() {
      _fotoPerfil = ruta;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Foto de perfil actualizada'),
        backgroundColor: AppTheme.verde,
      ),
    );
  }

  Future<void> _eliminarFoto() async {
    final configBox = await Hive.openBox('configuracion');
    await configBox.delete('usuario_foto_perfil');
    setState(() {
      _fotoPerfil = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto de perfil eliminada'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final configBox = await Hive.openBox('configuracion');
      await configBox.put('login_exitoso', false);
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  String _formatearFecha(String fechaIso) {
    if (fechaIso.isEmpty) return 'Hoy';
    try {
      final fecha = DateTime.parse(fechaIso);
      final ahora = DateTime.now();
      final diff = ahora.difference(fecha).inDays;
      if (diff == 0) return 'Hoy';
      if (diff == 1) return 'Ayer';
      return 'Hace $diff días';
    } catch (e) {
      return 'Reciente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.verde,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
                    children: [
                      const SizedBox(height: 10),
                      
                      GestureDetector(
                        onTap: _cambiarFoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.verde.withValues(alpha: 0.2),
                              child: _fotoPerfil != null && File(_fotoPerfil!).existsSync()
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_fotoPerfil!),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppTheme.verde,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.verde,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.verde,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Text(
                        _nombreCompleto,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.verde.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🪱 Lombrikid',
                          style: TextStyle(
                            color: AppTheme.verde,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.badge, color: AppTheme.verde),
                          title: const Text('Nombre de usuario'),
                          subtitle: Text(_usuario.isEmpty ? 'Sin definir' : _usuario),
                        ),
                      ),
                      
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person, color: AppTheme.verde),
                          title: const Text('Nombre completo'),
                          subtitle: Text(_nombreCompleto),
                        ),
                      ),
                      
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.cake, color: AppTheme.verde),
                          title: const Text('Edad'),
                          subtitle: Text(_edad),
                        ),
                      ),
                      
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_city, color: AppTheme.verde),
                          title: const Text('Ciudad'),
                          subtitle: Text(_ciudad),
                        ),
                      ),
                      
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today, color: AppTheme.verde),
                          title: const Text('Lombrikid desde'),
                          subtitle: Text(_formatearFecha(_fechaRegistro)),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.verde.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.verde),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Toca tu foto de perfil para cambiarla. ¡Sigue ayudando al planeta! 🌱',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}