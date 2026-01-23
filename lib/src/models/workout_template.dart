class WorkoutTemplate {
  final String id;
  final String title;
  final String description;
  final int durationSeconds;
  final int tss;
  final String category; // 'Test', 'Endurance', 'Intervals'
  final String zwoContent; // The raw XML content
  final Map<String, dynamic>? structure; // JSON structure fallback

  WorkoutTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.tss,
    required this.category,
    required this.zwoContent,
    this.structure,
  });
}
