// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:makine/logger.dart';

// import 'package:makine/screens/home_page.dart';
// import 'package:makine/screens/makineAyarlari/makine_options.dart';
// import 'package:makine/service/komut_service.dart';
// import 'package:makine/utils/ui_helpers.dart';
// import 'package:makine/viewmodel/provider.dart';

// class MakineOptionsScreen2 extends ConsumerStatefulWidget {
//   final double xKoordinat;
//   final double yKoordinat;
//   final double aci;
//   final String gcodeId;

//   const MakineOptionsScreen2({
//     super.key,
//     required this.xKoordinat,
//     required this.yKoordinat,
//     required this.aci,
//     required this.gcodeId,
//   });

//   @override
//   ConsumerState<MakineOptionsScreen2> createState() => _MakineOptionsScreen2State();
// }

// class _MakineOptionsScreen2State extends ConsumerState<MakineOptionsScreen2> with TickerProviderStateMixin {
//   int lazerHizi = 50;
//   int lazerGucu = 50;
//   //bool isLoading = false;
//   bool isLoadingAyarlar = true;
//   final GCodeService _gCodeService = GCodeService(Dio());
//   final Dio _dio = Dio();
//   late TabController tabController;
//   int selectedIndex = 0;
//   List<LazerAyar> ayarlar = [];
//   LazerAyar? selectedAyar;

//   // Bluetooth kontrolü için değişken
//   //bool isBluetoothConnected = false;

//   // GCode gönderme değişkenleri
//   bool _isSending = false;
//   bool _isComplete = false;
//   int _okResponseCount = 0;
//   StreamSubscription? _dataStreamSubscription;
//   String _deviceBuffer = '';
//   final Queue<String> _gcodeLinesQueue = Queue<String>();
//   List<String> _pendingLines = [];
//   int _currentPacketCharCount = 0;
//   int _expectedOkCount = 0;
//   int _currentPacketOkCount = 0;
//   List<String> _gcodeLines = [];

//   // Sınıf değişkeni olarak ekleyin
//   //bool _isCancelled = false;

