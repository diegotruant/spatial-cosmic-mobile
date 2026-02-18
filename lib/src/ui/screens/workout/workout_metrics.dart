import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/workout_service.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/w_prime_service.dart';
import '../../../logic/zwo_parser.dart';
import '../../widgets/big_metric_tile.dart';

// --- Helper Functions ---
String _formatTime(int totalSeconds) {
  int minutes = totalSeconds ~/ 60;
  int seconds = totalSeconds % 60;
  return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

Color _getZoneColor(int watts, int ftp) {
  if (ftp <= 0) return Colors.cyanAccent;
  return WorkoutService.getZoneColor(watts / ftp);
}

// --- Specialized Tiles ---

class IntervalTimerTile extends StatefulWidget {
  const IntervalTimerTile({super.key});

  @override
  State<IntervalTimerTile> createState() => _IntervalTimerTileState();
}

class _IntervalTimerTileState extends State<IntervalTimerTile> {
  bool _showRemainingTime = true; // Default to remaining for better UX

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showRemainingTime = !_showRemainingTime),
      child: Selector<WorkoutService, ({int elapsed, int duration, bool hasWorkout})>(
        selector: (_, service) => (
          elapsed: service.elapsedInBlock,
          duration: service.currentWorkout?.blocks[service.currentBlockIndex].duration ?? 0,
          hasWorkout: service.currentWorkout != null && service.currentBlockIndex < (service.currentWorkout?.blocks.length ?? 0)
        ),
        builder: (context, data, _) {
          return BigMetricTile(
            label: _showRemainingTime ? 'INT REM' : 'INTERVAL',
            value: _showRemainingTime
                ? (data.hasWorkout ? _formatTime(data.duration - data.elapsed) : '-')
                : _formatTime(data.elapsed),
            unit: '',
            accentColor: Colors.blueAccent,
            isHuge: false,
            labelFontSize: 11.0,
          );
        },
      ),
    );
  }
}

class TotalTimeTile extends StatefulWidget {
  const TotalTimeTile({super.key});

  @override
  State<TotalTimeTile> createState() => _TotalTimeTileState();
}

class _TotalTimeTileState extends State<TotalTimeTile> {
  bool _showTotalRemainingTime = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showTotalRemainingTime = !_showTotalRemainingTime),
      child: Selector<WorkoutService, ({int totalElapsed, int totalDuration})>(
        selector: (_, service) {
           int total = 0;
           if (service.currentWorkout != null) {
             for (var b in service.currentWorkout!.blocks) {
               total += b.duration;
             }
           }
           return (totalElapsed: service.totalElapsed, totalDuration: total);
        },
        builder: (context, data, _) {
          return BigMetricTile(
            label: _showTotalRemainingTime ? 'TOT REM' : 'TOT.TIME',
            value: _showTotalRemainingTime
                ? _formatTime(data.totalDuration - data.totalElapsed)
                : _formatTime(data.totalElapsed),
            unit: '',
            accentColor: Colors.grey,
            isHuge: false,
            labelFontSize: 11.0,
          );
        },
      ),
    );
  }
}

class NextStepTile extends StatelessWidget {
  const NextStepTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WorkoutService, ({int? nextDuration, double? nextTarget, int intensity})>(
        selector: (_, service) {
          final blocks = service.currentWorkout?.blocks;
          if (blocks == null || service.currentBlockIndex >= blocks.length - 1) {
            return (nextDuration: null, nextTarget: null, intensity: 100);
          }
          final nextBlock = blocks[service.currentBlockIndex + 1];
          
          // Calculate target visualization color
          double factor = 0;
          if (nextBlock is SteadyState) factor = nextBlock.power;
          else if (nextBlock is IntervalsT) factor = nextBlock.onPower;
          else if (nextBlock is Ramp) factor = (nextBlock.powerLow + nextBlock.powerHigh) / 2;
          
          return (
            nextDuration: nextBlock.duration,
            nextTarget: factor,
            intensity: service.intensityPercentage
          );
        },
        builder: (context, data, _) {
           if (data.nextDuration == null) {
             return const BigMetricTile(label: 'NEXT', value: 'FINISH', unit: '', accentColor: Colors.grey);
           }
           
           final intensityFactor = data.intensity / 100.0;
           final color = WorkoutService.getZoneColor(data.nextTarget! * intensityFactor);
           
           return BigMetricTile(
              label: 'NEXT STEP',
              value: _formatTime(data.nextDuration!),
              unit: '',
              accentColor: color,
              valueColor: color,
              labelFontSize: 11.0,
           );
        },
    );
  }
}

class MainPowerTile extends StatefulWidget {
  const MainPowerTile({super.key});

  @override
  State<MainPowerTile> createState() => _MainPowerTileState();
}

class _MainPowerTileState extends State<MainPowerTile> {
  bool _showPercentPower = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showPercentPower = !_showPercentPower),
      child: Selector<WorkoutService, ({double currentPower, int userFtp})>(
        selector: (_, service) => (currentPower: service.currentPower, userFtp: service.userFtp),
        builder: (context, data, _) {
          final currentWatts = data.currentPower.toInt();
          final color = _getZoneColor(currentWatts, data.userFtp);
          
          return BigMetricTile(
            label: _showPercentPower ? 'POWER %' : 'POWER',
            value: _showPercentPower
                ? (data.userFtp > 0 ? ((currentWatts / data.userFtp) * 100).toStringAsFixed(0) : '-')
                : currentWatts.toString(),
            unit: _showPercentPower ? '%' : 'W',
            accentColor: color,
            valueColor: color,
            isHuge: true,
          );
        },
      ),
    );
  }
}

