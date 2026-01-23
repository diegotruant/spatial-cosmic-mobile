import 'package:xml/xml.dart';

class WorkoutWorkout {
  final String? id;
  final String title;
  final List<WorkoutBlock> blocks;
  WorkoutWorkout({this.id, required this.title, required this.blocks});
}

abstract class WorkoutBlock {
  final int duration; // seconds
  WorkoutBlock(this.duration);
}

class SteadyState extends WorkoutBlock {
  final double power; // % of FTP
  SteadyState({required int duration, required this.power}) : super(duration);
}

class IntervalsT extends WorkoutBlock {
  final int repeat;
  final int onDuration;
  final int offDuration;
  final double onPower;
  final double offPower;

  IntervalsT({
    required this.repeat,
    required this.onDuration,
    required this.offDuration,
    required this.onPower,
    required this.offPower,
  }) : super(repeat * (onDuration + offDuration));
}

class ZwoParser {
  static WorkoutWorkout parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    
    // Attempt to find name or title
    String title = 'Unknown Workout';
    final nameNode = document.findAllElements('name').firstOrNull;
    if (nameNode != null) {
      title = nameNode.text;
    } else {
      final titleNode = document.findAllElements('title').firstOrNull;
      if (titleNode != null) title = titleNode.text;
    }

    final workoutNode = document.findAllElements('workout').first;
    final List<WorkoutBlock> blocks = [];

    for (var node in workoutNode.children) {
      if (node is XmlElement) {
        if (node.name.local == 'SteadyState') {
          blocks.add(SteadyState(
            duration: int.parse(node.getAttribute('Duration') ?? '0'),
            power: double.parse(node.getAttribute('Power') ?? '0.0'),
          ));
        } else if (node.name.local == 'IntervalsT') {
          blocks.add(IntervalsT(
            repeat: int.parse(node.getAttribute('Repeat') ?? '1'),
            onDuration: int.parse(node.getAttribute('OnDuration') ?? '0'),
            offDuration: int.parse(node.getAttribute('OffDuration') ?? '0'),
            onPower: double.parse(node.getAttribute('OnPower') ?? '0.0'),
            offPower: double.parse(node.getAttribute('OffPower') ?? '0.0'),
          ));
        }
      }
    }

    return WorkoutWorkout(title: title, blocks: blocks);
  }

  static Map<String, dynamic> getStats(WorkoutWorkout workout, int ftp) {
    int totalDuration = 0;
    double weightedPowerSum = 0;

    for (var block in workout.blocks) {
      totalDuration += block.duration;
      if (block is SteadyState) {
        weightedPowerSum += block.duration * block.power;
      } else if (block is IntervalsT) {
        // Average power of the interval set
        int setDuration = block.onDuration + block.offDuration;
        double avgPower = ((block.onDuration * block.onPower) + (block.offDuration * block.offPower)) / setDuration;
        weightedPowerSum += block.repeat * setDuration * avgPower;
      }
    }

    double avgPowerPercent = totalDuration > 0 ? weightedPowerSum / totalDuration : 0.0;
    int targetPower = (avgPowerPercent * ftp).round();

    return {
      'duration': totalDuration,
      'targetPower': targetPower,
    };
  }
  static WorkoutWorkout parseJson(Map<String, dynamic> assignment) {
    final title = assignment['workout_name'] as String? ?? 'Assigned Workout';
    final id = assignment['id'] as String?;
    final structure = assignment['workout_structure'];

    final List<WorkoutBlock> blocks = [];
    List<dynamic> structureList = [];

    if (structure != null) {
      if (structure is List) {
        structureList = structure;
      } else if (structure is Map) {
        if (structure.containsKey('steps')) {
          structureList = structure['steps'];
        } else if (structure.containsKey('intervals')) {
          structureList = structure['intervals'];
        }
      }
    }

    for (var blockJson in structureList) {
      if (blockJson['type'] == 'SteadyState' || (blockJson['power'] != null && blockJson['onPower'] == null)) {
         blocks.add(SteadyState(
           duration: (blockJson['duration'] as num?)?.toInt() ?? 0,
           power: (blockJson['power'] as num?)?.toDouble() ?? (blockJson['targetValue'] as num?)?.toDouble() ?? 0.0,
         ));
      } else if (blockJson['type'] == 'IntervalsT' || blockJson['onPower'] != null) {
         blocks.add(IntervalsT(
           repeat: (blockJson['repeat'] as num?)?.toInt() ?? 1,
           onDuration: (blockJson['onDuration'] as num?)?.toInt() ?? 0,
           offDuration: (blockJson['offDuration'] as num?)?.toInt() ?? 0,
           onPower: (blockJson['onPower'] as num?)?.toDouble() ?? 0.0,
           offPower: (blockJson['offPower'] as num?)?.toDouble() ?? 0.0,
         ));
      } else if (blockJson['type'] == 'active' || blockJson['type'] == 'rest' || blockJson['type'] == 'warmup' || blockJson['type'] == 'cooldown') {
          double target = 0.0;
          var val = blockJson['targetValue'];
          if (val is num) target = val.toDouble();
          else if (val is List && val.isNotEmpty) target = (val[0] as num).toDouble();
          
          if (target > 2.0) target = target / 100.0; 

          blocks.add(SteadyState(
             duration: (blockJson['duration'] as num?)?.toInt() ?? 0,
             power: target,
          ));
      }
    }

    return WorkoutWorkout(id: id, title: title, blocks: blocks);
  }

  static String toXml(WorkoutWorkout workout) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('workout_file', nest: () {
      builder.element('author', nest: () { builder.text('Spatial Cosmic'); });
      builder.element('name', nest: () { builder.text(workout.title); });
      builder.element('sportType', nest: () { builder.text('bike'); });
      builder.element('workout', nest: () {
        for (var block in workout.blocks) {
          if (block is SteadyState) {
            builder.element('SteadyState', attributes: {
              'Duration': block.duration.toString(),
              'Power': block.power.toStringAsFixed(2),
            });
          } else if (block is IntervalsT) {
            builder.element('IntervalsT', attributes: {
              'Repeat': block.repeat.toString(),
              'OnDuration': block.onDuration.toString(),
              'OffDuration': block.offDuration.toString(),
              'OnPower': block.onPower.toStringAsFixed(2),
              'OffPower': block.offPower.toStringAsFixed(2),
            });
          }
        }
      });
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }
}