//   @override
//   Widget build(BuildContext context) {
//     final isBluetoothConnected = ref.watch(isBluetoothConnectedProvider);
//     final isSending = ref.watch(isSendingProvider);
//     final isComplete = ref.watch(isCompleteProvider);
//     final isCancel = ref.watch(isCancelProvider);
//     final isLoading = ref.watch(isLoadingProvider);
//     return PopScope(
//       canPop: true,
//       onPopInvokedWithResult: (didPop, result) {},
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Makine Ayarları'),
//           bottom: TabBar(
//             controller: tabController,
//             indicatorSize: TabBarIndicatorSize.tab,
//             labelColor: Colors.black,
//             labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             indicator: BoxDecoration(
//               color: Theme.of(context).scaffoldBackgroundColor,
//               borderRadius: BorderRadius.only(
//                 topLeft: selectedIndex != 0 ? Radius.circular(5) : Radius.circular(0),
//                 topRight: selectedIndex == 0 ? Radius.circular(5) : Radius.circular(0),
//               ),
//             ),
//             unselectedLabelColor: Colors.white70,
//             indicatorColor: Colors.white,
//             tabs: [
//               Tab(text: 'Varsayılan'),
//               Tab(text: 'Özel'),
//             ],
//           ),
//         ),
//         body: Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Expanded(
//                 child: TabBarView(
//                   controller: tabController,
//                   children: [
//                     // Varsayılan ayarlar sekmesi
//                     Container(
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 16),
//                           isLoadingAyarlar
//                               ? const Center(child: CircularProgressIndicator())
//                               : ayarlar.isEmpty
//                                   ? const Center(
//                                       child: Text('Kayıtlı ayar bulunamadı'),
//                                     )
//                                   : DropdownButtonFormField<LazerAyar>(
//                                       decoration: const InputDecoration(
//                                         border: OutlineInputBorder(),
//                                         labelText: 'Ayar Seçin',
//                                       ),
//                                       value: selectedAyar,
//                                       items: ayarlar.map((LazerAyar ayar) {
//                                         return DropdownMenuItem<LazerAyar>(
//                                           value: ayar,
//                                           child: Text(ayar.ayarAdi),
//                                         );
//                                       }).toList(),
//                                       onChanged: (LazerAyar? value) {
//                                         setState(() {
//                                           selectedAyar = value;
//                                           if (value != null) {
//                                             // Seçilen ayarın değerlerini güncelle
//                                             lazerHizi = int.tryParse(value.lazerHizi) ?? 50;
//                                             lazerGucu = int.tryParse(value.lazerGucu) ?? 50;
//                                           }
//                                         });
//                                       },
//                                     ),
//                           if (selectedAyar != null) ...[
//                             const SizedBox(height: 20),
//                             SizedBox(
//                               width: double.infinity,
//                               child: Card(
//                                 elevation: 6,
//                                 color: Theme.of(context).cardColor,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16.0),
//                                   child: ListTile(
//                                     leading: Icon(
//                                       Icons.settings,
//                                       color: Colors.blue,
//                                       size: 30,
//                                     ),
//                                     title: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           '${selectedAyar!.ayarAdi}',
//                                           style: Theme.of(context).textTheme.titleMedium,
//                                         ),
//                                         Divider(
//                                           thickness: 1,
//                                           color: Colors.grey,
//                                         )
//                                       ],
//                                     ),
//                                     subtitle: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       mainAxisAlignment: MainAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Lazer Hızı: ${selectedAyar!.lazerHizi}',
//                                           style: Theme.of(context).textTheme.titleMedium,
//                                         ),
//                                         //const SizedBox(width: 8),
//                                         Text(
//                                           'Lazer Gücü: ${selectedAyar!.lazerGucu}',
//                                           style: Theme.of(context).textTheme.titleMedium,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                     // Özel ayarlar sekmesi
//                     SizedBox(
//                       width: double.infinity,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 16),
//                           const Text('Lazer Hızı'),
//                           const SizedBox(height: 16),
//                           Row(
//                             children: [
//                               Text('0'),
//                               Expanded(
//                                 child: Slider(
//                                   activeColor: Colors.blue,
//                                   value: lazerHizi.toDouble(),
//                                   min: 0,
//                                   max: 100,
//                                   divisions: 100,
//                                   label: lazerHizi.toString(),
//                                   onChanged: (double value) {
//                                     setState(() {
//                                       lazerHizi = value.toInt();
//                                     });
//                                   },
//                                 ),
//                               ),
//                               Text('100'),
//                             ],
//                           ),
//                           const SizedBox(height: 16),
//                           const Text('Lazer Gücü'),
//                           Row(
//                             children: [
//                               Text('0'),
//                               Expanded(
//                                 child: Slider(
//                                   activeColor: Colors.blue,
//                                   value: lazerGucu.toDouble(),
//                                   min: 0,
//                                   max: 100,
//                                   divisions: 100,
//                                   label: lazerGucu.toString(),
//                                   onChanged: (double value) {
//                                     setState(() {
//                                       lazerGucu = value.toInt();
//                                     });
//                                   },
//                                 ),
//                               ),
//                               Text('100'),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               //!GÖNDER BUTONU
//               Consumer(
//                 builder: (context, ref, child) {
//                   return SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                       ),
//                       onPressed: (isLoading || !isBluetoothConnected) ? null : _sendLazerKesimData,
//                       child: isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Text(isBluetoothConnected ? 'Devam Et' : 'Bluetooth Bağlantısı Gerekli'),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitDown,
//       DeviceOrientation.portraitUp,
//     ]);
//     tabController = TabController(length: 2, vsync: this);
//     tabController.addListener(() {
//       setState(() {
//         selectedIndex = tabController.index;
//       });
//     });

//     // API'den ayarları yükle
//     _fetchLazerAyarlar();

//     // Bluetooth kontrolü
//     _checkBluetooth();
//   }

//   @override
//   void dispose() {
//     _dataStreamSubscription?.cancel();
//     super.dispose();
//   }

//   // Bluetooth bağlantısını kontrol et
//   void _checkBluetooth() {
//     final controller = ref.read(bluetoothControllerProvider);
//     final isConnected = controller.isConnected;

//     // Provider durumunu güncelle
//     ref.read(isBluetoothConnectedProvider.notifier).state = isConnected;

