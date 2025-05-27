import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/model/lazer_ayar_model.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/makineAyarlari/model_yerlestirme.dart';
import 'package:makine/service/komut_service.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/provider.dart';

// State class to manage G-code sending process
class GCodeSendingState {
  final bool isSending;
  final bool isComplete;
  final bool isLoading;
  final bool isCancelled;
  final String status;
  final int okResponseCount;
  final int expectedOkCount;
  final int currentPacketOkCount;

  GCodeSendingState({
    this.isSending = false,
    this.isComplete = false,
    this.isLoading = false,
    this.isCancelled = false,
    this.status = '',
    this.okResponseCount = 0,
    this.expectedOkCount = 0,
    this.currentPacketOkCount = 0,
  });

  GCodeSendingState copyWith({
    bool? isSending,
    bool? isComplete,
    bool? isLoading,
    bool? isCancelled,
    String? status,
    int? okResponseCount,
    int? expectedOkCount,
    int? currentPacketOkCount,
  }) {
    return GCodeSendingState(
      isSending: isSending ?? this.isSending,
      isComplete: isComplete ?? this.isComplete,
      isLoading: isLoading ?? this.isLoading,
      isCancelled: isCancelled ?? this.isCancelled,
      status: status ?? this.status,
      okResponseCount: okResponseCount ?? this.okResponseCount,
      expectedOkCount: expectedOkCount ?? this.expectedOkCount,
      currentPacketOkCount: currentPacketOkCount ?? this.currentPacketOkCount,
    );
  }
}

// G-code işlemini yöneten StateNotifier
class GCodeSendingNotifier extends StateNotifier<GCodeSendingState> {
  final Ref ref;
  StreamSubscription? _dataStreamSubscription;
  String _deviceBuffer = '';
  final Queue<String> _gcodeLinesQueue = Queue<String>();
  List<String> _pendingLines = [];
  int _currentPacketCharCount = 0;
  List<String> _gcodeLines = [];

  GCodeSendingNotifier(this.ref) : super(GCodeSendingState());

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setCancelled(bool isCancelled) {
    state = state.copyWith(isCancelled: isCancelled);
  }

  void startSending(List<String> gcodes) {
    if (state.isSending) return;

    // Yeniden başlatırken iptal durumunu sıfırla
    setCancelled(false);

    // İşlemi başlatırken loading durumunu true yapalım
    setLoading(true);

    _gcodeLines = gcodes;
    state = state.copyWith(
        isLoading: true,
        isSending: true,
        isComplete: false,
        okResponseCount: 0,
        currentPacketOkCount: 0,
        expectedOkCount: 0,
        status: 'G-code gönderimi başlatılıyor...');

    _initializeQueue();

    // Yeni bir stream başlatmadan önce eski stream aboneliğini iptal et
    _streamTemizle();
    _listenForDeviceData();

    _processNextBatch();
  }

  // Stream aboneliğini düzgün şekilde temizlemek için yeni metot
  void _streamTemizle() {
    if (_dataStreamSubscription != null) {
      _dataStreamSubscription!.cancel();
      _dataStreamSubscription = null;
      _deviceBuffer = ''; // Buffer'ı sıfırla
    }
  }

  void _initializeQueue() {
    _gcodeLinesQueue.clear();
    _gcodeLinesQueue.addAll(_gcodeLines);
    setStatus('G-code kuyruğu hazırlandı (${_gcodeLinesQueue.length} satır)');
  }

