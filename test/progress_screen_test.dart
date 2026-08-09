import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lombriaventura/screens/progress_screen.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';

  @override
  Future<String?> getApplicationSupportPath() async => '.';

  @override
  Future<String?> getTemporaryPath() async => '.';

  @override
  Future<String?> getLibraryPath() async => '.';

  @override
  Future<String?> getApplicationCachePath() async => '.';

  @override
  Future<List<String>?> getExternalStoragePaths(
          {StorageDirectory? type}) async =>
      null;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<String?> getDownloadsPath() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  setUp(() async {
    await Hive.initFlutter();
    await Hive.deleteBoxFromDisk('actividad');
    await Hive.deleteBoxFromDisk('monedas');
    await Hive.deleteBoxFromDisk('historial_ventas');
    await Hive.openBox('actividad');
    await Hive.openBox('monedas');
    await Hive.openBox('historial_ventas');
  });

  testWidgets('ProgressScreen shows the streak from stored activity data', (
    tester,
  ) async {
    final box = Hive.box('actividad');
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    await box.put(hoy.toIso8601String().split('T')[0], true);
    await box.put(ayer.toIso8601String().split('T')[0], true);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProgressScreen(
          coins: 0,
          streakDays: 7,
          recordDays: 15,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 días !'), findsOneWidget);
  });
}
