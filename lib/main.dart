import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'models/conversacion.dart';
import 'services/recordatorios_service.dart';
import 'services/sync_service.dart';
import 'screens/splash_screen.dart';
import 'providers/usuario_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ConversacionAdapter());

  await Hive.openBox('configuracion');
  await Hive.openBox('chat_historial');
  await Hive.openBox('accesorios');
  await Hive.openBox('logros');
  await Hive.openBox('diario');
  await Hive.openBox('actividad');
  await Hive.openBox('recordatorios');
  await Hive.openBox('monedas');
  await Hive.openBox('capacitaciones');
  await Hive.openBox('usuarios');
  await Hive.openBox('historial_ventas');
  await Hive.openBox('usuarios_sync');
  await Hive.openBox('sync_pendientes');

  final recordatorioService = RecordatoriosService();
  await recordatorioService.init();

  final syncService = SyncService();
  await syncService.sincronizarAlIniciar();

  runApp(
    ChangeNotifierProvider(
      create: (_) => UsuarioProvider(),
      child: const LombriaventuraApp(),
    ),
  );
}

class LombriaventuraApp extends StatelessWidget {
  const LombriaventuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lombriaventura',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}