import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'glass_card.dart';

class SyncPlatformSelector extends StatelessWidget {
  final Function(String) onSelect;

  const SyncPlatformSelector({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          const Text(
            "ESPORTA FILE FIT",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0),
          ),
          const SizedBox(height: 32),
          
          _buildPlatformItem(
            icon: LucideIcons.download, 
            label: "Scarica file .fit", 
            subtitle: "Salva/Condividi file per Strava, Oura, ecc.",
            onTap: () => onSelect('export'),
            color: Colors.white70
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlatformItem({required IconData icon, required String label, String? subtitle, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        borderColor: color.withOpacity(0.2),
        color: color,
        opacity: 0.05,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
