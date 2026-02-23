import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'glass_card.dart';

class BigMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final Color? valueColor;
  final Color? backgroundColor; // New field
  final bool isHuge; // For the MAIN number (Power / Target)
  final double? labelFontSize;

  const BigMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    this.valueColor,
    this.backgroundColor, // New parameter
    this.isHuge = false,
    this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 16,
      borderColor: accentColor.withOpacity(0.3),
      color: backgroundColor, // Add this
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double labelSize = labelFontSize ?? 11;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label (Top Left)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.roboto(
                    color: Colors.white70,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Value (Takes remaining space)
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.contain,
                  child: Text(
                    value,
                    style: GoogleFonts.robotoMono(
                      color: valueColor ?? Colors.white,
                      fontSize: 100, 
                      fontWeight: FontWeight.w400, // Regular weight
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
              
              // Unit (Bottom Right)
              if (unit.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      unit,
                      style: GoogleFonts.roboto(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
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
