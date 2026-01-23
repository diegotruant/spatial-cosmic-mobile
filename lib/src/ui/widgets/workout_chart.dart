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
      double hRatio = 0.0;
      
      if (block is SteadyState) {
        hRatio = block.power;
      } else if (block is IntervalsT) {
        // For intervals, we'll draw the simplified "on" power representative block 
        // Or we could expand them, but let's keep it simple for the dashboard chart
        hRatio = block.onPower; 
      }

      final h = hRatio * size.height;
      final y = size.height - h;

      path.lineTo(currentX, y);
      path.lineTo(currentX + w, y);
      
      // Block fill
      final rect = Rect.fromLTWH(currentX, y, w, h);
      canvas.drawRect(rect, blockPaint..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E5FF).withOpacity(0.2),
          const Color(0xFF00E5FF).withOpacity(0.05),
        ],
      ).createShader(rect));

      currentX += w;
    }
    path.lineTo(size.width, size.height);
    
    // Draw neon outline
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonGraphPainter oldDelegate) => oldDelegate.workout != workout;
}
