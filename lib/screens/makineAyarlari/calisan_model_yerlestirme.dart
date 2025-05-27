// import 'dart:math';
// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:makine/model/extra_detay_model.dart';
// import 'package:makine/screens/bluetooth/bluetooth_scanner_screen.dart';
// import 'package:makine/screens/home_page.dart';
// import 'package:makine/screens/makineAyarlari/makine_options2.dart';
// import 'package:makine/utils/ui_helpers.dart';
// import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
// import 'package:sleek_circular_slider/sleek_circular_slider.dart';
// import 'package:makine/viewmodel/provider.dart';
// import 'package:dio/dio.dart';

// class ModelYerlestirme extends ConsumerStatefulWidget {
//   final List<EDetay> data;
//   const ModelYerlestirme({super.key, required this.data});

//   @override
//   ConsumerState<ModelYerlestirme> createState() => _ModelYerlestirmeState();
// }

// class _ModelYerlestirmeState extends ConsumerState<ModelYerlestirme> {
//   // Lazer makinesi gerçek boyutları (mm cinsinden)
//   static const double LASER_WIDTH_MM = 292.1; // 25 cm
//   static const double LASER_HEIGHT_MM = 502.8; // 35 cm
//   // Ekrandaki görüntü boyutları (piksel)
//   static const double imageWidth = 100.0; // Genişliği artırıldı
//   static const double imageHeight = 100.0; // Yüksekliği artırıldı
//   final TransformationController _transformationController = TransformationController();

//   bool _isMirrored = false;
//   Offset _imagePosition = const Offset(5, 5);

//   bool _isImageLoading = true;
//   bool _hasError = false;
//   double rotation = 0;
//   @override
//   Widget build(BuildContext context) {
//     final EDetay selectedDetail = widget.data.isNotEmpty
//         ? widget.data.first
//         : EDetay(
//             id: 0,
//             modelId: 0,
//             detayAdi: "Placeholder",
//             detayResmi: "https://via.placeholder.com/150", // Varsayılan bir resim
//             createdAt: "",
//             turId: 0,
//           );

//     final double containerWidth = MediaQuery.of(context).size.width;
//     final double containerHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 226, 226, 226),
//       appBar: AppBar(
//         title: const Text('Model Yerleştirme'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.flip),
//             onPressed: _toggleMirror,
//             tooltip: 'Y eksenine göre simetri',
//           ),
//           IconButton(
//             icon: const Icon(Icons.home),
//             onPressed: () {
//               Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (context) => const HomePage()),
//                 (route) => false,
//               );
//             },
//             tooltip: 'Ana Sayfa',
//           ),
//           //!KİLİT KALDIRMA
//           IconButton(
//             icon: const Icon(Icons.lock),
//             onPressed: () {
//               _sendGCodeCommand('\$X');
//             },
//           ),
//           //! DENEME GCODE GÖNDERME
//           TextButton(
//               onPressed: () {
//                 testGCode(selectedDetail.modelId);
//               },
//               child: Text(
//                 "Dene",
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
//               ))
//         ],
//       ),
//       body: Row(
//         children: [
//           // Sol panel (model yerleştirme alanı)
//           Flexible(
//             flex: 8,
//             child: Center(
//               child: Container(
//                 width: containerWidth * 0.8,
//                 height: containerHeight * 0.8,
//                 color: Colors.grey.shade300,
//                 child: Stack(
//                   children: [
//                     Positioned(
//                       left: _imagePosition.dx,
//                       top: _imagePosition.dy,
//                       child: GestureDetector(
//                         onPanUpdate: (details) {
//                           setState(() {
//                             // Yeni pozisyonu hesapla
//                             double newX = _imagePosition.dx + details.delta.dx;
//                             double newY = _imagePosition.dy + details.delta.dy;

//                             // Sınır kontrolü
//                             if (newX < 0) newX = 0;
//                             if (newY < 0) newY = 0;
//                             if (newX > containerWidth * 0.8 - imageWidth) {
//                               newX = containerWidth * 0.8 - imageWidth;
//                             }
//                             if (newY > containerHeight * 0.8 - imageHeight) {
//                               newY = containerHeight * 0.8 - imageHeight;
//                             }

//                             _imagePosition = Offset(newX, newY);
//                           });

