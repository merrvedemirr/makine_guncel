import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/service/komut_service.dart';

// GCodeService için provider
final gCodeServiceProvider = Provider((ref) => GCodeService(Dio()));

// GCode gönderim durumu için provider
final isSendingProvider = StateProvider<bool>((ref) => false);

// GCode gönderim durumu için provider
final shouldStopProvider = StateProvider<bool>((ref) => false);

class GcodeFetch extends ConsumerStatefulWidget {
  const GcodeFetch({super.key, required this.tur_id});
  final String tur_id;

  @override
  ConsumerState<GcodeFetch> createState() => _GcodeFetchState();
}

class _GcodeFetchState extends ConsumerState<GcodeFetch> {
  late final GCodeService gCodeService;

  @override
  void initState() {
    super.initState();
    gCodeService = ref.read(gCodeServiceProvider);
  }

  Future<void> _sendGCodeLines(List<String> lines) async {
    final shouldStop = ref.read(shouldStopProvider.notifier);
    final isSending = ref.read(isSendingProvider.notifier);
    isSending.state = true;
    for (String line in lines) {
      if (shouldStop.state) {
        print('GCode gönderimi durduruldu.');
        isSending.state = false;
        return;
      }
      if (line.isNotEmpty) {
        await gCodeService.sendGCodeLine(line);
        await Future.delayed(
            const Duration(milliseconds: 1)); // Gecikme ekleyebilirsiniz
      }
    }
    isSending.state = false;
    print('Tüm GCode komutları gönderildi.');
  }

  @override
  void dispose() {
    // Gönderimi durdurmak için bayrağı true yap
    ref.read(shouldStopProvider.notifier).state = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = ref.watch(isSendingProvider.notifier).state;

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isSending
                ? null
                : () async {
                    final gCodeLines =
                        await gCodeService.fetchGCode(widget.tur_id);
                    if (gCodeLines.isNotEmpty) {
                      ref.read(shouldStopProvider.notifier).state = false;
                      await _sendGCodeLines(gCodeLines);
                    } else {
                      print('GCode komutları alınamadı.');
                    }
                  },
            child: const Text('GCode Gönder'),
          ),
          ElevatedButton(
            onPressed: isSending
                ? () {
                    ref.read(shouldStopProvider.notifier).state = true;
                  }
                : null,
            child: const Text('Durdur'),
          ),
        ],
      ),
    );
  }
}
