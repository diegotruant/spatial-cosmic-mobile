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
  WorkoutBlock copy({int? duration});
}

class SteadyState extends WorkoutBlock {
  final double power; // % of FTP
  SteadyState({required int duration, required this.power}) : super(duration);
  
  @override
  SteadyState copy({int? duration}) {
    return SteadyState(duration: duration ?? this.duration, power: power);
  }
}

class Ramp extends WorkoutBlock {
  final double powerLow; // % of FTP
  final double powerHigh; // % of FTP
  Ramp({required int duration, required this.powerLow, required this.powerHigh}) : super(duration);

  @override
  Ramp copy({int? duration}) {
    return Ramp(duration: duration ?? this.duration, powerLow: powerLow, powerHigh: powerHigh);
  }
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
    int? overrideDuration,
  }) : super(overrideDuration ?? (repeat * (onDuration + offDuration)));
  
  @override
  IntervalsT copy({int? duration}) {
    return IntervalsT(
       repeat: repeat,
       onDuration: onDuration,
       offDuration: offDuration,
       onPower: onPower, 
       offPower: offPower,
       overrideDuration: duration
    );
  }
}

class FreeRide extends WorkoutBlock {
  final int duration;
  FreeRide({required this.duration}) : super(duration);

  @override
  FreeRide copy({int? duration}) {
    return FreeRide(duration: duration ?? this.duration);
  }
}

