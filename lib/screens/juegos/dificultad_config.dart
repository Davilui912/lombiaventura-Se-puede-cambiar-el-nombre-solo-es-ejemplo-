// lib/screens/juegos/dificultad_config.dart
import 'package:flutter/material.dart';

enum Dificultad { facil, medio, dificil }

class ConfigNivel {
  final double velocidadComida;
  final int puntosParaGanar;
  final double tiempoVisibleComida;
  final int puntosAcertar;
  final int puntosFallar;
  final int monedasGanadas;
  final String nombre;
  final String emoji;
  final Color color;
  final Color colorBarra;

  const ConfigNivel({
    required this.velocidadComida,
    required this.puntosParaGanar,
    required this.tiempoVisibleComida,
    required this.puntosAcertar,
    required this.puntosFallar,
    required this.monedasGanadas,
    required this.nombre,
    required this.emoji,
    required this.color,
    required this.colorBarra,
  });
}

ConfigNivel obtenerConfiguracion(Dificultad dificultad) {
  switch (dificultad) {
    case Dificultad.facil:
      return const ConfigNivel(
        velocidadComida: 3.5, // ✅ AHORA ES MEDIA (antes 2.0)
        puntosParaGanar: 50,
        tiempoVisibleComida: 4.0,
        puntosAcertar: 10,
        puntosFallar: -5,
        monedasGanadas: 1,
        nombre: 'Fácil',
        emoji: '🌱',
        color: Colors.green,
        colorBarra: Colors.blue,
      );
    case Dificultad.medio:
      return const ConfigNivel(
        velocidadComida: 5.0, // ✅ AHORA ES MEDIA-ALTA (antes 3.5)
        puntosParaGanar: 100,
        tiempoVisibleComida: 2.5,
        puntosAcertar: 15,
        puntosFallar: -10,
        monedasGanadas: 2,
        nombre: 'Medio',
        emoji: '🔥',
        color: Colors.orange,
        colorBarra: Colors.orange,
      );
    case Dificultad.dificil:
      return const ConfigNivel(
        velocidadComida: 7.0, // ✅ AHORA ES RÁPIDA (antes 5.0)
        puntosParaGanar: 150,
        tiempoVisibleComida: 1.5,
        puntosAcertar: 20,
        puntosFallar: -15,
        monedasGanadas: 3,
        nombre: 'Difícil',
        emoji: '💪',
        color: Colors.red,
        colorBarra: Colors.red,
      );
  }
}