  void _listenForDeviceData() {
    final controller = ref.read(bluetoothControllerProvider);
    final stream = controller.getDataStream();

    try {
      _dataStreamSubscription = stream.listen(
        (data) {
          if (state.isCancelled) return;

          _deviceBuffer += data;
          if (_deviceBuffer.contains('\n')) {
            var lines = _deviceBuffer.split('\n');
            _deviceBuffer = lines.removeLast();

            for (var line in lines) {
              line = line.trim();
              if (line.isNotEmpty && line.toLowerCase().contains('ok')) {
                final newOkCount = state.okResponseCount + 1;
                final newPacketOkCount = state.currentPacketOkCount + 1;

                state = state.copyWith(
                    okResponseCount: newOkCount,
                    currentPacketOkCount: newPacketOkCount,
                    status:
                        'Gönderim devam ediyor... (OK: $newOkCount, Paket: $newPacketOkCount/${state.expectedOkCount})');

                // M2 komutunun OK'ini kontrol et
                if (_pendingLines.isNotEmpty &&
                    _pendingLines.last.trim() == 'M2' &&
                    newPacketOkCount >= state.expectedOkCount) {
                  // M2'nin OK'i geldi, kesim tamamlandı
                  //, mevcut paketteki tüm komutların OK yanıtlarının gelip gelmediğini kontrol ediyor
                  Future.microtask(() {
                    _processNextBatch();
                    state = state.copyWith(
                      status: 'Kesim tamamlandı (M2 komutu onaylandı)',
                      isComplete: true,
                      isSending: false,
                      isLoading: false,
                    );
                    _clearMemory();
                  });
                } else if (newPacketOkCount >= state.expectedOkCount) {
                  // Normal paket tamamlanma durumu
                  Future.microtask(() => _processNextBatch());
                }
              }
            }
          }
        },
        onError: (error) {
          setStatus('Veri akışı hatası: $error');
        },
        onDone: () {
          setStatus('Bağlantı kapandı');
        },
      );
    } catch (e) {
      setStatus('Stream dinleme hatası: $e');
    }
  }

  Future<void> _processNextBatch() async {
    if (_gcodeLinesQueue.isEmpty && !state.isSending && !state.isComplete) {
      state = state.copyWith(isComplete: true, isSending: false, status: 'Gönderim tamamlandı');
      _clearMemory();
      return;
    }

    if (state.currentPacketOkCount < state.expectedOkCount || _gcodeLinesQueue.isEmpty) return;

    _pendingLines = [];
    _currentPacketCharCount = 0;
    int newExpectedOkCount = 0;

    while (_gcodeLinesQueue.isNotEmpty) {
      String nextLine = _gcodeLinesQueue.first;
      // Satırı temizle ve yorum satırlarını kontrol et
      String trimmedLine = nextLine.trim();
      if (!trimmedLine.startsWith(';')) {
        // Yorum satırı değilse işle
        String cleanLine = nextLine.replaceAll('"', '');
        int lineLength = cleanLine.length + 1; // Newline character

        if (_currentPacketCharCount + lineLength > 254) break;

        _gcodeLinesQueue.removeFirst();
        _pendingLines.add(cleanLine);
        _currentPacketCharCount += lineLength;
        newExpectedOkCount++;
      } else {
        // Yorum satırıysa sadece kuyruktan çıkar, işleme alma
        _gcodeLinesQueue.removeFirst();
      }
    }

    state = state.copyWith(currentPacketOkCount: 0, expectedOkCount: newExpectedOkCount);

    if (_pendingLines.isNotEmpty) {
      await _sendPendingLines();

      if (_gcodeLinesQueue.isEmpty) {
        state = state.copyWith(isComplete: true, isSending: false, status: 'Gönderim tamamlandı');
        _clearMemory();
      }
    } else if (_gcodeLinesQueue.isEmpty) {
      state = state.copyWith(isComplete: true, isSending: false, status: 'Gönderim tamamlandı');
      _clearMemory();
    }
  }

  Future<void> _sendPendingLines() async {
    final controller = ref.read(bluetoothControllerProvider);
    try {
      String batchContent = _pendingLines.map((line) => '$line\n').join();

      controller.connection!.output.add(Uint8List.fromList(utf8.encode(batchContent)));
      await controller.connection!.output.allSent;
    } catch (e) {
      setStatus('Gönderim hatası: $e');
    }
  }

