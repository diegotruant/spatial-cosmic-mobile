import 'package:flutter/material.dart';
import 'glass_card.dart';

class BigMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final Color? valueColor;
  final bool isHuge; // For the MAIN number (Power / Target)

  const BigMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    this.valueColor,
    this.isHuge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 16,
      borderColor: accentColor.withOpacity(0.3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic sizing based on height
          double labelSize = isHuge ? 14 : 11;
          double valueSize = isHuge ? constraints.maxHeight * 0.55 : constraints.maxHeight * 0.45;
          // Clamp value size
          if (valueSize > 80) valueSize = 80;
          if (valueSize < 24) valueSize = 24;

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label (Top Left)
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: labelSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Value (Bottom Left - Aligned)
              SizedBox(
                height: valueSize,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.contain,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 100, // FittedBox will scale this down
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 15,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              // Unit (Bottom Right absolute or inline?)
              // Let's keep it simple: if unit exists, show it small next to 
              if (unit.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      unit,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
            ],
          );
        }
      ),
    );
  }
}
