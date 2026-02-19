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

  const LiveWorkoutChart({
    super.key, 
    this.isZoomed = false, 
    this.showPowerZones = false,
    this.wPrime,
    this.cp,
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
            currentWorkoutTime: workoutService.currentWorkoutTime, // NEW
            workoutTimeHistory: workoutService.workoutTimeHistory, // NEW
            
            isZoomed: isZoomed,
            intensityPercentage: workoutService.intensityPercentage,
            showPowerZones: showPowerZones,
            wPrime: wPrime,
            cp: cp,
            userFtp: workoutService.userFtp, // Read from service
            currentBlockIndex: workoutService.currentBlockIndex, // Read from service
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
  final int currentWorkoutTime; // NEW
  final List<int> workoutTimeHistory; // NEW
  
  final bool isZoomed;
  final int intensityPercentage;
  final bool showPowerZones;
  final double? wPrime;
  final int? cp;
  final int userFtp;
  final int currentBlockIndex; // NEW

  _LiveGraphPainter({
    required this.powerHistory,
    required this.hrHistory,
    required this.tempHistory,
    required this.currentWorkout,
    required this.totalElapsed,
    required this.currentWorkoutTime,
    required this.workoutTimeHistory,
    required this.isZoomed,
    required this.intensityPercentage,
    required this.showPowerZones,
    this.wPrime,
    this.cp,
    required this.userFtp,
    required this.currentBlockIndex,
  });
  
  // Helper for Zone Colors
  // Helper for Zone Colors
  Color _getZoneColor(double factor) {
    return WorkoutService.getZoneColor(factor);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (currentWorkout == null) return;
    
    final blocks = currentWorkout!.blocks;
    var totalWorkoutDuration = 0;
    for (var b in blocks) {
      totalWorkoutDuration += b.duration;
    }
    if (totalWorkoutDuration == 0) return;

    // View Window Logic
    final visibleDuration = isZoomed ? 600 : totalWorkoutDuration;
    final secToX = size.width / visibleDuration;

    // Power scaling
    final double ftp = userFtp > 0 ? userFtp.toDouble() : 250.0;
    final double maxPower = max(ftp * 1.5, 400.0);
    final wattToY = size.height / maxPower;
    final hrToY = size.height / 220;
    
    // Scrolling Logic
    double scrollOffset = 0.0;
    if (isZoomed) {
       // Keep cursor at 1/3 of screen width (200s out of 600s)
       const centerOffset = 200; 
       if (currentWorkoutTime > centerOffset) {
         scrollOffset = (currentWorkoutTime - centerOffset) * secToX;
       }
    }

    canvas.save();
    canvas.translate(-scrollOffset, 0);

    // 2. Draw Grid & Blocks
    final double intensityFactor = intensityPercentage / 100.0;

    // Highlight Current Block Area (Subtle Background)
    double currentHighlightX = 0;
    for (int i=0; i<currentBlockIndex && i<blocks.length; i++) {
       currentHighlightX += blocks[i].duration * secToX;
    }
    if (currentBlockIndex < blocks.length) {
       final highlightW = blocks[currentBlockIndex].duration * secToX;
       if (currentHighlightX + highlightW >= scrollOffset && currentHighlightX <= scrollOffset + size.width) {
          final highlightPaint = Paint()..color = Colors.white.withOpacity(0.03)..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromLTWH(currentHighlightX, 0, highlightW, size.height), highlightPaint);
          
          // Top Line highlight
          canvas.drawLine(Offset(currentHighlightX, 0), Offset(currentHighlightX + highlightW, 0), Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 2.0);
       }
    }

    // Draw Horizontal Grid Lines (e.g. 5 lines)
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1.0;
    for (var i = 1; i < 5; i++) {
        double yPos = size.height * (i / 5.0);
        canvas.drawLine(Offset(scrollOffset, yPos), Offset(scrollOffset + size.width, yPos), gridPaint);
    }

    // Draw Blocks
    double currentX = 0.0;
    for (var block in blocks) {
      final w = block.duration * secToX;
      
      // Optimization: Only draw if visible (careful with repeats inside intervals)
      if (block is! IntervalsT && (currentX + w < scrollOffset || currentX > scrollOffset + size.width)) {
        currentX += w;
        continue;
      }

      // Handle Types
      if (block is SteadyState) {
        final double targetW = block.power * ftp * intensityFactor; 
        final double h = targetW * wattToY;
        final double y = size.height - h;
        
        Color blockColor = showPowerZones ? _getZoneColor(block.power * intensityFactor) : const Color(0xFF00B0FF);
        
        canvas.drawRect(Rect.fromLTWH(currentX, y, w, h), Paint()..color = blockColor.withOpacity(0.55));
        canvas.drawLine(Offset(currentX, y), Offset(currentX + w, y), Paint()..color = blockColor..strokeWidth = 2.0);
        
      } else if (block is Ramp) {
         final double startW = block.powerLow * ftp * intensityFactor;
         final double endW = block.powerHigh * ftp * intensityFactor;
         final double hStart = startW * wattToY;
         final double hEnd = endW * wattToY;
         final double yStart = size.height - hStart;
         final double yEnd = size.height - hEnd;
         
         double avgFactor = (block.powerLow + block.powerHigh) / 2 * intensityFactor;
         Color rampColor = showPowerZones ? _getZoneColor(avgFactor) : const Color(0xFFFFAB40);
         
         final rampPath = Path();
         rampPath.moveTo(currentX, yStart);
         rampPath.lineTo(currentX + w, yEnd);
         rampPath.lineTo(currentX + w, size.height);
         rampPath.lineTo(currentX, size.height);
         rampPath.close();
         
         canvas.drawPath(rampPath, Paint()..color = rampColor.withOpacity(0.55));
         canvas.drawLine(Offset(currentX, yStart), Offset(currentX + w, yEnd), Paint()..color = rampColor..strokeWidth = 2.0);

      } else if (block is IntervalsT) {
         // Loop for repeats
         for (int r = 0; r < block.repeat; r++) {
            // ON
            double wOn = block.onDuration * secToX;
            double hOn = block.onPower * ftp * intensityFactor * wattToY;
            double yOn = size.height - hOn;
            Color onColor = showPowerZones ? _getZoneColor(block.onPower * intensityFactor) : const Color(0xFF40C4FF);
            
            if (currentX + wOn >= scrollOffset && currentX <= scrollOffset + size.width) {
               canvas.drawRect(Rect.fromLTWH(currentX, yOn, wOn, hOn), Paint()..color = onColor.withOpacity(0.45));
               canvas.drawLine(Offset(currentX, yOn), Offset(currentX + wOn, yOn), Paint()..color = onColor..strokeWidth = 3.5);
            }
            currentX += wOn;
            
            // OFF
            double wOff = block.offDuration * secToX;
            double hOff = block.offPower * ftp * intensityFactor * wattToY;
            double yOff = size.height - hOff;
            Color offColor = showPowerZones ? _getZoneColor(block.offPower * intensityFactor) : Colors.grey;
            
            if (currentX + wOff >= scrollOffset && currentX <= scrollOffset + size.width) {
               canvas.drawRect(Rect.fromLTWH(currentX, yOff, wOff, hOff), Paint()..color = offColor.withOpacity(0.3));
               canvas.drawLine(Offset(currentX, yOff), Offset(currentX + wOff, yOff), Paint()..color = offColor..strokeWidth = 2.0);
            }
            currentX += wOff;
         }
         continue; // Handled currentX increment inside loop
      }
      else if (block is FreeRide) {
         // Free Ride Block - Draw as a distinct visual element (e.g. Grey block)
         // We can't really map it to power, so we'll draw it at a "nominal" height (e.g. 150W or 50% FTP) 
         // or just tint the background for that section.
         // Let's draw a dotted box or gradient.
         
         double h = size.height * 0.4; // Fixed visual height (40% of screen)
         double y = size.height - h;
         
         final rect = Rect.fromLTWH(currentX, 0, w, size.height);
         canvas.drawRect(rect, Paint()..color = Colors.grey.withOpacity(0.15));
         
         // Draw "Free Ride" Text? Too complex for custom painter without text painter optimization.
         // Just a simple dashed line at the "nominal" power.
         final linePaint = Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0;
         double dashWidth = 5, dashSpace = 5;
         double startX = currentX;
         while (startX < currentX + w) {
            canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), linePaint);
            startX += dashWidth + dashSpace;
         }

      }
      
      currentX += w;
    }

    // 3. Draw Curves (History)
    
    // Power (Cyan)
    _drawPath(canvas, powerHistory, workoutTimeHistory, secToX, wattToY, size, scrollOffset, const Color(0xFF00E5FF), 3.0, true, Colors.white);

    // Heart Rate (Red)
    _drawPath(canvas, hrHistory.map((e) => e.toDouble()).toList(), workoutTimeHistory, secToX, hrToY, size, scrollOffset, Colors.redAccent, 2.0, false, null);

    // Temperature (Green - Scaled 36-41 -> 0-Height)
    if (tempHistory.isNotEmpty) {
      final tempPath = Path();
      bool first = true;
      for (int i=0; i<tempHistory.length; i++) {
        // Use history if available
        final xVal = (i < workoutTimeHistory.length) ? workoutTimeHistory[i] : i;
        final x = xVal * secToX;
        
        if (x < scrollOffset - 10 || x > scrollOffset + size.width + 10) continue;
        
        final val = tempHistory[i];
        final norm = (val - 36.0) / 4.0; // 36-40 range
        final y = size.height - (norm * size.height);
        
        if (first) { 
           tempPath.moveTo(x, y); first = false; 
        } else {
           // Gap Detection
           if (i > 0 && i < workoutTimeHistory.length && (workoutTimeHistory[i] - workoutTimeHistory[i-1] > 1)) {
              tempPath.moveTo(x, y);
           } else {
              tempPath.lineTo(x, y);
           }
        }
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
      
      if (wBalData.isNotEmpty) {
        final wPath = Path();
        final wPaint = Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        bool firstW = true;
        for (int i = 0; i < wBalData.length; i++) {
           // Use history if available
           final xVal = (i < workoutTimeHistory.length) ? workoutTimeHistory[i] : i;
           final x = xVal * secToX;

           if (x < scrollOffset - 10 || x > scrollOffset + size.width + 10) continue;
           
           // Normalize W' (0 to wPrime) to Y (Height to 0)
           final pct = wBalData[i] / wPrime!;
           final y = size.height - (pct * size.height); // 1.0 -> 0 (Top), 0.0 -> Height (Bottom)
           
           if (firstW) { 
              wPath.moveTo(x, y); firstW = false; 
           } else {
              // Gap Detection
              if (i > 0 && i < workoutTimeHistory.length && (workoutTimeHistory[i] - workoutTimeHistory[i-1] > 1)) {
                 wPath.moveTo(x, y);
              } else {
                 wPath.lineTo(x, y);
              }
           }
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

    // 5. Draw Cursor Line (Current Position)
    final cursorX = currentWorkoutTime * secToX; // CHANGED to currentWorkoutTime
    if (cursorX >= scrollOffset && cursorX <= scrollOffset + size.width) {
       final cursorPaint = Paint()
         ..color = Colors.white
         ..strokeWidth = 2.0
         ..style = PaintingStyle.stroke;
       
       // Dashed Line
       double dashY = 0;
       while (dashY < size.height) {
         canvas.drawLine(Offset(cursorX, dashY), Offset(cursorX, dashY + 5), cursorPaint);
         dashY += 10;
       }
       
       // Optional: Triangle/Circle at bottom?
       canvas.drawCircle(Offset(cursorX, size.height), 4, Paint()..color = Colors.white);
    }

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

  void _drawPath(Canvas canvas, List<double> data, List<int>? xValues, double secToX, double valToY, Size size, double scrollOffset, Color color, double width, bool glow, Color? coreColor) {
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
      // Determine X: either use history or index (fallback)
      final xVal = (xValues != null && i < xValues.length) ? xValues[i] : i;
      final x = xVal * secToX;
      
      if (x < scrollOffset - 10 || x > scrollOffset + size.width + 10) continue;

      final y = size.height - (data[i] * valToY);
      
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        // GAP DETECTION (TrainerDay Style): If X jumps by more than 1 second, move to new X
        if (xValues != null && i > 0 && (xValues[i] - xValues[i-1] > 1)) {
           path.moveTo(x, y);
        } else {
           path.lineTo(x, y);
        }
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
  bool shouldRepaint(_LiveGraphPainter oldDelegate) {
    return oldDelegate.totalElapsed != totalElapsed || 
           oldDelegate.currentWorkoutTime != currentWorkoutTime || // NEW
           oldDelegate.isZoomed != isZoomed ||
           oldDelegate.intensityPercentage != intensityPercentage ||
           oldDelegate.currentBlockIndex != currentBlockIndex;
  }
}
