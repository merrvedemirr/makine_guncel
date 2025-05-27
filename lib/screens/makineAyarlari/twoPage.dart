import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/service/komut_service.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/provider.dart';

Padding customRow(double lazerPage, WidgetRef ref, String message,
    StateProvider<double> lazerProvider) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Text(
          '$message: %${lazerPage.toInt()}',
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
        Expanded(
          child: Slider(
            activeColor: Colors.blue,
            value: lazerPage,
            min: 1,
            max: 100,
            divisions: 99,
            label: lazerPage.toInt().toString(),
            onChanged: (value) {
              ref.read(lazerProvider.notifier).state = value;
            },
          ),
        ),
      ],
    ),
  );
}

class TwoPage extends ConsumerStatefulWidget {
  final String turId;
  const TwoPage({
    super.key,
    required this.turId,
  });
  @override
  ConsumerState<TwoPage> createState() => _TwoPageState();
}

class _TwoPageState extends ConsumerState<TwoPage> {
  late final GCodeService gCodeService;

  @override
  Widget build(BuildContext context) {
    final lazerKesmeGucu = ref.watch(lazerKesmeGucuProvider);
    final lazerHizPage2 = ref.watch(lazerHizPage2Provider);
    final isSending = ref.watch(isSendingProvider.notifier).state;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            customRow(
                lazerHizPage2, ref, "Lazer Kesme Hızı", lazerHizPage2Provider),
            customRow(lazerKesmeGucu, ref, "Lazer Kesme Gücü",
                lazerKesmeGucuProvider),
            Container(
              margin: const EdgeInsets.only(top: 25),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // Gölge rengi
                  spreadRadius: 1, // Gölge yayılma alanı
                  blurRadius: 7, // Gölge bulanıklığı
                  offset: const Offset(0, 8), // Gölgenin konumu (x, y)
                ),
              ]),
              child: ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        try {
                          ref.read(isSendingProvider.notifier).state = true;
                          final gCodeLines =
                              await gCodeService.fetchGCode(widget.turId);
                          if (gCodeLines.isNotEmpty) {
                            final isOkey = await sendGCodeLines(gCodeLines);
                            if (isOkey) {
                              _showMessage('Gönderme Başarılı', false);
                              ref.read(isSendingProvider.notifier).state =
                                  false;
                            }
                          } else {
                            _showMessage('Bağlantı Hatası', true);
                            inspect('GCode komutları alınamadı.');
                          }
                        } catch (e) {
                          _showMessage('Bağlantı Hatası', true);
                          inspect('GCode komutları alınamadı.');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  "Gönder",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    gCodeService = ref.read(gCodeServiceProvider);
  }

  Future<bool> sendGCodeLines(List<String> lines) async {
    for (String line in lines) {
      if (line.isNotEmpty) {
        await gCodeService.sendGCodeLine(line);
        await Future.delayed(
            const Duration(milliseconds: 1)); // Gecikme ekleyebilirsiniz
      }
    }
    inspect('Tüm GCode komutları gönderildi.');
    return true;
  }

  void _showMessage(String message, bool isError) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: isError,
    );
  }
}
