// import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:makine/controller/bluetooth_controller.dart';
// import 'package:makine/logger.dart';
// import 'package:makine/screens/deneme.dart';
// import 'package:makine/screens/gcode_processor_screen.dart';
// import 'package:makine/screens/makineAyarlari/gcode_sender.dart';
// import 'package:makine/screens/makineAyarlari/gcode_sender_screen.dart';
// import 'package:makine/screens/profil/bluetooth_view.dart';
// import 'package:makine/service/komut_service.dart';
// import 'package:makine/stringKeys/string_utils.dart';
// import 'package:makine/utils/ui_helpers.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// // Lazer ayarları için model sınıfı
// class LazerAyar {
//   final String id;
//   final String ayarAdi;
//   final String lazerHizi;
//   final String lazerGucu;
//   final String createdAt;
//   final String status;

//   LazerAyar({
//     required this.id,
//     required this.ayarAdi,
//     required this.lazerHizi,
//     required this.lazerGucu,
//     required this.createdAt,
//     required this.status,
//   });

//   factory LazerAyar.fromJson(Map<String, dynamic> json) {
//     return LazerAyar(
//       id: json['id'] ?? '',
//       ayarAdi: json['ayar_adi'] ?? '',
//       lazerHizi: json['lazer_hizi'] ?? '',
//       lazerGucu: json['lazer_gucu'] ?? '',
//       createdAt: json['created_at'] ?? '',
//       status: json['status'] ?? '',
//     );
//   }
// }

// class MakineOptionsScreen3 extends StatefulWidget {
//   final double xKoordinat;
//   final double yKoordinat;
//   final double aci;
//   final String gcodeId;

//   const MakineOptionsScreen3({
//     super.key,
//     required this.xKoordinat,
//     required this.yKoordinat,
//     required this.aci,
//     required this.gcodeId,
//   });

//   @override
//   State<MakineOptionsScreen3> createState() => _MakineOptionsScreen3State();
// }

// class _MakineOptionsScreen3State extends State<MakineOptionsScreen3> with TickerProviderStateMixin {
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
//   late final GCodeService gCodeService;

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
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Ayar Adı: ${selectedAyar!.ayarAdi}'),
//                                     const SizedBox(height: 8),
//                                     Text('Lazer Hızı: ${selectedAyar!.lazerHizi}'),
//                                     const SizedBox(height: 8),
//                                     Text('Lazer Gücü: ${selectedAyar!.lazerGucu}'),
//                                   ],
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
//                                   activeColor: ConstanceVariable.bottomBarSelectedColor,
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
//                                   activeColor: ConstanceVariable.bottomBarSelectedColor,
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
//     // gCodeService = ref.read(gCodeServiceProvider);

//     // API'den ayarları yükle
//     _fetchLazerAyarlar();
//   }

//   // GCode verilerini oluştur (raw veriyi işleyerek)
//   Map<String, dynamic> _createGCodeDataFromResponse(dynamic responseData) {
//     // API yanıtı liste şeklinde geldi ise
//     if (responseData is List) {
//       return <String, dynamic>{
//         "user_id": 8,
//         "makine_id": "1234-5678-9012-3456",
//         "makine_ip": "192.168.1.1",
//         "cmd": responseData
//       };
//     }
//     // API yanıtı Map şeklinde ve cmd içeriyorsa
//     else if (responseData is Map && responseData.containsKey('cmd')) {
//       // Map'i string, dynamic tipine dönüştür
//       Map<String, dynamic> result = <String, dynamic>{};
//       responseData.forEach((key, value) {
//         result[key.toString()] = value;
//       });
//       return result;
//     }
//     // API yanıtı Map şeklinde ama cmd içermiyorsa
//     else if (responseData is Map) {
//       // Eğer veri var ama cmd yoksa
//       List<String> cmdList = [];

//       // Map'teki verileri stringlere dönüştürerek cmd listesi oluştur
//       responseData.forEach((key, value) {
//         if (value is String) {
//           cmdList.add(value);
//         } else if (value is List) {
//           for (var item in value) {
//             cmdList.add(item.toString());
//           }
//         }
//       });