//     if (!isConnected) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => AlertDialog(
//             title: Row(
//               children: [
//                 Icon(
//                   Icons.bluetooth_disabled_outlined,
//                   color: Colors.blue,
//                 ),
//                 SizedBox(
//                   width: 20,
//                 ),
//                 Text(
//                   'Uyarı',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue),
//                 ),
//               ],
//             ),
//             content: Text(
//               'Bluetooth Bağlantısı Yok. Lütfen Bağlantınızı Kontrol Ediniz.',
//               style: Theme.of(context).textTheme.titleMedium,
//             ),
//             actions: [
//               TextButton(
//                 style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                         side: BorderSide(color: Colors.blue), borderRadius: BorderRadius.circular(20))),
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: Text(
//                   'Kapat',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue),
//                 ),
//               ),
//             ],
//           ),
//         );
//       });
//     }
//   }

//   Future<bool> _fetchGCodes() async {
//     ref.read(processStatusProvider.notifier).state = 'GCode dosyaları çekiliyor...';

//     try {
//       final response = await _dio.get(
//         "https://kardamiyim.com/laser/API/Controller.php?endpoint=cron/generateGCodes",
//         options: Options(
//           validateStatus: (status) => true,
//         ),
//       );

//       logger.d(response.data);

//       if (response.statusCode == 200 && response.data is Map && response.data.containsKey('cmd')) {
//         final List<String> urls = List<String>.from(response.data['cmd']);
//         inspect(urls);

//         if (urls.isEmpty) {
//           ref.read(processStatusProvider.notifier).state = "Hata: İşlenecek GCode URL'si bulunamadı";
//           _showErrorMessage("İşlenecek GCode URL'si bulunamadı");
//           setState(() {
//             isLoading = false;
//           });
//           return false;
//         }

//         // GCode URL'lerini kaydet
//         _gcodeLines = urls;

//         // Durumu güncelle
//         ref.read(processStatusProvider.notifier).state = "GCode'lar başarıyla çekildi. Gönderim için hazırlanıyor...";

//         return true;
//       } else {
//         ref.read(processStatusProvider.notifier).state = "Hata: GCode URL'leri alınamadı";
//         _showErrorMessage("GCode URL'leri alınamadı");
//         setState(() {
//           isLoading = false;
//         });
//         return false;
//       }
//     } catch (e) {
//       ref.read(processStatusProvider.notifier).state = "Hata: GCode URL'leri alınırken hata: $e";
//       _showErrorMessage("GCode URL'leri alınırken hata: $e");
//       logger.e(e.toString());
//       setState(() {
//         isLoading = false;
//       });
//       return false;
//     }
//   }

//   // API'den lazer ayarlarını getir
//   Future<void> _fetchLazerAyarlar() async {
//     setState(() {
//       isLoadingAyarlar = true;
//     });

//     try {
//       final response = await _dio.get(
//         'https://kardamiyim.com/laser/API/Controller.php?endpoint=ayar/get',
//         options: Options(
//           validateStatus: (status) => true,
//         ),
//       );
//       print(response.data);

//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data;
//         setState(() {
//           ayarlar = data.map((item) => LazerAyar.fromJson(item)).toList();
//           isLoadingAyarlar = false;

//           // Eğer ayar varsa ilk ayarı seç
//           if (ayarlar.isNotEmpty) {
//             selectedAyar = ayarlar.first;
//             lazerHizi = int.tryParse(selectedAyar!.lazerHizi) ?? 50;
//             lazerGucu = int.tryParse(selectedAyar!.lazerGucu) ?? 50;
//           }
//         });
//       } else {
//         _showErrorMessage('Ayarlar yüklenemedi: ${response.statusCode}');
//         setState(() {
//           isLoadingAyarlar = false;
//         });
//       }
//     } catch (e) {
//       _showErrorMessage('Ayarlar yüklenirken hata: $e');
//       setState(() {
//         isLoadingAyarlar = false;
//       });
//     }
//   }

//   Future<void> _sendLazerKesimData() async {
//     //yüklenme true - gönderiliyor true - tamamlandı false -iptal hala false
//     ref.read(isLoadingProvider.notifier).state = true;
//     ref.read(isSendingProvider.notifier).state = true;

//     //! DEVAM ET BASINCA BURASI ÇALIŞIYOR
//     // Bluetooth kontrolünü bir kez daha yap
//     final controller = ref.read(bluetoothControllerProvider);

//     // Provider'ı sıfırla ve başlangıç durumunu ayarla
//     ref.read(processStatusProvider.notifier).state = 'İşlem başlatılıyor...';

//     // İşlem diyaloğunu göster
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return Consumer(
//           builder: (context, ref, child) {
//             // Provider'dan işlem durumunu al
//             final processStatus = ref.watch(processStatusProvider);
//             final isComplete = ref.watch(isCompleteProvider);
//             final isSending = ref.watch(isSendingProvider);

//             return WillPopScope(
//               onWillPop: () async => false, // Geri tuşuyla kapatılamaz
//               child: AlertDialog(
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(processStatus),
//                     SizedBox(height: 16),
//                     isComplete
//                         ? Icon(Icons.check_circle, color: Colors.green)
//                         : CircularProgressIndicator(
//                             color: Colors.blue,
//                           ),
//                   ],
//                 ),
//                 actions: [
//                   // İşlem tamamlandıysa Ana Sayfa butonunu göster
//                   if (isComplete)
//                     ElevatedButton(
//                       onPressed: () {
//                         //tamamlandıysa yükleme false - gönderme false - tamamlandı yönlendirildikten sonra false olmalı.

//                         // ilk önce diyalog kapat sonra yönlendir.
//                         if (mounted && Navigator.of(context).canPop()) {
//                           Navigator.of(context).pop();
//                         }
//                         ref.read(isCompleteProvider.notifier).state = false;
//                         ref.read(isLoadingProvider.notifier).state = false;
//                         ref.read(isSendingProvider.notifier).state = false;
//                         Navigator.of(context).pushAndRemoveUntil(
//                           MaterialPageRoute(builder: (context) => const HomePage()),
//                           (route) => false,
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                       ),
//                       child: Text('Ana Sayfaya Dön'),
//                     ),

//                   // Gönderim devam ediyorsa ve tamamlanmamışsa İptal butonunu göster
//                   if (isSending && !isComplete)
//                     ElevatedButton(
//                       onPressed: () async {
//                         try {
//                           // Önce iptal bayrağını ayarlayın
//                           ref.read(isCancelProvider.notifier).state = true;

//                           // Önce M5 komutunu gönder ve yanıtı bekle
//                           controller.connection!.output.add(Uint8List.fromList(utf8.encode("M5\n")));
//                           await controller.connection!.output.allSent;
//                           ref.read(processStatusProvider.notifier).state = 'İptal ediliyor...';
//                           await Future.delayed(const Duration(milliseconds: 500)); // Yanıt için bekle

//                           // Sonra $H komutunu gönder ve yanıtı bekle
//                           controller.connection!.output.add(Uint8List.fromList(utf8.encode("\$H\n")));
//                           await controller.connection!.output.allSent;
//                           await Future.delayed(const Duration(milliseconds: 500)); // Yanıt için bekle
//                         } catch (e) {
//                           _showErrorMessage('Acil durum komutları gönderilemedi: $e');
//                         }

//                         // Gönderimi durdur
//                         _gcodeLinesQueue.clear(); // Kalan komutları temizle
//                         _pendingLines.clear(); // Bekleyen komutları temizle

//                         ref.read(isSendingProvider.notifier).state = false;
//                         ref.read(isCompleteProvider.notifier).state = false;
//                         ref.read(isLoadingProvider.notifier).state = false;

//                         // İptal mesajını göster
//                         ref.read(processStatusProvider.notifier).state = 'Gönderim iptal edildi';
//                         //_showErrorMessage('Gönderim kullanıcı tarafından iptal edildi');

//                         // Kısa bir gecikme ekle ve diyaloğu kapat
//                         // await Future.delayed(const Duration(milliseconds: 500));
//                         if (mounted && Navigator.of(context).canPop()) {
//                           Navigator.of(context).pop();
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                       ),
//                       child: const Text('Gönderimi İptal Et'),
//                     ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );

