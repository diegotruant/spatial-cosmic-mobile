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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
      borderRadius: 12,
      borderColor: accentColor.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70, // Slightly dimmer for better hierarchy
                  fontSize: 10, // Slightly smaller
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null)
                trailing!
              else if (icon != null)
                Icon(icon, color: accentColor.withOpacity(0.8), size: 12),
            ],
          ),
          const SizedBox(height: 4), // Replaced Spacer with small gap
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: isLarge ? 28 : 22, // Slightly smaller fonts
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
              if (unit != null && unit!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