class TargetPowerTile extends StatefulWidget {
  const TargetPowerTile({super.key});

  @override
  State<TargetPowerTile> createState() => _TargetPowerTileState();
}

class _TargetPowerTileState extends State<TargetPowerTile> {
  bool _showPercentTarget = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showPercentTarget = !_showPercentTarget),
      child: Selector<WorkoutService, ({int targetWatts, int userFtp})>(
        selector: (_, service) => (targetWatts: service.currentTargetWatts, userFtp: service.userFtp),
        builder: (context, data, _) {
           final color = _getZoneColor(data.targetWatts, data.userFtp);
           
           return BigMetricTile(
              label: _showPercentTarget ? 'TARGET %' : 'TARGET',
              value: _showPercentTarget
                  ? (data.userFtp > 0 ? ((data.targetWatts / data.userFtp) * 100).toStringAsFixed(0) : '-')
                  : data.targetWatts.toString(),
              unit: _showPercentTarget ? '%' : 'W',
              accentColor: color,
              valueColor: color,
              isHuge: true,
           );
        },
      ),
    );
  }
}

class HeartRateTile extends StatefulWidget {
  const HeartRateTile({super.key});

  @override
  State<HeartRateTile> createState() => _HeartRateTileState();
}

class _HeartRateTileState extends State<HeartRateTile> {
  bool _showPercentHr = false;

  @override
  Widget build(BuildContext context) {
    final hrMax = context.select<SettingsService, int>((s) => s.hrMax);
    
    return GestureDetector(
        onTap: () => setState(() => _showPercentHr = !_showPercentHr),
        child: Selector<BluetoothService, int>(
           selector: (_, bt) => bt.heartRate,
           builder: (context, hr, _) {
             return BigMetricTile(
                label: _showPercentHr ? 'HR %' : 'HR',
                value: _showPercentHr
                    ? (hrMax > 0 && hr > 0 ? ((hr / hrMax) * 100).toInt().toString() : '-')
                    : hr > 0 ? hr.toString() : '-',
                unit: _showPercentHr ? '%' : 'BPM',
                accentColor: Colors.redAccent,
             );
           },
        )
    );
  }
}

class CadenceTile extends StatelessWidget {
  const CadenceTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<BluetoothService, int>(
      selector: (_, bt) => bt.cadence,
      builder: (context, cadence, _) {
        return BigMetricTile(
            label: 'CAD',
            value: cadence > 0 ? cadence.toString() : '-',
            unit: 'RPM',
            accentColor: Colors.greenAccent
        );
      },
    );
  }
}

class WPrimeTile extends StatelessWidget {
  const WPrimeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WPrimeService, ({double currentWPrime, bool isDepleting})>(
      selector: (_, wp) => (currentWPrime: wp.currentWPrime, isDepleting: wp.isDepleting),
      builder: (context, data, _) {
        return BigMetricTile(
            label: 'W\' BAL',
            value: (data.currentWPrime / 1000).toStringAsFixed(1),
            unit: 'kJ',
            accentColor: data.isDepleting ? Colors.orangeAccent : Colors.purpleAccent,
        );
      },
    );
  }
}

class SpeedTile extends StatelessWidget {
  const SpeedTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WorkoutService, double>(
      selector: (_, service) => service.currentSpeed,
      builder: (context, speed, _) {
        return BigMetricTile(
            label: 'SPD',
            value: speed.toStringAsFixed(1),
            unit: 'km/h',
            accentColor: Colors.blueAccent
        );
      },
    );
  }
}

class DistanceTile extends StatelessWidget {
  const DistanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WorkoutService, double>(
      selector: (_, service) => service.totalDistance,
      builder: (context, dist, _) {
         return BigMetricTile(
            label: 'DIST',
            value: dist.toStringAsFixed(1),
            unit: 'km',
            accentColor: Colors.blueAccent
        );
      },
    );
  }
}

class BalanceTile extends StatelessWidget {
  const BalanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<BluetoothService, ({int? left, int? right})>(
      selector: (_, bt) => (left: bt.leftPowerBalance, right: bt.rightPowerBalance),
      builder: (context, data, _) {
        final val = (data.left != null && data.right != null)
          ? '${data.left}/${data.right}'
          : '-';
        return BigMetricTile(
            label: 'BAL',
            value: val,
            unit: '%',
            accentColor: Colors.cyanAccent
        );
      },
    );
  }
}

class CoreTempTile extends StatelessWidget {
  const CoreTempTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<BluetoothService, double>(
       selector: (_, bt) => bt.coreTemp,
       builder: (context, temp, _) {
          Color tempColor = Colors.greenAccent;
          if (temp > 38.0) {
            tempColor = Colors.redAccent;
          } else if (temp > 37.0) tempColor = Colors.yellowAccent;
          else if (temp <= 0) tempColor = Colors.grey;

          return BigMetricTile(
              label: 'CORE',
              value: temp > 0 ? temp.toStringAsFixed(1) : '-',
              unit: '°C',
              accentColor: tempColor,
              valueColor: tempColor,
          );
       },
    );
  }
}

class NpTile extends StatelessWidget {
  const NpTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<WorkoutService, int>(
      selector: (_, service) => service.currentNp,
      builder: (context, np, _) {
        return BigMetricTile(
            label: 'NP (LIVE)',
            value: np > 0 ? np.toString() : '-',
            unit: 'W',
            accentColor: Colors.deepPurpleAccent,
            valueColor: Colors.deepPurpleAccent,
        );
      },
    );
  }
}

// Fixed size wrapper usually needed for lists
class FixedMetricTile extends StatelessWidget {
  final Widget child;
  const FixedMetricTile({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: child,
    );
  }
}