//                           // HAREKET SONRASI G90 ve G0 komutlarını gönder
//                           _sendGCodeCommand('G90');
//                           _sendGCodeCommand(
//                               'G0 X${_getActualX().toStringAsFixed(2)} Y${_getActualY().toStringAsFixed(2)} F400');
//                         },
//                         child: Transform.rotate(
//                           angle: rotation * (pi / 180),
//                           alignment: Alignment.center,
//                           child: Container(
//                             width: imageWidth,
//                             height: imageHeight,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[200],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(8),
//                               child: Image(
//                                 image: NetworkImage(selectedDetail.detayResmi),
//                                 fit: BoxFit.contain,
//                                 loadingBuilder: (context, child, loadingProgress) {
//                                   if (loadingProgress == null) {
//                                     _isImageLoading = false;
//                                     return child;
//                                   }
//                                   return Center(
//                                     child: CircularProgressIndicator(
//                                       value: loadingProgress.expectedTotalBytes != null
//                                           ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                                           : null,
//                                     ),
//                                   );
//                                 },
//                                 errorBuilder: (context, error, stackTrace) {
//                                   _hasError = true;
//                                   return Container(
//                                     color: Colors.grey[300],
//                                     child: const Center(
//                                       child: Icon(
//                                         Icons.error_outline,
//                                         color: Colors.red,
//                                         size: 30,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Sağ panel (kontroller)
//           Flexible(
//             flex: 2,
//             child: Container(
//               color: Colors.white,
//               height: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: SingleChildScrollView(
//                 // Eğer içerik çok fazlaysa scroll ekleyin
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 5),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           InkWell(
//                             onTap: () {
//                               setState(() {
//                                 rotation = (rotation - 1) % 360;
//                               });
//                             },
//                             child: const Padding(
//                               padding: EdgeInsets.all(8.0),
//                               child: Icon(
//                                 Icons.remove_circle_outline,
//                                 size: 25,
//                               ),
//                             ),
//                           ),
//                           SleekCircularSlider(
//                             appearance: CircularSliderAppearance(
//                               customWidths: CustomSliderWidths(
//                                 trackWidth: 4,
//                                 progressBarWidth: 4,
//                                 shadowWidth: 3,
//                               ),
//                               customColors: CustomSliderColors(
//                                 trackColor: Colors.grey[300],
//                                 progressBarColor: Colors.blue,
//                                 shadowColor: Colors.blue.withOpacity(0.2),
//                               ),
//                               startAngle: 180,
//                               angleRange: 360,
//                               size: 60.0,
//                             ),
//                             min: 0,
//                             onChangeEnd: (value) {
//                               setState(() {
//                                 rotation = value;
//                               });
//                             },
//                             onChangeStart: (value) {
//                               setState(() {
//                                 rotation = value;
//                               });
//                             },
//                             max: 360,
//                             initialValue: rotation,
//                             onChange: (double value) {
//                               setState(() {
//                                 rotation = value;
//                               });
//                             },
//                             innerWidget: (percentage) {
//                               return Center(
//                                 child: Text(
//                                   '${percentage.toInt()}°',
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           InkWell(
//                             onTap: () {
//                               setState(() {
//                                 rotation = (rotation + 1) % 360;
//                               });
//                             },
//                             child: const Padding(
//                               padding: EdgeInsets.all(8.0),
//                               child: Icon(
//                                 Icons.add_circle_outline,
//                                 size: 25,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       alignment: Alignment.center,
//                       height: 30,
//                       margin: const EdgeInsets.only(top: 10),
//                       child: OutlinedButton(
//                         onPressed: () {
//                           setState(() {
//                             rotation = 0;
//                           });
//                         },
//                         style: OutlinedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(horizontal: 20),
//                           foregroundColor: Colors.black,
//                         ),
//                         child: const Text('Açı Sıfırla'),
//                       ),
//                     ),
//                     Divider(),

//                     Text(
//                       "Lazer Makinesi Konumu",
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                     //const SizedBox(height: 5),
//                     Center(
//                       child: Column(
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.keyboard_arrow_up, size: 30),
//                             onPressed: () async {
//                               _sendGCodeCommand('G91');
//                               _sendGCodeCommand('G1 Y-2 F500');
//                               _sendGCodeCommand('G90');
//                             },
//                           ),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.keyboard_arrow_left, size: 30),
//                                 onPressed: () async {
//                                   _sendGCodeCommand('G91');
//                                   _sendGCodeCommand('G1 X-2 F500');
//                                   _sendGCodeCommand('G90');
//                                 },
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.home, size: 30),
//                                 onPressed: () => _sendGCodeCommand("\$H"),
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.keyboard_arrow_right, size: 30),
//                                 onPressed: () async {
//                                   _sendGCodeCommand('G91');
//                                   _sendGCodeCommand('G1 X2 F500');
//                                   _sendGCodeCommand('G90');
//                                 },
//                               ),
//                             ],
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.keyboard_arrow_down, size: 30),
//                             onPressed: () async {
//                               _sendGCodeCommand('G91');
//                               _sendGCodeCommand('G1 Y2 F500');
//                               _sendGCodeCommand('G90');
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       alignment: Alignment.center,
//                       height: 30,
//                       margin: const EdgeInsets.only(bottom: 7),
//                       child: ElevatedButton(
//                         onPressed: () {
//                           pageRouteBuilder(
//                               context,
//                               MakineOptionsScreen2(
//                                 xKoordinat: _getActualX(),
//                                 yKoordinat: _getActualY(),
//                                 aci: rotation,
//                                 gcodeId: selectedDetail.modelId.toString(),
//                               )
//                               // MakineOptionsScreen3(
//                               //   xKoordinat: _getActualX(),
//                               //   yKoordinat: _getActualY(),
//                               //   aci: rotation,
//                               //   gcodeId: selectedDetail.modelId.toString(),
//                               // )
//                               );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.symmetric(horizontal: 20),
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                         ),
//                         child: const Text('Devam Et'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // Ekran yönlendirmesini varsayılan duruma döndür
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//     _transformationController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();

