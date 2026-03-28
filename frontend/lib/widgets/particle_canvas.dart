import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that renders an animated particle effect background.
/// 
/// Simulates 3D floating particles that move around and bounce off walls.
/// Replicates the 'ParticleCanvas' component from the React web app.
class ParticleCanvas extends StatefulWidget {
  const ParticleCanvas({super.key});

  @override
  State<ParticleCanvas> createState() => _ParticleCanvasState();
}

class _ParticleCanvasState extends State<ParticleCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    for (int i = 0; i < 80; i++) {
      _particles.add(_Particle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var particle in _particles) {
          particle.update();
        }
        return CustomPaint(
          painter: _ParticlePainter(_particles),
          child: Container(),
        );
      },
    );
  }
}

/// Represents a single particle in the simulation.
class _Particle {
  double x = 0;
  double y = 0;
  double z = 0;
  double vx = 0;
  double vy = 0;
  double vz = 0;
  double radius = 0;
  double opacity = 0;

  // Canvas dimensions are handled in painter/update
  // For initialization, we assume a normalized space or handle it during draw

  _Particle(Random random) {
    // Initial random values 
    // We'll map these to screen size in the painter or keep them abstract
    // React logic: x: random * width, y: random * height, z: random * 1000
    // Flutter: We can't know width/height in constructor easily without LayoutBuilder.
    // So we'll use normalized coordinates (0-1) and scale in painter.
    
    x = random.nextDouble();         // 0.0 to 1.0 (will multiply by width)
    y = random.nextDouble();         // 0.0 to 1.0 (will multiply by height)
    z = random.nextDouble() * 1000;  // 0 to 1000
    
    vx = (random.nextDouble() - 0.5) * 0.002; // Velocity relative to screen size
    vy = (random.nextDouble() - 0.5) * 0.002;
    vz = (random.nextDouble() - 0.5) * 4;     // Z velocity

    radius = random.nextDouble() * 2 + 1;
    opacity = random.nextDouble() * 0.5 + 0.3;
  }

  /// Updates the particle's position based on its velocity.
  void update() {
    x += vx;
    y += vy;
    z += vz;

    // Bounce off edges (normalized 0-1)
    if (x < 0 || x > 1) vx *= -1;
    if (y < 0 || y > 1) vy *= -1;
    if (z < 0 || z > 1000) vz *= -1;
  }
}

/// Custom painter to draw the particles on the canvas.
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background
    final paint = Paint()
      ..color = const Color.fromRGBO(5, 10, 5, 0.1) // #050a05 with low opacity
      ..style = PaintingStyle.fill;
    
    // We don't need to clear for "trails" effect if we want them, 
    // but React implementation draws a rectifier over everything:
    // ctx.fillStyle = 'rgba(5, 10, 5, 0.1)'; ctx.fillRect(0, 0, canvas.width, canvas.height);
    // In Flutter CustomPainter, we redraw every frame. 
    // To get trails, we'd need to draw to an offscreen image or just accept standard animation.
    // For now, standard animation (no trails).
    // Actually, React version just clears mostly but leaves trails? 
    // "ctx.fillRect(0, 0, canvas.width, canvas.height)" with 0.1 opacity effectively clears it slowly?
    // In CustomPainter, the canvas is fresh every frame. 
    // So distinct particles won't trail unless we simulate it. 
    // We will just draw particles.

    for (var particle in particles) {
      final scale = 1000 / (1000 + particle.z);
      
      final x2d = (particle.x * size.width) * scale + size.width / 2 * (1 - scale);
      final y2d = (particle.y * size.height) * scale + size.height / 2 * (1 - scale);
      final r = particle.radius * scale;

      final particlePaint = Paint()
        ..color = Color.fromRGBO(74, 222, 128, particle.opacity * scale) // #4ade80
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x2d, y2d), r, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
