import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/workout_service.dart';
import '../../logic/zwo_parser.dart';
import 'package:provider/provider.dart';

class LiveWorkoutChart extends StatelessWidget {
  final bool isZoomed;
  final bool showPowerZones; // Added parameter
  final double? wPrime;
  final int? cp;
  final int userFtp;

  const LiveWorkoutChart({
    super.key, 
    this.isZoomed = false, 
    this.showPowerZones = false,
    this.wPrime,
    this.cp,
    required this.userFtp,
  });

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
            wPrime: wPrime,
            cp: cp,
            userFtp: userFtp,
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
  final double? wPrime;
  final int? cp;
  final int userFtp;

  _LiveGraphPainter({
    required this.powerHistory,
    required this.hrHistory,
    required this.tempHistory,
    required this.currentWorkout,
    required this.totalElapsed,
    required this.isZoomed,
    required this.intensityPercentage,
    required this.showPowerZones,
    this.wPrime,
    this.cp,
    required this.userFtp,
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

    // Power scaling based on athlete FTP so che blocchi e linea coincidono a 100%
    final double ftp = userFtp > 0 ? userFtp.toDouble() : 250.0;
    final double maxPower = max(ftp * 1.5, 400.0); // un po' sopra FTP per margine
    final wattToY = size.height / maxPower;
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

      double baseFactor = 0.0;
      if (block is SteadyState) baseFactor = block.power;
      else if (block is IntervalsT) baseFactor = block.onPower; 

      // Target watts a 100% e con intensità applicata
      final double targetW100 = baseFactor * ftp;
      final double h100 = targetW100 * wattToY;
      final double y100 = size.height - h100;

      final double targetWAdj = targetW100 * intensityFactor;
      final double hAdj = targetWAdj * wattToY;
      final double yAdj = size.height - hAdj;
      
      // Determine Color
      Color blockColor = const Color(0xFF00B0FF);
      Color borderColor = Colors.cyanAccent;
      
      if (showPowerZones) {
         // Usa il fattore di potenza relativo (ZWO) scalato per l'intensità
         double effectiveFactor = baseFactor * intensityFactor;
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

      // Draw Active Block (Adjusted) con colori PIÙ INTENSI e BORDI DEFINITI
      if (block is SteadyState) {
        canvas.drawRect(Rect.fromLTWH(currentX, yAdj, w, hAdj), Paint()..color = blockColor.withOpacity(0.55));
        canvas.drawRect(Rect.fromLTWH(currentX, yAdj, w, hAdj), Paint()..color = borderColor.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.0);
        canvas.drawLine(Offset(currentX, yAdj), Offset(currentX + w, yAdj), Paint()..color = borderColor.withOpacity(0.9)..strokeWidth = 3.5);
      } else if (block is IntervalsT) {
         final double onTargetW = block.onPower * ftp * intensityFactor;
         final double onH = onTargetW * wattToY;
         final double yOn = size.height - onH;
         
         double effectiveOnFactor = block.onPower * intensityFactor;
         Color onColor = showPowerZones ? _getZoneColor(effectiveOnFactor) : const Color(0xFF40C4FF);
         
         // On Interval
         canvas.drawRect(Rect.fromLTWH(currentX, yOn, w, onH), Paint()..color = onColor.withOpacity(0.45));
         canvas.drawLine(Offset(currentX, yOn), Offset(currentX + w, yOn), Paint()..color = onColor..strokeWidth = 3.5);
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

    // 4. Draw W' Balance (if available) - Red Dashed/Solid Line
    if (wPrime != null && cp != null && wPrime! > 0 && cp! > 0) {
      final wBalData = <double>[];
      double currentWBal = wPrime!;

      // Calculate W' history
      for (final p in powerHistory) {
         // Integral model: delta = CP - Power
         // If Power > CP, deplete. If Power < CP, recharge.
         double delta = cp! - p;
         currentWBal += delta;
         if (currentWBal > wPrime!) currentWBal = wPrime!;
         wBalData.add(currentWBal);
      }
      
      // Draw W' line (Scale 0 to WPrime maps to Height)
      // We overlay it? Or use a small dedicated area?
      // User request: "mostri la deplezione W'".
      // Overlaying on the main graph with a separate scale (0-100% of W') is standard.
      // Let's map 0 W' to Bottom, 100% W' to Top (or maybe 80% height to assume full)
      
      if (wBalData.isNotEmpty) {
        final wPath = Path();
        final wPaint = Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        bool firstW = true;
        for (int i = 0; i < wBalData.length; i++) {
           final x = i * secToX;
           if (x < scrollOffset - 10 || x > scrollOffset + size.width + 10) continue;
           
           // Normalize W' (0 to wPrime) to Y (Height to 0)
           // 100% W' = Top of chart? Or separate axis?
           // Let's use the full height range: 0% at bottom, 100% at top.
           final pct = wBalData[i] / wPrime!;
           final y = size.height - (pct * size.height); // 1.0 -> 0 (Top), 0.0 -> Height (Bottom)
           
           if (firstW) { wPath.moveTo(x, y); firstW = false; }
           else wPath.lineTo(x, y);
        }
        
        canvas.drawPath(wPath, wPaint);
        
        // Label for W' (Current Value)
        if (wBalData.isNotEmpty) {
             final lastVal = wBalData.last;
             final pct = (lastVal / wPrime!) * 100;
             final text = "W' ${lastVal.toInt()}J (${pct.toStringAsFixed(0)}%)";
             
             final tp = TextPainter(
                text: TextSpan(text: text, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                textDirection: TextDirection.ltr
             );
             tp.layout();
             tp.paint(canvas, Offset(size.width - 80, 10)); // Top right
        }
      }
    }
    
    // Draw Bottom Axis (Time Labels)
    _drawBottomAxis(canvas, size, scrollOffset, secToX);

    canvas.restore();
    
    // 4. Fixed Overlays (Right Axis) - Painted AFTER restore() so they don't scroll
    _drawLeftTempAxis(canvas, size);
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
           text: '$minutes',
           style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)
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

  void _drawLeftTempAxis(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final tempSteps = [36, 37, 38, 39, 40];

    for (var val in tempSteps) {
      final y = size.height - ((val - 36) / 4 * size.height);
      textPainter.text = TextSpan(
        text: val.toString(),
        style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(12, y - 6));

      // Tick mark
      canvas.drawCircle(Offset(2, y), 1.5, Paint()..color = Colors.purpleAccent);
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
      // Disegniamo il valore sul lato destro, vicino al tick HR
      final labelX = size.width - 32;
      textPainter.paint(canvas, Offset(labelX, y - 6));
      
      // Tick mark a destra
      canvas.drawCircle(Offset(size.width - 4, y), 2, Paint()..color = Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveGraphPainter oldDelegate) => 
      oldDelegate.totalElapsed != totalElapsed || 
      oldDelegate.isZoomed != isZoomed ||
      oldDelegate.intensityPercentage != intensityPercentage;
}