  void cancelSending() async {
    // Önce işlemi durdurmak için iptal bayrağını ayarla
    setCancelled(true);

    // Ardından bad state hatalarını önlemek için stream'i temizle
    _streamTemizle();

    final controller = ref.read(bluetoothControllerProvider);
    try {
      // Acil durum durdurma komutlarını gönder
      controller.connection!.output.add(Uint8List.fromList(utf8.encode("M5\n")));
      await controller.connection!.output.allSent;
      await Future.delayed(const Duration(milliseconds: 500));

      controller.connection!.output.add(Uint8List.fromList(utf8.encode("\$H\n")));
      await controller.connection!.output.allSent;
    } catch (e) {
      setStatus('Acil durum komutları gönderilemedi: $e');
    }

    // Kuyrukları temizle
    _gcodeLinesQueue.clear();
    _pendingLines.clear();

    // State'i tamamen sıfırla
    state = GCodeSendingState(
        isSending: false,
        isComplete: false,
        isLoading: false,
        status: 'Gönderim iptal edildi',
        okResponseCount: 0,
        expectedOkCount: 0,
        currentPacketOkCount: 0);
  }

  void _clearMemory() {
    _pendingLines.clear();
    _gcodeLinesQueue.clear();
    _streamTemizle();
  }

  @override
  void dispose() {
    _streamTemizle();
    // State'i tamamen sıfırla
    ref.read(gcodeSendingProvider.notifier).state = GCodeSendingState(
        isSending: false,
        isComplete: false,
        isLoading: false,
        isCancelled: false,
        status: '',
        okResponseCount: 0,
        expectedOkCount: 0,
        currentPacketOkCount: 0);
    super.dispose();
  }
}

// Provider for GCodeSendingState
final gcodeSendingProvider = StateNotifierProvider<GCodeSendingNotifier, GCodeSendingState>((ref) {
  return GCodeSendingNotifier(ref);
});

class MakineGcodeGonderScreen extends ConsumerStatefulWidget {
  const MakineGcodeGonderScreen(this.data,
      {required this.xKoordinat, required this.yKoordinat, required this.aci, required this.gcodeId, super.key});
  final double xKoordinat;
  final double yKoordinat;
  final double aci;
  final String gcodeId;
  final List<EDetay> data;

  @override
  ConsumerState<MakineGcodeGonderScreen> createState() => _MakineGcodeGonderScreenState();
}

class _MakineGcodeGonderScreenState extends ConsumerState<MakineGcodeGonderScreen> with TickerProviderStateMixin {
  late TabController tabController;
  int selectedIndex = 0;
  List<LazerAyar> ayarlar = [];
  LazerAyar? selectedAyar;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    tabController.addListener(() {
      setState(() {
        selectedIndex = tabController.index;
      });
    });

