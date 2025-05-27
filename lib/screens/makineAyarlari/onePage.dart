import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/screens/deneme.dart';
import 'package:makine/service/komut_service.dart';
import 'package:makine/utils/ui_helpers.dart';

final dropdownItemsProvider = Provider<List<String>>((ref) => [
      'Seçenek 1',
      'Seçenek 2',
      'Seçenek 3',
      'Seçenek 4',
    ]);
// Gerekli providerlar
final selectedValueProvider = StateProvider<String?>((ref) => null);

class OnePage extends ConsumerStatefulWidget {
  final String turId;
  const OnePage({super.key, required this.turId});
  @override
  ConsumerState<OnePage> createState() => _OnePageState();
}

class _OnePageState extends ConsumerState<OnePage> {
  late final GCodeService gCodeService;

  @override
  Widget build(BuildContext context) {
    final isSending = ref.watch(isSendingProvider.notifier).state;
    // Dropdown ve Radio Button değerlerini sağlayıcılardan al
    final selectedValue = ref.watch(selectedValueProvider);
    final dropdownItems = ref.watch(dropdownItemsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Dropdown 1
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
                //color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100, width: 2)),
            width: MediaQuery.of(context).size.width,
            child: DropdownButton<String>(
              isExpanded: true,
              menuWidth: MediaQuery.of(context).size.width / 1.1,
              icon: const Icon(
                Icons.arrow_drop_down_sharp,
                color: Colors.blue,
              ),
              elevation: 1,
              borderRadius: BorderRadius.circular(20),
              underline: const SizedBox(),
              value: selectedValue,
              hint: const Text('Bir seçenek seçin'),
              items: dropdownItems.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (String? newValue) {
                ref.read(selectedValueProvider.notifier).state = newValue;
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5), // Gölge rengi
                  spreadRadius: 1, // Gölge yayılma alanı
                  blurRadius: 7, // Gölge bulanıklığı
                  offset: const Offset(0, 8), // Gölgenin konumu (x, y)
                ),
              ],
            ),
            child: ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        try {
                          ref.read(isSendingProvider.notifier).state = true;
                          final gCodeLines =
                              await gCodeService.fetchGCode(widget.turId);
                          if (gCodeLines.isNotEmpty) {
                            ref.read(isSendingProvider.notifier).state = true;
                            final isOkey = await sendGCodeLines(gCodeLines);
                            if (isOkey) {
                              _showMessage('Gönderme Başarılı', false);
                              ref.read(isSendingProvider.notifier).state =
                                  false;
                            }
                          } else {
                            _showMessage(
                                'Bağlantı Hatası veya kodlar alınamadı', true);
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
                )),
          )
        ],
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
