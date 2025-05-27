// import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:makine/logger.dart';

// import 'package:makine/screens/gcode_display_screen.dart';
// import 'package:makine/screens/makineAyarlari/makine_options.dart';
// import 'package:makine/service/komut_service.dart';
// import 'package:makine/utils/ui_helpers.dart';

// class MakineOptionsScreen2 extends StatefulWidget {
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
//   State<MakineOptionsScreen2> createState() => _MakineOptionsScreen2State();
// }

// class _MakineOptionsScreen2State extends State<MakineOptionsScreen2> with TickerProviderStateMixin {
//   int lazerHizi = 50;
//   int lazerGucu = 50;
//   bool isLoading = false;
//   bool isLoadingAyarlar = true;
//   final GCodeService _gCodeService = GCodeService(Dio());
//   final Dio _dio = Dio();
//   late TabController tabController;
//   int selectedIndex = 0;
//   List<LazerAyar> ayarlar = [];
//   LazerAyar? selectedAyar;

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: true,
//       onPopInvokedWithResult: (didPop, result) {
//         SystemChrome.setPreferredOrientations([
//           DeviceOrientation.landscapeLeft,
//           DeviceOrientation.landscapeRight,
//         ]);
//       },
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
//                                   // child: Column(
//                                   //   crossAxisAlignment: CrossAxisAlignment.start,
//                                   //   children: [
//                                   //
//                                   //     const SizedBox(height: 8),

//                                   //   ],
//                                   // ),
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
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: isLoading ? null : _sendLazerKesimData,
//                   child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Devam Et'),
//                 ),
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
//   }

//   Future<void> _fetchGCodes() async {
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
//           _showErrorMessage("İşlenecek GCode URL'si bulunamadı");
//           setState(() {
//             isLoading = false;
//           });
//           return;
//         }

//         setState(() {
//           isLoading = false;
//         });
//         //? Bu kısımda artık kod gönderimi olacak diyalog çıkacak

//         //Navigate to BluetoothScannerScreen with GCode lines
//         if (mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => GCodeDisplayScreen(
//                 gcodeLines: urls,
//               ),
//             ),
//           );
//         }
//       } else {
//         _showErrorMessage("GCode URL'leri alınamadı");
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       _showErrorMessage("GCode URL'leri alınırken hata: $e");
//       logger.e(e.toString());
//       setState(() {
//         isLoading = false;
//       });
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
//     //! DEVAM ET BASINCA BURASI ÇALIŞIYOR
//     setState(() {
//       //todo: yükleniyor çıktı
//       isLoading = true;
//     });

//     try {
//       //todo: varsayılan ayar seçildiğinde
//       if (selectedIndex == 0) {
//         if (selectedAyar != null) {
//           lazerHizi = int.tryParse(selectedAyar!.lazerHizi) ?? 50;
//           lazerGucu = int.tryParse(selectedAyar!.lazerGucu) ?? 50;
//         } else {
//           _showErrorMessage('Lütfen bir ayar seçin');
//           setState(() {
//             isLoading = false;
//           });
//           return;
//         }
//       } else {
//         //todo: yeni ayarlar seçiliyse
//         lazerHizi = lazerHizi;
//         lazerGucu = lazerGucu;
//       }

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

//         // GCode URL'lerini al ve BluetoothScannerScreen'e yönlendir
//         await _fetchGCodes();
//       } else {
//         // API'den gelen hata mesajını göster
//         _showErrorMessage(result.errorMessage ?? 'Lazer kesim bilgileri kaydedilemedi');
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       _showErrorMessage('Hata: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
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
