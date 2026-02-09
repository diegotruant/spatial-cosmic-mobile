import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/bluetooth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/glass_card.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  @override
  void initState() {
    super.initState();
    // Start scanning immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothService>().startScan();
    });
  }

  @override
  void dispose() {
    // Stop scanning when leaving
    // Note: We might want to keep scanning if we just pop a dialog, but here we are popping the screen.
    // However, we rely on the service to handle stopScan if needed, or we can force it.
    // For now, let's just let it run or stop it explicitly.
    // context.read<BluetoothService>().stopScan(); 
    // Ideally we should stop scanning to save battery.
    // Find a way to access service without context if mounted false... 
    // Actually simpler:
    super.dispose();
  }
  
  void _stopScan() {
     if (mounted) context.read<BluetoothService>().stopScan();
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothService>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.get('add_devices'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            _stopScan();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (bluetooth.isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                   width: 20, height: 20, 
                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
              onPressed: () => bluetooth.startScan(),
            ),
        ],
      ),
      body: Stack(
        children: [
           // Background
           Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 100, spreadRadius: 20)
                ],
              ),
            ),
          ),
          
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Connected Devices Section
              if (bluetooth.connectedDeviceCount > 0) ...[
                 Text(l10n.get('connected').toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
                 const SizedBox(height: 8),
                 _buildConnectedDeviceTile(l10n, bluetooth.trainer, 'Smart Trainer', 'TRAINER', bluetooth),
                 _buildConnectedDeviceTile(l10n, bluetooth.heartRateSensor, 'Heart Rate', 'HR', bluetooth),
                 _buildConnectedDeviceTile(l10n, bluetooth.powerMeter, 'Power Meter', 'POWER', bluetooth),
                 _buildConnectedDeviceTile(l10n, bluetooth.cadenceSensor, 'Cadence Sensor', 'CADENCE', bluetooth),
                 _buildConnectedDeviceTile(l10n, bluetooth.coreSensor, 'CORE Sensor', 'CORE', bluetooth),
                 const SizedBox(height: 24),
              ],

              // Scanned Devices
              Text('${l10n.get('searching')} (${bluetooth.scanResults.length})', style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              
              if (bluetooth.scanResults.isEmpty && !bluetooth.isScanning)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(child: Text(l10n.get('no_devices_found'), style: const TextStyle(color: Colors.white30))),
                ),

              ...bluetooth.scanResults.map((result) {
                 if (result.device.platformName.isEmpty) return const SizedBox.shrink(); 
                 
                 // FILTER: Only show fitness devices
                 final type = bluetooth.detectDeviceType(result);
                 if (type == null) return const SizedBox.shrink();

                 return Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: GlassCard(
                     child: ListTile(
                       onTap: () => _showConnectionDialog(context, result.device),
                       title: Text(result.device.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       subtitle: Text(type, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text('${result.rssi} dBm', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                           const SizedBox(width: 8),
                           const Icon(Icons.chevron_right, color: Colors.white30),
                         ],
                       ),
                     ),
                   ),
                 );
              }),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectedDeviceTile(AppLocalizations l10n, BluetoothDevice? device, String label, String type, BluetoothService service) {
    if (device == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        borderColor: Colors.greenAccent.withOpacity(0.3),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(_getIconForType(type), color: Colors.greenAccent, size: 20),
          ),
          title: Text(device.platformName.isNotEmpty ? device.platformName : label, style: const TextStyle(color: Colors.white)),
          subtitle: Text('$label • ${l10n.get('connected')}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () async {
              // TODO: Implement getDeviceType and disconnectDevice methods in BluetoothService
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Disconnect feature temporarily disabled'),
                  backgroundColor: Colors.orange,
                ),
              );
              
              /* DISABLED UNTIL METHODS ARE IMPLEMENTED
              // Get device type before disconnecting
              final deviceType = service.getDeviceType(device);
              if (deviceType == null) return;
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text('Disconnecting ${device.platformName}...'),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.orange,
                ),
              );
              
              // Disconnect device
              await service.disconnectDevice(deviceType);
              
              // Show success
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${device.platformName} disconnected'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              */
            }, 
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'TRAINER': return LucideIcons.bike;
      case 'HR': return LucideIcons.heart;
      case 'POWER': return LucideIcons.zap;
      case 'CADENCE': return LucideIcons.repeat;
      case 'CORE': return LucideIcons.thermometer;
      default: return LucideIcons.bluetooth;
    }
  }

  void _showConnectionDialog(BuildContext context, BluetoothDevice device) {
    final bluetooth = context.read<BluetoothService>();
    
    // 1. Try to detect type from the scan result associated with this device
    // We need to find the ScanResult for this device
    try {
      final result = bluetooth.scanResults.firstWhere((r) => r.device.remoteId == device.remoteId);
      final detectedType = bluetooth.detectDeviceType(result);
      
      if (detectedType != null) {
        // Auto-connect!
        // Show a quick snackbar or toast to confirm?
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected ${device.platformName} as $detectedType. Connecting...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          )
        );
        bluetooth.connectToDevice(device, detectedType);
        return;
      }
    } catch (e) {
      // ignore
    }

    // 2. Fallback to manual selection if unknown
    // OR if it IS a Trainer, we want to ask which features to use!
    
    // Check if name suggests trainer or if we already detected it
    bool likelyTrainer = device.platformName.toUpperCase().contains("KICKR") || 
                         device.platformName.toUpperCase().contains("TACX") ||
                         device.platformName.toUpperCase().contains("TRAINER") || 
                         device.platformName.toUpperCase().contains("ELITE") ||
                         device.platformName.toUpperCase().contains("DIRETO") ||
                         device.platformName.toUpperCase().contains("NEO");

    if (likelyTrainer) {
       _showTrainerConfigDialog(context, device);
       return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(device.platformName, style: const TextStyle(color: Colors.white)),
        content: Text(AppLocalizations.of(context).get('select_device_type'), style: const TextStyle(color: Colors.white70)),
        actions: [
          _buildTypeButton(ctx, device, 'Smart Trainer (Config)', 'TRAINER_CONFIG'), // Special type to trigger config
          _buildTypeButton(ctx, device, 'Heart Rate', 'HR'),
          _buildTypeButton(ctx, device, 'Power Meter', 'POWER'),
          _buildTypeButton(ctx, device, 'Cadence', 'CADENCE'),
          _buildTypeButton(ctx, device, 'CORE Sensor', 'CORE'),
        ],
      ),
    );
  }
  
  void _showTrainerConfigDialog(BuildContext context, BluetoothDevice device) {
    final bluetooth = context.read<BluetoothService>();
    // Temporary state for the dialog
    bool usePower = true;
    bool useCadence = true;
    bool useSpeed = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text("Trainer Configuration", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select which data to use from this trainer:",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text("Power", style: TextStyle(color: Colors.white)),
                    value: usePower,
                    activeColor: Colors.blueAccent,
                    onChanged: (v) => setState(() => usePower = v!),
                  ),
                  CheckboxListTile(
                    title: const Text("Cadence", style: TextStyle(color: Colors.white)),
                    subtitle: const Text("Uncheck if using external sensor", style: TextStyle(color: Colors.white30, fontSize: 10)),
                    value: useCadence,
                    activeColor: Colors.blueAccent,
                    onChanged: (v) => setState(() => useCadence = v!),
                  ),
                  CheckboxListTile(
                    title: const Text("Speed", style: TextStyle(color: Colors.white)),
                    value: useSpeed,
                    activeColor: Colors.blueAccent,
                    onChanged: (v) => setState(() => useSpeed = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update Service Preferences
                    bluetooth.useTrainerPower = usePower;
                    bluetooth.useTrainerCadence = useCadence;
                    bluetooth.useTrainerSpeed = useSpeed;
                    
                    // Connect as Trainer
                    bluetooth.connectToDevice(device, 'TRAINER');
                    Navigator.pop(ctx);
                  },
                  child: const Text("Connect"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTypeButton(BuildContext ctx, BluetoothDevice device, String label, String type) {
    return TextButton(
      onPressed: () {
        if (type == 'TRAINER_CONFIG') {
           Navigator.pop(ctx);
           _showTrainerConfigDialog(context, device);
        } else {
           context.read<BluetoothService>().connectToDevice(device, type);
           Navigator.pop(ctx); // Close dialog
        }
      },
      child: Text(label, style: const TextStyle(color: Colors.blueAccent)),
    );
  }
}