//       return <String, dynamic>{
//         "user_id": 8,
//         "makine_id": "1234-5678-9012-3456",
//         "makine_ip": "192.168.1.1",
//         "cmd": cmdList.isEmpty ? ["No GCode data found"] : cmdList
//       };
//     }
//     // Diğer durumlar
//     else {
//       return <String, dynamic>{
//         "user_id": 8,
//         "makine_id": "1234-5678-9012-3456",
//         "makine_ip": "192.168.1.1",
//         "cmd": ["No valid GCode data found"]
//       };
//     }
//   }

//   // GCode komutlarını al ve işleme sayfasına yönlendir
//   Future<void> _fetchGCodesAndNavigate() async {
//     try {
//       // API'den GCode verilerini al
//       final response = await _dio.get(
//         "https://kardamiyim.com/laser/API/Controller.php?endpoint=cron/generateGCodes",
//         options: Options(
//           validateStatus: (status) => true,
//         ),
//       );

//       logger.i(response.data);

//       if (response.statusCode == 200) {
//         // Helper metod ile veriyi işle
//         final gCodeData = _createGCodeDataFromResponse(response.data);
//         print("gCodeData: $gCodeData");

//         // Bluetooth bağlantısını kontrol et
//         final FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
//         bool isConnected = false;

//         try {
//           // Bağlı cihazları kontrol et
//           List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
//           for (BluetoothDevice device in devices) {
//             try {
//               BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
//               if (connection.isConnected) {
//                 isConnected = true;

//                 // GCode gönderici oluştur ve başlat

//                 List<String> gcodeLines = List<String>.from(gCodeData['cmd']);

//                 // Navigator.push(
//                 //   context,
//                 //   MaterialPageRoute(
//                 //     builder: (context) => GCodeSenderScreen(
//                 //       gcodeLines: gcodeLines,
//                 //       connection: connection,
//                 //     ),
//                 //   ),
//                 // );

//                 // Başarı mesajı göster
//                 _showSuccessMessage('GCode gönderimi başladı');
//                 break;
//               }
//             } catch (e) {
//               print('Cihaz bağlantı hatası: $e');
//             }
//           }
//         } catch (e) {
//           print('Bluetooth kontrol hatası: $e');
//         }

//         // Eğer bağlantı yoksa BluetoothView'a yönlendir
//         if (!isConnected) {
//           if (mounted) {
//             _showErrorMessage('Bluetooth bağlantısı bulunamadı');
//             BluetoothController controller = BluetoothController();
//             Navigator.of(context).push(MaterialPageRoute(
//               builder: (context) => BluetoothView(controller),
//             ));
//           }
//         }
//       } else {
//         _showErrorMessage('GCode verileri alınamadı: ${response.statusCode}');
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       _showErrorMessage('GCode verileri alınırken hata: $e');
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
//     // İşlem gecikmesi için dialog göster
//     _sendRequest(); // Doğrudan isteği gönder
//   }

//   Future<void> _sendRequest() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       //todo: Varsayılan seçildiyse varsayılan ayarı al
//       if (selectedIndex == 0) {
//         lazerHizi = int.tryParse(selectedAyar!.lazerHizi) ?? 50;
//         lazerGucu = int.tryParse(selectedAyar!.lazerGucu) ?? 50;
//       } else {
//         //todo: Özel seçildiyse özel ayarı al- slider değerlerini al
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
//         _showSuccessMessage('Lazer kesim bilgileri başarıyla kaydedildi');

//         // GCode komutlarını al ve GCodeProcessorScreen'e yönlendir
//         await _fetchGCodesAndNavigate();
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

//   Future<bool> sendGCodeLines(List<String> lines) async {
//     for (String line in lines) {
//       if (line.isNotEmpty) {
//         await gCodeService.sendGCodeLine(line);
//         await Future.delayed(const Duration(milliseconds: 1)); // Gecikme ekleyebilirsiniz
//       }
//     }
//     inspect('Tüm GCode komutları gönderildi.');
//     return true;
//   }
// }
