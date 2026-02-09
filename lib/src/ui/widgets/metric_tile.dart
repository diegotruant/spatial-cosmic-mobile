import 'package:flutter/material.dart';
import 'glass_card.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Widget? trailing;
  final Color accentColor;
  final Color? valueColor; // NEW: Optional custom color for value text
  final bool isLarge;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.trailing,
    this.accentColor = Colors.cyanAccent,
    this.valueColor, // NEW
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reduced padding to 8
      borderRadius: 12,
      borderColor: accentColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label in alto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else if (icon != null)
                Icon(icon, color: accentColor.withOpacity(0.8), size: 12),
            ],
          ),
          const SizedBox(height: 4),
          // Valore al centro
          Expanded( // Added Expanded to fill vertical space if needed, or just let FittedBox handle it
             child: Align(
               alignment: Alignment.centerLeft,
               child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: isLarge ? 26 : 20,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color: (valueColor ?? accentColor).withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
             ),
          ),
          // Unità sotto il valore (invece che a fianco)
          // Unità sotto il valore (invece che a fianco)
          if (unit != null && unit!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              unit!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
