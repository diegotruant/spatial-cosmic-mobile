import 'package:flutter/material.dart';
import '../../services/workout_service.dart';
import '../../logic/zwo_parser.dart';
import 'package:provider/provider.dart';

class LiveWorkoutChart extends StatelessWidget {
  final bool isZoomed;
  final bool showPowerZones; // Added parameter

  const LiveWorkoutChart({super.key, this.isZoomed = false, this.showPowerZones = false});

  @override
  Widget build(BuildContext context) {
    final workoutService = context.watch<WorkoutService>();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _LiveGraphPainter(
            powerHistory: workoutService.powerHistory,
            hrHistory: workoutService.hrHistory,
            tempHistory: workoutService.tempHistory,
            currentWorkout: workoutService.currentWorkout,

            totalElapsed: workoutService.totalElapsed,
            isZoomed: isZoomed,
            intensityPercentage: workoutService.intensityPercentage,
            showPowerZones: showPowerZones,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _LiveGraphPainter extends CustomPainter {
  final List<double> powerHistory;
  final List<int> hrHistory;
  final List<double> tempHistory;
  final WorkoutWorkout? currentWorkout;
  final int totalElapsed;
  final bool isZoomed;
  final int intensityPercentage;
  final bool showPowerZones;

  _LiveGraphPainter({
    required this.powerHistory,
    required this.hrHistory,
    required this.tempHistory,
    required this.currentWorkout,
    required this.totalElapsed,
    required this.isZoomed,
    required this.intensityPercentage,
    required this.showPowerZones,
  });
  
  // Helper for Zone Colors
  Color _getZoneColor(double factor) {
    if (factor < 0.55) return Colors.grey;
    if (factor < 0.75) return Colors.blueAccent;
    if (factor < 0.90) return Colors.greenAccent;
    if (factor < 1.05) return Colors.yellowAccent;
    if (factor < 1.20) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate Scaling & Translation
    if (currentWorkout == null) return;
    
    final blocks = currentWorkout!.blocks;
    var totalWorkoutDuration = 0;
    for (var b in blocks) totalWorkoutDuration += b.duration;
    if (totalWorkoutDuration == 0) return;

    // View Window Logic
    final visibleDuration = isZoomed ? 600 : totalWorkoutDuration;
    final secToX = size.width / visibleDuration;
    final wattToY = size.height / 500; // 500W max scale
    final hrToY = size.height / 220; // 220 BPM max
    
    // Scrolling Logic
    double scrollOffset = 0.0;
    if (isZoomed) {
       final headStart = 120; // 2 minutes padding on left
       if (totalElapsed > headStart) {
         scrollOffset = (totalElapsed - headStart) * secToX;
       }
    }

    canvas.save();
    canvas.translate(-scrollOffset, 0);

    // 2. Draw Grid & Blocks (Background)
    
    // Draw Grid Lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.0;
    
    for (var i = 1; i < 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(scrollOffset, y), Offset(scrollOffset + size.width, y), gridPaint);
    }

    // Draw Blocks
    var currentX = 0.0;
    final double intensityFactor = intensityPercentage / 100.0;

    for (var block in blocks) {
      final w = block.duration * secToX;
      
      // Optimization: Only draw if visible
      if (currentX + w < scrollOffset || currentX > scrollOffset + size.width) {
        currentX += w;
        continue;
      }

      double basePower = 0.0;
      if (block is SteadyState) basePower = block.power;
      else if (block is IntervalsT) basePower = block.onPower; 

      // Height for 100% (Ghost)
      final h100 = basePower * 300 * wattToY; // Assuming target usually ~300 max relative? No basePower is factor 0.0-2.0 usually. 
      // Wait, standard zwo parser: power is factor of FTP (e.g. 0.5, 1.0).
      // If basePower is factor, we need to map to Y pixels.
      // If we assumed 500W max scale, and userFtp is e.g. 200W. 
      // Then target Watts = factor * FTP.
      // We don't have FTP here efficiently.
      // But typically we graph relative to FTP? Or absolute watts?
      // The original code used `basePower * 300 * wattToY`.
      // If `wattToY = H / 500`. And basePower = 1.0. Height = 300 * (H/500) = 0.6 H.
      // That assumes FTP is roughly 300W for visual scaling? 
      // Let's stick to original scaling logic to avoid breaking it, just change colors.
      
      final y100 = size.height - h100;

      // Height for Adjusted
      final hAdj = h100 * intensityFactor;
      final yAdj = size.height - hAdj;
      
      // Determine Color
      Color blockColor = const Color(0xFF00B0FF);
      Color borderColor = Colors.cyanAccent;
      
      if (showPowerZones) {
         // Use adjusted power factor to determine color
         // basePower is standard factor. Adjusted is basePower * intensityFactor.
         double effectiveFactor = basePower * intensityFactor;
         Color zoneColor = _getZoneColor(effectiveFactor);
         blockColor = zoneColor;
         borderColor = zoneColor;
      }

      // Draw Ghost (if intensity changed)
      if (intensityPercentage != 100) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, y100, w, h100), 
          Paint()..color = Colors.white.withOpacity(0.1) 
        );
        canvas.drawLine(
           Offset(currentX, y100), 
           Offset(currentX + w, y100), 
           Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 1
        );
      }

      // Draw Active Block (Adjusted)
      if (block is SteadyState) {
        canvas.drawRect(Rect.fromLTWH(currentX, yAdj, w, hAdj), Paint()..color = blockColor.withOpacity(0.4));
        canvas.drawLine(Offset(currentX, yAdj), Offset(currentX + w, yAdj), Paint()..color = borderColor.withOpacity(0.8)..strokeWidth = 2);
      } else if (block is IntervalsT) {
         final onH = (block.onPower * 300 * wattToY) * intensityFactor;
         final yOn = size.height - onH;
         
         double effectiveOnFactor = block.onPower * intensityFactor;
         Color onColor = showPowerZones ? _getZoneColor(effectiveOnFactor) : const Color(0xFF40C4FF);
         
         canvas.drawRect(Rect.fromLTWH(currentX, yOn, w, onH), Paint()..color = onColor.withOpacity(0.25));
      }
      currentX += w;
    }