    // Sayfa açıldığında state'i sıfırla
    ref.read(gcodeSendingProvider.notifier).state = GCodeSendingState(
        isSending: false,
        isComplete: false,
        isLoading: false,
        isCancelled: false, // Başlangıçta false olmalı
        status: '',
        okResponseCount: 0,
        expectedOkCount: 0,
        currentPacketOkCount: 0);
  }

  @override
  Widget build(BuildContext context) {
    //Makine Lazer ayarları
    final lazerHizi = ref.watch(lazerHiziProvider);
    final lazerGucu = ref.watch(lazerGucuProvider);
    final isBluetoothConnected = ref.watch(isBluetoothConnectedProvider);
    final settings = ref.watch(laserSettingsNotifierProvider);
    final selectedAyar = ref.watch(selectedAyarProvider);
    final gcodeSendingState = ref.watch(gcodeSendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Makine Ayarları'),
        bottom: TabBar(
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          indicator: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: selectedIndex != 0 ? Radius.circular(5) : Radius.circular(0),
              topRight: selectedIndex == 0 ? Radius.circular(5) : Radius.circular(0),
            ),
          ),
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Varsayılan'),
            Tab(text: 'Özel'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    //!Varsayılan Ayar Seçimi
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        child: Column(
                          children: [
                            settings.when(
                              data: (data) {
                                // Eğer ilk defa yükleniyorsa ve seçili ayar yoksa, ilk ayarı otomatik ata
                                final selectedAyar = ref.watch(selectedAyarProvider);
                                if (selectedAyar == null && data.isNotEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    ref.read(selectedAyarProvider.notifier).state = data.first;
                                    ref.read(lazerHiziProvider.notifier).state =
                                        double.tryParse(data.first.lazerHizi) ?? 50.0;
                                    ref.read(lazerGucuProvider.notifier).state =
                                        double.tryParse(data.first.lazerGucu) ?? 50.0;
                                  });
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: DropdownButtonFormField<LazerAyar>(
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'Ayar Seçin',
                                    ),
                                    items: data.map((e) {
                                      return DropdownMenuItem<LazerAyar>(
                                        value: e,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0), // Sağ-sol padding
                                          child: Text(e.ayarAdi),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (LazerAyar? value) {
                                      ref.read(selectedAyarProvider.notifier).state = value;
                                      if (value != null) {
                                        ref.read(lazerHiziProvider.notifier).state =
                                            double.tryParse(value.lazerHizi) ?? 50.0;
                                        ref.read(lazerGucuProvider.notifier).state =
                                            double.tryParse(value.lazerGucu) ?? 50.0;
                                      }
                                    },
                                    value: selectedAyar,
                                  ),
                                );
                              },
                              error: (error, stack) => Text(error.toString()),
                              loading: () => const Center(child: CircularProgressIndicator()),
                            ),
                            if (selectedAyar != null) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: Card(
                                  elevation: 6,
                                  color: Theme.of(context).cardColor,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.settings,
                                        color: Colors.blue,
                                        size: 30,
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${selectedAyar!.ayarAdi}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.grey,
                                          )
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Lazer Hızı: ${selectedAyar!.lazerHizi}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          //const SizedBox(width: 8),
                                          Text(
                                            'Lazer Gücü: ${selectedAyar!.lazerGucu}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    //!Özel Ayar Seçimi
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Text('Lazer Hızı'),
                            ),
                            Row(
                              children: [
                                Text('0'),
                                Expanded(
                                  child: Slider(
                                    activeColor: Colors.blue,
                                    value: lazerHizi.toDouble(),
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: lazerHizi.toInt().toString(),
                                    onChanged: (value) {
                                      ref.read(lazerHiziProvider.notifier).state = value.toDouble();
                                    },
                                  ),
                                ),
                                Text('100'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Lazer Gücü'),
                            Row(
                              children: [
                                Text('0'),
                                Expanded(
                                  child: Slider(
                                    activeColor: Colors.blue,
                                    value: lazerGucu.toDouble(),
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: lazerGucu.toString(),
                                    onChanged: (double value) {
                                      ref.read(lazerGucuProvider.notifier).state = value.toDouble();
                                    },
                                  ),
                                ),
                                Text('100'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (gcodeSendingState.isLoading || !isBluetoothConnected)
                      ? null
                      : () => _handleSendButtonPressed(ref, selectedIndex, context),
                  child: gcodeSendingState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isBluetoothConnected ? 'Devam Et' : 'Bluetooth Bağlantısı Gerekli'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendButtonPressed(WidgetRef ref, int tabIndex, BuildContext context) async {
    // İptal edilmiş bir işlemden sonra yeni başlatma için state'i sıfırla
    if (ref.read(gcodeSendingProvider).isCancelled) {
      ref.read(gcodeSendingProvider.notifier).state = GCodeSendingState(
          isSending: false,
          isComplete: false,
          isLoading: true,
          isCancelled: false, // İptal durumunu sıfırla
          status: '',
          okResponseCount: 0,
          expectedOkCount: 0,
          currentPacketOkCount: 0);
    }
    // İlk olarak loading durumunu ayarla
    //ref.read(gcodeSendingProvider.notifier).setLoading(true);
    // Validate settings
    final selectedAyar = ref.watch(selectedAyarProvider);
    if (tabIndex == 0 && selectedAyar == null) {
      UIHelpers.showSnackBar(context, message: 'Lütfen bir ayar seçin', isError: true);
      return;
    }

    try {
      // Save settings based on tab
      if (tabIndex == 1) {
        // Custom settings
        final gCodeService = GCodeService(Dio());
        final result = await gCodeService.sendLazerKesimData(
          gcodeId: widget.gcodeId,
          lazerHiz: ref.read(lazerHiziProvider).toString(),
          lazerGucu: ref.read(lazerGucuProvider).toString(),
          aci: widget.aci.toString(),
          x: widget.xKoordinat.toString(),
          y: widget.yKoordinat.toString(),
          kontor: '1',
        );

        if (result.success) {
          ref.read(gcodeSendingProvider.notifier).setStatus('Lazer kesim bilgileri başarıyla kaydedildi');
          UIHelpers.showSnackBar(context, message: 'Lazer kesim bilgileri başarıyla kaydedildi', isError: false);
        } else {
          throw Exception(result.errorMessage ?? 'Lazer kesim bilgileri kaydedilemedi');
        }
      }

      // Show processing dialog
      _showProcessingDialog(ref);

      // Fetch G-codes
      ref.read(gcodeSendingProvider.notifier).setStatus('GCode verileri alınıyor...');
      final gcodeList = await ref.read(gcodeCekmeServisiProvider).fetchGCodeler();

      if (gcodeList.isEmpty) {
        ref.read(gcodeSendingProvider.notifier).setStatus('GCode verisi bulunamadı');
        ref.read(gcodeSendingProvider.notifier).state =
            ref.read(gcodeSendingProvider.notifier).state.copyWith(isComplete: true, isLoading: false);
        return;
      }

      // Start sending G-codes
      ref.read(gcodeSendingProvider.notifier).startSending(gcodeList);
    } catch (e) {
      ref.read(gcodeSendingProvider.notifier).setStatus('Hata: $e');
      UIHelpers.showSnackBar(context, message: 'Hata: Beklenmeyen bir hata oluştu', isError: true);
      ref.read(gcodeSendingProvider.notifier).setLoading(false);
    }
  }

  void _showProcessingDialog(WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final gcodeSendingState = ref.watch(gcodeSendingProvider);

            // İptal edildiğinde otomatik kapat
            if (gcodeSendingState.isCancelled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
              });
            }

            // İşlem tamamlandığında otomatik kapanış da ekleyebilirsiniz
            // (isteğe bağlı, buton yerine otomatik kapanmasını isterseniz)
            // if (gcodeSendingState.isComplete && !gcodeSendingState.isCancelled) {
            //   WidgetsBinding.instance.addPostFrameCallback((_) {
            //     // 2 saniye sonra otomatik kapat ve ana sayfaya git
            //     Future.delayed(Duration(seconds: 2), () {
            //       if (Navigator.of(dialogContext).canPop()) {
            //         Navigator.of(dialogContext).pop();
            //         Navigator.of(context).pushAndRemoveUntil(
            //           MaterialPageRoute(builder: (_) => const HomePage()),
            //           (route) => false,
            //         );
            //       }
            //     });
            //   });
            // }

            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('İşlem Durumu'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(gcodeSendingState.status),
                    const SizedBox(height: 16),
                    gcodeSendingState.isComplete
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 48)
                        : const CircularProgressIndicator(),
                  ],
                ),
                actions: [
                  if (!gcodeSendingState.isComplete && !gcodeSendingState.isCancelled)
                    TextButton(
                      onPressed: () {
                        ref.read(gcodeSendingProvider.notifier).cancelSending();
                        // Navigator artık otomatik kapanacak
                      },
                      child: const Text('Gönderimi İptal Et'),
                    ),
                  if (gcodeSendingState.isComplete)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => HomePage()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ana Sayfaya Dön'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