//     try {
//       //todo: varsayılan ayar seçildiğinde
//       if (selectedIndex == 0) {
//         if (selectedAyar != null) {
//           lazerHizi = int.tryParse(selectedAyar!.lazerHizi) ?? 50;
//           lazerGucu = int.tryParse(selectedAyar!.lazerGucu) ?? 50;
//         } else {
//           ref.read(processStatusProvider.notifier).state = 'Hata: Lütfen bir ayar seçin';
//           // Dialog'u kapat
//           if (mounted && Navigator.of(context).canPop()) {
//             Navigator.of(context).pop();
//           }

//           _showErrorMessage('Lütfen bir ayar seçin');
//           //Ayar seçilmemişse diyalog açılmamalı!
//           ref.read(isLoadingProvider.notifier).state = false;
//           ref.read(isSendingProvider.notifier).state = false;
//           return;
//         }
//       }

//       // Durum mesajını güncelle
//       ref.read(processStatusProvider.notifier).state = 'Lazer kesim ayarları gönderiliyor...';

//       final result = await _gCodeService.sendLazerKesimData(
//         gcodeId: widget.gcodeId,
//         lazerHiz: lazerHizi.toString(),
//         lazerGucu: lazerGucu.toString(),
//         aci: widget.aci.toString(),
//         x: widget.xKoordinat.toString(),
//         y: widget.yKoordinat.toString(),
//         kontor: '1', // Varsayılan değer
//       );