class ZwoParser {
  /// Parse ZWO XML string. If the XML doesn't have a <name> tag, 
  /// uses titleOverride if provided, otherwise defaults to "Unknown Workout".
  static WorkoutWorkout parse(String xmlString, {String? titleOverride}) {
    final document = XmlDocument.parse(xmlString);
    
    // Attempt to find name or title in XML
    String title = titleOverride ?? 'Unknown Workout';
    final nameNode = document.findAllElements('name').firstOrNull;
    if (nameNode != null && nameNode.text.isNotEmpty) {
      title = nameNode.text;
    } else {
      final titleNode = document.findAllElements('title').firstOrNull;
      if (titleNode != null && titleNode.text.isNotEmpty) title = titleNode.text;
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
        } else if (node.name.local == 'Ramp' || node.name.local == 'Warmup' || node.name.local == 'Cooldown') {
          // Both Warmup/Cooldown in ZWO use PowerLow/PowerHigh
          blocks.add(Ramp(
            duration: int.parse(node.getAttribute('Duration') ?? '0'),
            powerLow: double.parse(node.getAttribute('PowerLow') ?? '0.0'),
            powerHigh: double.parse(node.getAttribute('PowerHigh') ?? '0.0'),
          ));
        } else if (node.name.local == 'IntervalsT') {
          blocks.add(IntervalsT(
            repeat: int.parse(node.getAttribute('Repeat') ?? '1'),
            onDuration: int.parse(node.getAttribute('OnDuration') ?? '0'),
            offDuration: int.parse(node.getAttribute('OffDuration') ?? '0'),
            onPower: double.parse(node.getAttribute('OnPower') ?? '0.0'),
            offPower: double.parse(node.getAttribute('OffPower') ?? '0.0'),
          ));
        } else if (node.name.local == 'FreeRide') {
           blocks.add(FreeRide(
             duration: int.parse(node.getAttribute('Duration') ?? '0'),
           ));
        }
      }
    }

    return WorkoutWorkout(title: title, blocks: blocks);
  }

  static Map<String, dynamic> getStats(WorkoutWorkout workout, int ftp) {
    int totalDuration = 0;
    double weightedPowerSum = 0;
    int knownDuration = 0;

    for (var block in workout.blocks) {
      totalDuration += block.duration;
      if (block is SteadyState) {
        weightedPowerSum += block.duration * block.power;
        knownDuration += block.duration;
      } else if (block is Ramp) {
        weightedPowerSum += block.duration * (block.powerLow + block.powerHigh) / 2;
        knownDuration += block.duration;
      } else if (block is IntervalsT) {
        // Average power of the interval set
        int setDuration = block.onDuration + block.offDuration;
        double avgPower = ((block.onDuration * block.onPower) + (block.offDuration * block.offPower)) / setDuration;
        weightedPowerSum += block.repeat * setDuration * avgPower;
        knownDuration += block.repeat * setDuration;
      }
      // FreeRide is excluded from weighted power calculation but included in stats
    }

    double avgPowerPercent = knownDuration > 0 ? weightedPowerSum / knownDuration : 0.0;
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
      final type = (blockJson['type'] as String?)?.toLowerCase();
      final duration = (blockJson['duration'] as num?)?.toInt() ?? 0;
      
      if (type == 'freeride') {
         blocks.add(FreeRide(duration: duration));
         continue;
      }
      
      // Extract Power safely
      double? pStart;
      double? pEnd;

      var rawPower = blockJson['power'] ?? blockJson['targetValue'];
      if (rawPower is num) {
        pStart = rawPower.toDouble();
        pEnd = (blockJson['powerEnd'] as num?)?.toDouble() ?? pStart;
      } else if (rawPower is Map) {
        pStart = (rawPower['start'] as num?)?.toDouble() ?? (rawPower['target'] as num?)?.toDouble() ?? (rawPower['min'] as num?)?.toDouble();
        pEnd = (rawPower['end'] as num?)?.toDouble() ?? pStart;
      } else if (rawPower is List && rawPower.isNotEmpty) {
        pStart = (rawPower[0] as num).toDouble();
        pEnd = rawPower.length > 1 ? (rawPower[1] as num).toDouble() : pStart;
      }

      // Normalize % values (Builder uses 0.9, some others might use 90)
      if (pStart != null && pStart > 2.0) pStart /= 100.0;
      if (pEnd != null && pEnd > 2.0) pEnd /= 100.0;

      if (type == 'intervals' || type == 'intervalst' || blockJson['onPower'] != null) {
         blocks.add(IntervalsT(
           repeat: (blockJson['repeat'] as num?)?.toInt() ?? 1,
           onDuration: (blockJson['onDuration'] as num?)?.toInt() ?? 0,
           offDuration: (blockJson['offDuration'] as num?)?.toInt() ?? 0,
           onPower: (blockJson['onPower'] as num?)?.toDouble() ?? 0.0,
           offPower: (blockJson['offPower'] as num?)?.toDouble() ?? 0.0,
         ));
      } else if (type == 'ramp' || (pStart != null && pEnd != null && pStart != pEnd)) {
         blocks.add(Ramp(
           duration: duration,
           powerLow: pStart ?? 0.0,
           powerHigh: pEnd ?? 0.0,
         ));
      } else {
         blocks.add(SteadyState(
           duration: duration,
           power: pStart ?? 0.0,
         ));
      }
    }

    return WorkoutWorkout(id: id, title: title, blocks: blocks);
  }

  static String toXml(WorkoutWorkout workout) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('workout_file', nest: () {
      builder.element('author', nest: () { builder.text('Velo Lab'); });
      builder.element('name', nest: () { builder.text(workout.title); });
      builder.element('sportType', nest: () { builder.text('bike'); });
      builder.element('workout', nest: () {
        for (var block in workout.blocks) {
          if (block is SteadyState) {
            builder.element('SteadyState', attributes: {
              'Duration': block.duration.toString(),
              'Power': block.power.toStringAsFixed(2),
            });
          } else if (block is Ramp) {
            builder.element('Ramp', attributes: {
              'Duration': block.duration.toString(),
              'PowerLow': block.powerLow.toStringAsFixed(2),
              'PowerHigh': block.powerHigh.toStringAsFixed(2),
            });
          } else if (block is IntervalsT) {
            builder.element('IntervalsT', attributes: {
              'Repeat': block.repeat.toString(),
              'OnDuration': block.onDuration.toString(),
              'OffDuration': block.offDuration.toString(),
              'OnPower': block.onPower.toStringAsFixed(2),
              'OffPower': block.offPower.toStringAsFixed(2),
            });
          } else if (block is FreeRide) {
            builder.element('FreeRide', attributes: {
              'Duration': block.duration.toString(),
            });
          }
        }
      });
    });
    return builder.buildDocument().toXmlString(pretty: true);
  }
}

