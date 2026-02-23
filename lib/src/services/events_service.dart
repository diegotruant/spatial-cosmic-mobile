import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum EventType { race, test, objective, note, other }

class AthleteEvent {
  final String id;
  final String athleteId;
  final String title;
  final DateTime date;
  final EventType type;
  final String? description;

  AthleteEvent({
    required this.id,
    required this.athleteId,
    required this.title,
    required this.date,
    required this.type,
    this.description,
  });

  factory AthleteEvent.fromJson(Map<String, dynamic> json) {
    return AthleteEvent(
      id: json['id'],
      athleteId: json['athlete_id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      type: EventType.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['type'] as String).toUpperCase(),
        orElse: () => EventType.other,
      ),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athlete_id': athleteId,
      'title': title,
      'date': date.toIso8601String().split('T')[0],
      'type': type.name.toUpperCase(),
      'description': description,
    };
  }
}

class EventsService extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;
  
  List<AthleteEvent> _events = [];
  bool _isLoading = false;

  List<AthleteEvent> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;

  String? _athleteId;

  void updateAthleteId(String? id) {
    if (id != _athleteId) {
      _athleteId = id;
      if (_athleteId != null) fetchEvents();
    }
  }

  Future<void> fetchEvents() async {
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
    if (targetId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('athlete_id', targetId)
          .order('date', ascending: true);
      
      _events = (response as List).map((e) => AthleteEvent.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching events: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEvent(String title, DateTime date, EventType type, String? description) async {
    final targetId = _athleteId ?? _supabase.auth.currentUser?.id;
    if (targetId == null) return;
    
    final newEvent = {
        'id': '${targetId}_${date.millisecondsSinceEpoch}', // Simple ID gen
        'athlete_id': targetId,
        'title': title,
        'date': date.toIso8601String().split('T')[0],
        'type': type.name.toUpperCase(),
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('events').insert(newEvent);
      await fetchEvents(); // Refresh
    } catch (e) {
       debugPrint("Error adding event: $e");
       rethrow;
    }
  }

  // Helper to get upcoming events
  List<AthleteEvent> get upcomingEvents {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return _events.where((e) => e.date.isAfter(now)).toList();
  }
}
