import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnaerobicBatteryGauge extends StatelessWidget {
  final double currentWPrime; // Joule rimanenti
  final double maxWPrime;     // Joule totali (capacità massima)
  final bool isDepleting;    // Se l'atleta è sopra CP

  const AnaerobicBatteryGauge({
    super.key,
    required this.currentWPrime,
    required this.maxWPrime,
    required this.isDepleting,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (maxWPrime > 0) 
        ? (currentWPrime / maxWPrime).clamp(0.0, 1.0) 
        : 0.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: BatteryPainter(
                  percentage: percentage,
                  color: isDepleting ? Colors.orangeAccent : Colors.greenAccent,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${(percentage * 100).toInt()}%",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text("W' RESIDUA", style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isDepleting ? "CONSUMO RISERVA!" : "RICARICA IN CORSO...",
          style: TextStyle(
            color: isDepleting ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class BatteryPainter extends CustomPainter {
  final double percentage;
  final Color color;

  BatteryPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width / 2, size.height / 2) - 6; // Subtract half stroke width to fit

    // Disegna lo sfondo grigio (arco completo)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Disegna il progresso della batteria (arco colorato)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      (math.pi * 1.5) * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
