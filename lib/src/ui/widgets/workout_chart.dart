import 'package:flutter/material.dart';
import '../../logic/zwo_parser.dart';

class WorkoutChart extends StatelessWidget {
  final WorkoutWorkout? workout;
  const WorkoutChart({super.key, this.workout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(
        painter: _NeonGraphPainter(workout: workout),
      ),
    );
  }
}

class _NeonGraphPainter extends CustomPainter {
  final WorkoutWorkout? workout;
  _NeonGraphPainter({this.workout});

  @override
  void paint(Canvas canvas, Size size) {
    if (workout == null || workout!.blocks.isEmpty) {
      // Draw background/empty state if needed
      return;
    }

    final blockPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    // Calculate total duration for scaling X axis
    int totalDuration = workout!.blocks.fold(0, (sum, b) => sum + b.duration);
    if (totalDuration == 0) return;

    var currentX = 0.0;
    final path = Path();
    path.moveTo(0, size.height);

    for (final block in workout!.blocks) {
      final w = (block.duration / totalDuration) * size.width;
      double hStartRatio = 0.0;
      double hEndRatio = 0.0;
      
      if (block is SteadyState) {
        hStartRatio = block.power;
        hEndRatio = block.power;
      } else if (block is Ramp) {
        hStartRatio = block.powerLow;
        hEndRatio = block.powerHigh;
      } else if (block is IntervalsT) {
        hStartRatio = block.onPower; 
        hEndRatio = block.onPower;
      }

      final yStart = size.height - (hStartRatio * size.height);
      final yEnd = size.height - (hEndRatio * size.height);

      // Block fill path (polygon)
      final fillPath = Path();
      fillPath.moveTo(currentX, size.height);
      fillPath.lineTo(currentX, yStart);
      fillPath.lineTo(currentX + w, yEnd);
      fillPath.lineTo(currentX + w, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, blockPaint..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.2),
          const Color(0xFF00E5FF).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(currentX, min(yStart, yEnd), w, size.height - min(yStart, yEnd))));

      path.lineTo(currentX, yStart);
      path.lineTo(currentX + w, yEnd);
      
      currentX += w;
    }
    path.lineTo(size.width, size.height);
    
    // Draw neon outline
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonGraphPainter oldDelegate) => oldDelegate.workout != workout;
}