//       if (result.success) {
//         if (selectedIndex == 1) {
//           _showSuccessMessage('Lazer kesim bilgileri başarıyla kaydedildi');
//         }

//         // GCode URL'lerini al
//         ref.read(processStatusProvider.notifier).state = 'GCode dosyaları çekiliyor...';
//         bool fetchSuccess = await _fetchGCodes();

//         if (fetchSuccess) {
//           // GCode gönderimi başlat
//           ref.read(processStatusProvider.notifier).state = 'GCode gönderimi başlatılıyor...';

//           // GCode gönderme işlemini başlat
//           _startSending();
//         } else {
//           // İşlem tamamlanamadı, diyaloğu kapat
//           if (mounted && Navigator.of(context).canPop()) {
//             Navigator.of(context).pop();
//           }
//           setState(() {
//             isLoading = false;
//           });
//         }
//       } else {
//         // Hata durumu
//         ref.read(processStatusProvider.notifier).state = 'Hata: ${result.errorMessage ?? "Bilinmeyen hata"}';

//         // Dialog'u kapat
//         if (mounted && Navigator.of(context).canPop()) {
//           Navigator.of(context).pop();
//         }

//         // API'den gelen hata mesajını göster
//         _showErrorMessage(result.errorMessage ?? 'Lazer kesim bilgileri kaydedilemedi');
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       // Hata durumu
//       ref.read(processStatusProvider.notifier).state = 'Hata: $e';

//       // Dialog'u kapat
//       if (mounted && Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }

//       _showErrorMessage('Hata: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   // BluetoothSenderScreen'den alınan GCode gönderme metotları
//   void _startSending() {
//     final isSending = ref.watch(isSendingProvider);
//     if (isSending) return;

//     setState(() {
//       _isSending = true;
//       _okResponseCount = 0;
//       _currentPacketOkCount = 0;
//       _expectedOkCount = 0;
//     });

//     _initializeQueue(); // Kuyruğu başlat
//     _listenForDeviceData();

//     _processNextBatch();
//   }

//   void _initializeQueue() {
//     // Tüm G-code satırlarını kuyruğa ekle
//     _gcodeLinesQueue.addAll(_gcodeLines);
//     ref.read(processStatusProvider.notifier).state = 'G-code kuyruğu hazırlandı (${_gcodeLinesQueue.length} satır)';
//   }

//   void _listenForDeviceData() {
//     final controller = ref.read(bluetoothControllerProvider);
//     final stream = controller.getDataStream();
//     if (stream == null) return;

//     _dataStreamSubscription = stream.listen(
//       (data) {
//         // İptal edilmişse hiçbir şey yapma
//         if (_isCancelled) return;

//         _deviceBuffer += data;
//         if (_deviceBuffer.contains('\n')) {
//           var lines = _deviceBuffer.split('\n');
//           _deviceBuffer = lines.removeLast();

//           for (var line in lines) {
//             line = line.trim();
//             if (line.isNotEmpty) {
//               if (line.toLowerCase().contains('ok')) {
//                 setState(() {
//                   _okResponseCount++;
//                   _currentPacketOkCount++;
//                 });
//                 ref.read(processStatusProvider.notifier).state =
//                     'Gönderim devam ediyor... (OK: $_okResponseCount, Paket: $_currentPacketOkCount/$_expectedOkCount)';

//                 // Eğer bu paketteki tüm OK'ler geldiyse yeni paketi işle
//                 if (_currentPacketOkCount >= _expectedOkCount) {
//                   Future.microtask(() => _processNextBatch());
//                 }
//               }
//             }
//           }
//         }
//       },
//       onError: (error) {
//         ref.read(processStatusProvider.notifier).state = 'Veri akışı hatası: $error';
//       },
//       onDone: () {
//         ref.read(processStatusProvider.notifier).state = 'Bağlantı kapandı';
//       },
//     );
//   }

