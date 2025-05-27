// // lib/screens/gcode/gcode_sender_screen.dart

// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:makine/screens/makineAyarlari/gcode_sender.dart';

// class GCodeSenderScreen extends StatefulWidget {
//   final List<String> gcodeLines;
//   final BluetoothConnection connection;

//   const GCodeSenderScreen({
//     required this.gcodeLines,
//     required this.connection,
//     super.key,
//   });

//   @override
//   State<GCodeSenderScreen> createState() => _GCodeSenderScreenState();
// }

// class _GCodeSenderScreenState extends State<GCodeSenderScreen> {
//   late GCodeSender _sender;
//   bool _isPaused = false;
//   double _progress = 0;
//   String _status = 'Hazırlanıyor...';
//   final List<String> _logMessages = [];
//   final List<String> _activeCommands = [];
//   final ScrollController _logScrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _initializeSender();
//   }

//   void _initializeSender() {
//     _sender = GCodeSender(
//       connection: widget.connection,
//       gcodeLines: widget.gcodeLines,
//       windowSize: 4,
//       onProgressUpdate: (progress, status) {
//         setState(() {
//           _progress = progress;
//           _status = status;
//         });
//       },
//       onLog: _addLogMessage,
//       onActiveCommandsUpdate: (commands) {
//         setState(() {
//           _activeCommands.clear();
//           _activeCommands.addAll(commands);
//         });
//       },
//     );
//     _startSending();
//   }

//   Future<void> _startSending() async {
//     try {
//       _sender.start();
//     } catch (e) {
//       _addLogMessage('Hata: $e');
//     }
//   }

//   void _addLogMessage(String message) {
//     setState(() {
//       _logMessages.add('${DateTime.now().toString().substring(11, 19)}: $message');
//     });
//     // Log listesini otomatik kaydır
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (_logScrollController.hasClients) {
//         _logScrollController.animateTo(
//           _logScrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 200),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('GCode Gönderimi'),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () {
//             // Geri dönmeden önce kullanıcıya sor
//             showDialog(
//               context: context,
//               builder: (context) => AlertDialog(
//                 title: Text('Gönderimi Sonlandır'),
//                 content: Text('GCode gönderimi devam ediyor. Çıkmak istediğinize emin misiniz?'),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: Text('Hayır'),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       _sender.stop();
//                       Navigator.pop(context); // Dialog'u kapat
//                       Navigator.pop(context); // Ekranı kapat
//                     },
//                     child: Text('Evet'),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//       body: Column(
//         children: [
//           // İlerleme Göstergesi
//           Padding(
//             padding: EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 LinearProgressIndicator(
//                   value: _progress,
//                   backgroundColor: Colors.grey[200],
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     _isPaused ? Colors.orange : Colors.blue,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   '${(_progress * 100).toStringAsFixed(1)}%',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   _status,
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),

//           // Kontrol Butonları
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton.icon(
//                 icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
//                 label: Text(_isPaused ? 'Devam Et' : 'Duraklat'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _isPaused ? Colors.green : Colors.orange,
//                   foregroundColor: Colors.white,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _isPaused = !_isPaused;
//                     if (_isPaused) {
//                       _sender.pause();
//                     } else {
//                       _sender.resume();
//                     }
//                   });
//                 },
//               ),
//               ElevatedButton.icon(
//                 icon: Icon(Icons.stop),
//                 label: Text('Durdur'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                 ),
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: Text('Gönderimi Durdur'),
//                       content: Text('GCode gönderimini durdurmak istediğinize emin misiniz?'),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: Text('Hayır'),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             _sender.stop();
//                             Navigator.pop(context);
//                           },
//                           child: Text('Evet'),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),

//           // Log ve Aktif Komutlar Bölümü
//           Expanded(
//             child: Container(
//               margin: EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Aktif Komutlar Bölümü
//                   Container(
//                     height: 150,
//                     padding: EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.black87,
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(8),
//                         topRight: Radius.circular(8),
//                       ),
//                       border: Border.all(color: Colors.blue, width: 1),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Aktif Komutlar:',
//                               style: TextStyle(
//                                 color: Colors.blue,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               'Buffer Durumu',
//                               style: TextStyle(
//                                 color: Colors.orange,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                         Expanded(
//                           child: ListView.builder(
//                             itemCount: _activeCommands.length,
//                             itemBuilder: (context, index) {
//                               final command = _activeCommands[index];
//                               return Padding(
//                                 padding: EdgeInsets.symmetric(vertical: 4),
//                                 child: Text(
//                                   command,
//                                   style: TextStyle(
//                                     color: command.contains('⌛') ? Colors.yellow : Colors.green,
//                                     fontFamily: 'Courier',
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   SizedBox(height: 1), // Ayırıcı boşluk

//                   // Log Mesajları Bölümü
//                   Expanded(
//                     child: Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.black87,
//                         borderRadius: BorderRadius.only(
//                           bottomLeft: Radius.circular(8),
//                           bottomRight: Radius.circular(8),
//                         ),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Log Mesajları:',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Expanded(
//                             child: ListView.builder(
//                               controller: _logScrollController,
//                               itemCount: _logMessages.length,
//                               itemBuilder: (context, index) {
//                                 final message = _logMessages[index];
//                                 Color messageColor = Colors.white;

//                                 // Mesaj türüne göre renklendirme
//                                 if (message.contains('❌')) {
//                                   messageColor = Colors.red;
//                                 } else if (message.contains('✅')) {
//                                   messageColor = Colors.green;
//                                 } else if (message.contains('📤')) {
//                                   messageColor = Colors.yellow;
//                                 } else if (message.contains('📥')) {
//                                   messageColor = Colors.blue;
//                                 } else {
//                                   messageColor = Colors.white;
//                                 }

//                                 return Text(
//                                   message,
//                                   style: TextStyle(
//                                     color: messageColor,
//                                     fontFamily: 'Courier',
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _sender.dispose();
//     _logScrollController.dispose();
//     super.dispose();
//   }
// }