    // 3. Draw Curves (History)
    
    // Power (Cyan)
    _drawPath(canvas, powerHistory, secToX, wattToY, size, scrollOffset, const Color(0xFF00E5FF), 3.0, true, Colors.white);

    // Heart Rate (Red)
    _drawPath(canvas, hrHistory.map((e) => e.toDouble()).toList(), secToX, hrToY, size, scrollOffset, Colors.redAccent, 2.0, false, null);

    // Temperature (Green - Scaled 36-41 -> 0-Height)
    if (tempHistory.isNotEmpty) {
      final tempPath = Path();
      bool first = true;
      for (int i=0; i<tempHistory.length; i++) {
        final x = i * secToX;
        if (x < scrollOffset - 10 || x > scrollOffset + size.width + 10) continue;
        
        final val = tempHistory[i];
        final norm = (val - 36.0) / 4.0; // 36-40 range
        final y = size.height - (norm * size.height);
        
        if (first || i==0) { tempPath.moveTo(x, y); first = false; }
        else tempPath.lineTo(x, y);
      }
      canvas.drawPath(tempPath, Paint()..color = Colors.purpleAccent..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }
    
    // Draw Bottom Axis (Time Labels)
    _drawBottomAxis(canvas, size, scrollOffset, secToX);

    canvas.restore();
    
    // 4. Fixed Overlays (Right Axis) - Painted AFTER restore() so they don't scroll
    _drawRightAxis(canvas, size);
  }

  void _drawBottomAxis(Canvas canvas, Size size, double scrollOffset, double secToX) {
     final visibleDuration = size.width / secToX;
     int stepSeconds = 300; // Default 5 min
     if (visibleDuration <= 1200) stepSeconds = 120; // If <= 20 min view, use 2 min
     
     final startSec = (scrollOffset / secToX).floor();
     final endSec = ((scrollOffset + size.width) / secToX).ceil();
     
     // Align start to step
     // e.g. if step is 120, and start is 130. Next multiple is 240.
     // We want first multiple >= startSec.
     int currentSec = (startSec ~/ stepSeconds) * stepSeconds;
     if (currentSec < startSec) currentSec += stepSeconds;
     
     final textPainter = TextPainter(textDirection: TextDirection.ltr);
     final linePaint = Paint()..color = Colors.white.withOpacity(0.1)..strokeWidth = 1;

     while (currentSec <= endSec) {
        final x = currentSec * secToX;
        
        // Draw Vertical Line
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
        
        // Draw Label
        final minutes = currentSec ~/ 60;
        textPainter.text = TextSpan(
           text: '${minutes}m',
           style: const TextStyle(color: Colors.white54, fontSize: 10)
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 4, size.height - 14));
        
        currentSec += stepSeconds;
     }
  }

  void _drawPath(Canvas canvas, List<double> data, double secToX, double valToY, Size size, double scrollOffset, Color color, double width, bool glow, Color? coreColor) {
    if (data.isEmpty) return;
    final path = Path();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    
    if (glow) paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    bool first = true;
    for (var i = 0; i < data.length; i++) {
      final x = i * secToX;
      if (x < scrollOffset - 10 || x > scrollOffset + size.width + 10) continue;

      final y = size.height - (data[i] * valToY);
      if (first || i == 0) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    
    if (coreColor != null) {
       canvas.drawPath(path, Paint()..color = coreColor..style = PaintingStyle.stroke..strokeWidth = width * 0.5);
    }
  }

  void _drawRightAxis(Canvas canvas, Size size) {
    // Background for labels?
    
    // HR Labels (Red) - 0 to 220
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final hrSteps = [50, 90, 130, 170, 210];
    
    for (var val in hrSteps) {
      final y = size.height - (val / 220 * size.height);
      textPainter.text = TextSpan(
        text: val.toString(), 
        style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 25, y - 6));
      
      // Tick mark
      canvas.drawCircle(Offset(size.width - 4, y), 2, Paint()..color = Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveGraphPainter oldDelegate) => 
      oldDelegate.totalElapsed != totalElapsed || 
      oldDelegate.isZoomed != isZoomed ||
      oldDelegate.intensityPercentage != intensityPercentage;
}
