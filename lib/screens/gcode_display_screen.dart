import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/screens/bluetooth/bluetooth_scanner_screen.dart';
import 'package:makine/screens/bluetooth/bluetooth_sender_screen.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/provider.dart';

class GCodeDisplayScreen extends ConsumerStatefulWidget {
  final List<String> gcodeLines;

  const GCodeDisplayScreen({
    super.key,
    required this.gcodeLines,
  });

  @override
  ConsumerState<GCodeDisplayScreen> createState() => _GCodeDisplayScreenState();
}

class _GCodeDisplayScreenState extends ConsumerState<GCodeDisplayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCode İçeriği'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gelen toplam ${widget.gcodeLines.length} satır GCode',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: widget.gcodeLines.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            (index + 1).toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.gcodeLines[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final controller = ref.read(bluetoothControllerProvider);
                  if (controller.isConnected && controller.selectedDevice != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BluetoothSenderScreen(
                          deviceName: controller.selectedDevice!.name,
                          gcodeLines: widget.gcodeLines,
                          controller: controller,
                        ),
                      ),
                    );
                  } else {
                    UIHelpers.showSnackBar(context, message: 'Cihaz bağlı değil', isError: true).then(
                      (value) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BluetoothScannerScreen(),
                          ),
                        );
                      },
                    );
                  }
                },
                child: Text(
                  'Gönder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }
}