//   Future<void> _processNextBatch() async {
//     if (_gcodeLinesQueue.isEmpty && !_isSending && !_isComplete) {
//       setState(() {
//         _isComplete = true;
//         _isSending = false;
//       });
//       if (mounted && Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//       _clearMemory();
//       ref.read(processStatusProvider.notifier).state = 'Gönderim tamamlandı';
//       return;
//     }

//     // Eğer önceki paketin tüm OK'leri gelmemişse bekle
//     if (_currentPacketOkCount < _expectedOkCount || _gcodeLinesQueue.isEmpty) return;

//     _pendingLines = [];
//     _currentPacketCharCount = 0;
//     // Yeni paket için OK sayaçlarını sıfırla
//     _currentPacketOkCount = 0;
//     _expectedOkCount = 0;

//     // Satırları tek tek kontrol et
//     while (_gcodeLinesQueue.isNotEmpty) {
//       String nextLine = _gcodeLinesQueue.first;
//       String cleanLine = nextLine.replaceAll('"', '');
//       int lineLength = cleanLine.length + 1; // Sadece \n için +1

//       if (_currentPacketCharCount + lineLength > 254) {
//         break;
//       }

//       _gcodeLinesQueue.removeFirst();
//       _pendingLines.add(cleanLine);
//       _currentPacketCharCount += lineLength;
//       _expectedOkCount++; // Her eklenen satır için bir OK bekliyoruz
//     }

//     if (_pendingLines.isNotEmpty) {
//       await _sendPendingLines();
//       if (_gcodeLinesQueue.isEmpty) {
//         setState(() {
//           _isComplete = true;
//           _isSending = false;
//         });

//         // Bellek temizliği
//         _clearMemory();
//         //!BU KISIMDA ÇALIŞTI
//         if (mounted && Navigator.of(context).canPop()) {
//           Navigator.of(context).pop();
//         }
//         //İşlem tamamlandıktan sonra ana sayfaya yönlendir
//         Future.delayed(const Duration(seconds: 1), () {
//           if (mounted) {
//             Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(builder: (context) => const HomePage()),
//               (route) => false,
//             );
//           }
//         });
//       }
//     } else if (_gcodeLinesQueue.isEmpty) {
//       setState(() {
//         _isComplete = true;
//         _isSending = false;
//       });

//       // Bellek temizliği
//       _clearMemory();
//       if (mounted && Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }
//       //İşlem tamamlandıktan sonra ana sayfaya yönlendir
//       Future.delayed(const Duration(seconds: 1), () {
//         if (mounted) {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => const HomePage()),
//             (route) => false,
//           );
//         }
//       });
//     }
//   }

//   Future<void> _sendPendingLines() async {
//     final controller = ref.read(bluetoothControllerProvider);
//     try {
//       String batchContent = _pendingLines.map((line) => '$line\n').join();

//       controller.connection!.output.add(Uint8List.fromList(utf8.encode(batchContent)));
//       await controller.connection!.output.allSent;

//       // Gereksiz güncelleme kaldırıldı
//       // setState(() {
//       //   _progress = 1 - (_gcodeLinesQueue.length / _gcodeLines.length);
//       // });
//     } catch (e) {
//       ref.read(processStatusProvider.notifier).state = 'Gönderim hatası: $e';
//     }
//   }

//   // Bellek temizliği
//   void _clearMemory() {
//     // Büyük veri yapılarını temizle
//     _pendingLines.clear();
//     _gcodeLinesQueue.clear();

//     // Veri akışını iptal et ve yeniden bağlı olup olmadığını kontrol et
//     if (_dataStreamSubscription != null) {
//       _dataStreamSubscription!.cancel();
//       _listenForDeviceData(); // Gerekirse yeniden bağlan
//     }

//     // Zorunlu çöp toplama tavsiyesi
//     // (Not: Bu garanti edilmez ama tavsiye niteliğindedir)
//     // ignore: unnecessary_statements
//     const Duration(seconds: 1);
//   }

//   void _showErrorMessage(String message) {
//     UIHelpers.showSnackBar(
//       context,
//       message: message,
//       isError: true,
//     );
//   }

//   void _showSuccessMessage(String message) {
//     UIHelpers.showSnackBar(
//       context,
//       message: message,
//       isError: false,
//     );
//   }
// }
