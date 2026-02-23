import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnaerobicBatteryGauge extends StatelessWidget {
  final double currentWPrime; // Joule rimanenti
  final double maxWPrime;     // Joule totali (capacità massima assoluta)
  final double dynamicMaxWPrime; // Joule totali dinamici (Stamina Potenziale)
  final bool isDepleting;    // Se l'atleta è sopra CP

  const AnaerobicBatteryGauge({
    super.key,
    required this.currentWPrime,
    required this.maxWPrime,
    required this.dynamicMaxWPrime,
    required this.isDepleting,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (maxWPrime > 0) 
        ? (currentWPrime / maxWPrime).clamp(0.0, 1.0) 
        : 0.0;
    double potentialPercentage = (maxWPrime > 0)
        ? (dynamicMaxWPrime / maxWPrime).clamp(0.0, 1.0)
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
                  potentialPercentage: potentialPercentage,
                  color: isDepleting ? Colors.orangeAccent : Colors.greenAccent,
                  strokeWidth: 12,
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
  final double potentialPercentage;
  final Color color;
  final double strokeWidth;

  BatteryPainter({
    required this.percentage,
    required this.potentialPercentage,
    required this.color,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    Paint potentialPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.5) // Colore per il tetto massimo (Stamina Potenziale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width / 2, size.height / 2) - 6; // Subtract half stroke width to fit

    // Disegna lo sfondo grigio (arco completo al 100%)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Disegna il tetto della Stamina Potenziale (arco semitrasparente che si accorcia col tempo)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      (math.pi * 1.5) * potentialPercentage,
      false,
      potentialPaint,
    );

    // Disegna il progresso della batteria (arco colorato - Stamina Attuale)
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

class CompactWPrimeGauge extends StatelessWidget {
  final double currentWPrime;
  final double maxWPrime;
  final double dynamicMaxWPrime;
  final bool isDepleting;
  final double size;

  const CompactWPrimeGauge({
    super.key,
    required this.currentWPrime,
    required this.maxWPrime,
    required this.dynamicMaxWPrime,
    required this.isDepleting,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (maxWPrime > 0)
        ? (currentWPrime / maxWPrime).clamp(0.0, 1.0)
        : 0.0;
    final potentialPercentage = (maxWPrime > 0)
        ? (dynamicMaxWPrime / maxWPrime).clamp(0.0, 1.0)
        : 0.0;
    final color = isDepleting ? Colors.orangeAccent : Colors.greenAccent;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: BatteryPainter(
              percentage: percentage,
              potentialPercentage: potentialPercentage,
              color: color,
              strokeWidth: 6,
            ),
          ),
          Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
