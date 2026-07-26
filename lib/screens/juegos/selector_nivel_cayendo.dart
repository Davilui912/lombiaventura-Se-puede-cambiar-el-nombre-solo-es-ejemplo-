import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'alimenta_lombriz_cayendo.dart';
import 'dificultad_config.dart';

class SelectorNivelCayendoScreen extends StatelessWidget {
  const SelectorNivelCayendoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Selecciona dificultad'),
        backgroundColor: AppTheme.verde,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNivelButton(
                context,
                Dificultad.facil,
                '🌱 Fácil',
                'Velocidad lenta',
                'Ganas 1 moneda al completar',
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildNivelButton(
                context,
                Dificultad.medio,
                '🔥 Medio',
                'Velocidad media',
                'Ganas 2 monedas al completar',
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildNivelButton(
                context,
                Dificultad.dificil,
                '💪 Difícil',
                'Velocidad rápida',
                'Ganas 3 monedas al completar',
                Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNivelButton(
    BuildContext context,
    Dificultad dificultad,
    String titulo,
    String velocidad,
    String recompensa,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlimentaLombrizCayendoScreen(
              dificultad: dificultad,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color, width: 3),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  titulo.split(' ')[0],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    velocidad,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    recompensa,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }
}