//     // Debug için model bilgisini yazdır
//     print("Model Yerleştirme Ekranına Gelen Data:");
//     for (var item in widget.data) {
//       print("ID: ${item.id}, ModelID: ${item.modelId}, DetayAdi: ${item.detayAdi}");
//     }

//     // Ekranı yatay moda sabitle
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//   }

//   // Gerçek koordinatları hesaplama fonksiyonları
//   double _getActualX() {
//     // Ekran koordinatlarını gerçek koordinatlara çevirme
//     double containerWidth = MediaQuery.of(context).size.width * 0.8;
//     double scaleX = LASER_WIDTH_MM / containerWidth;
//     return _imagePosition.dx * scaleX;
//   }

//   double _getActualY() {
//     // Ekran koordinatlarını gerçek koordinatlara çevirme
//     double containerHeight = MediaQuery.of(context).size.height * 0.8;
//     double scaleY = LASER_HEIGHT_MM / containerHeight;
//     return _imagePosition.dy * scaleY;
//   }

//   void _showMessage(String message, bool isError) {
//     UIHelpers.showSnackBar(
//       context,
//       message: message,
//       isError: isError,
//     );
//   }

//   void _toggleMirror() {
//     setState(() {
//       _isMirrored = !_isMirrored;
//     });
//   }

//   Future<void> _sendGCodeCommand(String command) async {
//     final controller = ref.read(bluetoothControllerProvider);

//     if (controller.connection == null) {
//       _showMessage('Bluetooth bağlantısı yok! Cihaz seçmek için yönlendiriliyorsunuz.', true);

//       // Snackbar'ın gösterilmesini bekle, sonra yönlendir
//       await Future.delayed(const Duration(milliseconds: 500));
//       if (!mounted) return; // Widget hala ekranda mı kontrol et

//       Navigator.of(context).push(
//         MaterialPageRoute(builder: (context) => BluetoothScannerScreen()),
//       );
//       return;
//     }

//     try {
//       controller.connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
//       await controller.connection!.output.allSent;
//       // Başarılı gönderimde mesaj gösterme!
//     } catch (e) {
//       _showMessage('Gönderim hatası: $e', true);
//     }
//   }

//   Future<void> testGCode(int modelId) async {
//     final dio = Dio();
//     final url = 'https://kardamiyim.com/laser/API/Controller.php?endpoint=gcode/test&id=$modelId';
//     try {
//       final response = await dio.get(url);

//       if (response.statusCode == 200) {
//         final gcode = response.data["data"];

//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Gelen GCode'),
//             content: SingleChildScrollView(
//               child: Text(gcode),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Kapat'),
//               ),
//               // Gönder butonu ekleniyor
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Önce diyaloğu kapat
//                   _sendGcodeToMachine(gcode); // Sonra makinaya gönder
//                 },
//                 child: const Text('Makineye Gönder'),
//               ),
//             ],
//           ),
//         );
//       } else {
//         print('Hata: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('İstek hatası: $e');
//     }
//   }

//   // Gelen G-code satırlarını makineye gönderen fonksiyon
//   Future<void> _sendGcodeToMachine(String gcodeText) async {
//     // Bluetooth bağlantısını kontrol et
//     final controller = ref.read(bluetoothControllerProvider);
//     if (controller.connection == null || !controller.isConnected) {
//       _showMessage('Bluetooth bağlantınız yok!', true);
//       return; // Bluetooth bağlantısı yoksa işlemi sonlandır
//     }

//     _showMessage('G-code gönderimi başlıyor...', false);

//     // İlerleme durumunu gösterecek bir diyalog göster
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamaz
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('G-Code Gönderiliyor'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const LinearProgressIndicator(),
//                   const SizedBox(height: 16),
//                   const Text('Komutlar gönderiliyor, lütfen bekleyin...'),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );

//     try {
//       // Satırlara ayır
//       final List<String> gcodeLines = gcodeText.split('\n');
//       int total = gcodeLines.length;
//       int current = 0;

//       // Her bir satırı sırayla gönder
//       for (String line in gcodeLines) {
//         line = line.trim();
//         if (line.isNotEmpty) {
//           await _sendGCodeCommand(line);
//           // Komutlar arasında biraz beklet (makinenin işleme zamanı için)
//           await Future.delayed(const Duration(milliseconds: 300));
//           current++;
//         }
//       }

//       // İşlem tamamlandığında diyaloğu kapat
//       if (mounted) {
//         Navigator.of(context).pop(); // Diyaloğu kapat
//         _showMessage('G-code gönderimi tamamlandı (${gcodeLines.length} komut)', false);
//       }
//     } catch (e) {
//       // Hata durumunda diyaloğu kapat ve hata mesajı göster
//       if (mounted) {
//         Navigator.of(context).pop(); // Diyaloğu kapat
//         _showMessage('G-code gönderimi sırasında hata: $e', true);
//       }
//     }
//   }
// }
