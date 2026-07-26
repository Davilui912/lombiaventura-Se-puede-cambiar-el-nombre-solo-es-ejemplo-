import 'package:flutter/material.dart';
import '../config/theme.dart';

// ✅ COORDENADAS PARA IMAGEN DE 180x180
class ConfigAccesorio {
  final double top;
  final double right;
  final double width;

  const ConfigAccesorio({required this.top, required this.right, required this.width});
}

final Map<String, ConfigAccesorio> coordenadasAccesorios = {
  'gorra_azul_pluma': const ConfigAccesorio(top: -10, right: 10, width: 70),
  'gorra_balon': const ConfigAccesorio(top: -3, right: 15, width: 70),
  'gorra_futbol_lentes': const ConfigAccesorio(top: -10, right: 10, width: 70),
  'gorra_futbol_sinta': const ConfigAccesorio(top: -10, right: 10, width: 70),
  'gorra_lentes_oscuros': const ConfigAccesorio(top: -3, right: 15, width: 70),
  'gorra_lombriz': const ConfigAccesorio(top: -13, right: 15, width: 70),
  'gorra_parches_amarilla': const ConfigAccesorio(top: -3, right: 15, width: 70),
  'gorra_parches_azul': const ConfigAccesorio(top: -5, right: 11, width: 70),
  'gorra_parches_futbol': const ConfigAccesorio(top: -5, right: 10, width: 70),
  'gorra_parches_gris': const ConfigAccesorio(top: -5, right: 11, width: 70),
  'gorra_parches_militar': const ConfigAccesorio(top: -3, right: 12, width: 70),
  'lentes_azules': const ConfigAccesorio(top: 10, right: 26, width: 60),
  'lentes_descanso': const ConfigAccesorio(top: 15, right: 25, width: 60),
  'lentes_futbol': const ConfigAccesorio(top: 12, right: 23, width: 80),
  'lentes_inventor': const ConfigAccesorio(top: 17, right: 29, width: 65),
  'lentes_militares': const ConfigAccesorio(top: 16, right: 25, width: 60),
  'lentes_naranjas': const ConfigAccesorio(top: 15, right: 25, width: 60),
  'lentes_oscuros': const ConfigAccesorio(top: 19, right: 28, width: 60),
  'lentes_simples': const ConfigAccesorio(top: 4, right: 25, width: 65),
  'lentes_sol': const ConfigAccesorio(top: 15, right: 31, width: 60),
  'collar_perlas_amarillas': const ConfigAccesorio(top: 48, right: 20, width: 60),
  'collar_perlas': const ConfigAccesorio(top: 55, right: 20, width: 60),
  'collar_plateado_pluma': const ConfigAccesorio(top: 55, right: 20, width: 60),
  'collar_pluma': const ConfigAccesorio(top: 55, right: 20, width: 60),
  'sombrero_amarillo': const ConfigAccesorio(top: -25, right: 20, width: 65),
  'sombrero_arcoiris': const ConfigAccesorio(top: -25, right: 20, width: 65),
  'sombrero_azul': const ConfigAccesorio(top: -25, right: 20, width: 65),
  'sombrero_estilo_flores': const ConfigAccesorio(top: -25, right: 20, width: 65),
  'sombrero_estilo_morado': const ConfigAccesorio(top: -25, right: 20, width: 65),
  'sombrero_estilo_naranja': const ConfigAccesorio(top: -25, right: 20, width: 65),
  'sombrero_rojo': const ConfigAccesorio(top: -20, right: 20, width: 65),
  'sombrero_verde': const ConfigAccesorio(top: -25, right: 20, width: 65),
};

class LombrizConAccesorio extends StatelessWidget {
  final double size;
  final String? accesorioId;

  const LombrizConAccesorio({
    super.key,
    this.size = 100,
    this.accesorioId,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Coordenadas base para 180x180
    final baseSize = 180.0;
    final scale = size / baseSize; // ✅ Factor de escalado

    final coordenadas = accesorioId != null ? coordenadasAccesorios[accesorioId] : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ✅ Imagen base de la lombriz (centrada)
          Positioned.fill(
            child: Image.asset(
              'assets/images/personaje/lombriz_base.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: AppTheme.verde.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bug_report,
                    size: size * 0.6,
                    color: AppTheme.verde,
                  ),
                );
              },
            ),
          ),
          
          // ✅ Accesorio con coordenadas escaladas
          if (accesorioId != null && accesorioId!.isNotEmpty && coordenadas != null)
            Positioned(
              top: coordenadas.top * scale,
              right: coordenadas.right * scale,
              child: Image.asset(
                'assets/images/accesorios/$accesorioId.png',
                width: coordenadas.width * scale,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }
}