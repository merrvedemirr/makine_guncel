// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:makine/controller/bluetooth_controller.dart';

// class BluetoothSenderScreen extends StatefulWidget {
//   final String deviceName;
//   final List<String> gcodeLines;
//   final int windowSize;
//   final BluetoothController controller;

//   const BluetoothSenderScreen({
//     super.key,
//     required this.deviceName,
//     required this.gcodeLines,
//     this.windowSize = 1,
//     required this.controller,
//   });

//   @override
//   State<BluetoothSenderScreen> createState() => _BluetoothSenderScreenState();
// }

// class _BluetoothSenderScreenState extends State<BluetoothSenderScreen> with WidgetsBindingObserver {
//   late final BluetoothController _controller;

//   Queue<String> _sendQueue = Queue();
//   int _inflight = 0;
//   int _pointer = 0;
//   bool _isComplete = false;
//   double _progress = 0.0;
//   bool _isSending = false;

//   // OK yanıtı sayacı
//   int _okResponseCount = 0;

//   final List<String> _sentCommands = [];
//   final List<String> _deviceResponses = [];
//   final ScrollController _sentScrollController = ScrollController();
//   final ScrollController _responseScrollController = ScrollController();

//   String _deviceBuffer = '';
//   StreamSubscription? _dataStreamSubscription;

//   // Ana sayfa için gönderilecek özel G-code
//   final String _homeGcode = "\$H"; // Ana sayfa komutu

//   @override
//   void initState() {
//     super.initState();
//     _controller = widget.controller;
//     _initializeQueues();
//     _listenForDeviceData();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   void _initializeQueues() {
//     _sendQueue.clear();
//     _pointer = 0;
//     _inflight = 0;
//     _okResponseCount = 0; // Sayacı sıfırla

//     for (var line in widget.gcodeLines) {
//       line = line.trim();
//       if (line.isNotEmpty) {
//         _sendQueue.add(line);
//       }
//     }
//   }

//   Future<void> _sendCommand(String line) async {
//     try {
//       _controller.connection!.output.add(Uint8List.fromList(utf8.encode('$line\r\n')));
//       await _controller.connection!.output.allSent;
//       _inflight++;
//       _sentCommands.add('📤 Gönderildi: $line');
//       _scrollToEnd(_sentScrollController);
//     } catch (e) {
//       _sentCommands.add('❌ Gönderim hatası: $e');
//       _scrollToEnd(_sentScrollController);
//     }
//   }

//   void _sendNextAvailable() {
//     if (!_isSending) return;

//     while (_inflight < widget.windowSize && _sendQueue.isNotEmpty) {
//       final line = _sendQueue.removeFirst();
//       _sendCommand(line);
//     }
//     _updateProgress();
//   }

//   // G-code gönderimini başlat
//   void _startSending() {
//     if (_isSending) return;

//     setState(() {
//       _isSending = true;
//       _okResponseCount = 0; // Gönderime başlarken sayacı sıfırla
//     });

//     _sendNextAvailable();
//   }

//   // Ana sayfa G-code'unu gönder
//   Future<void> _sendHomeCommand() async {
//     _deviceResponses.add('🏠 Ana sayfa komutu gönderiliyor...');
//     await _sendCommand(_homeGcode);
//     _scrollToEnd(_responseScrollController);
//   }

//   void _listenForDeviceData() {
//     final stream = _controller.getDataStream();
//     if (stream == null) return;

//     _dataStreamSubscription = stream.listen(
//       (data) {
//         _deviceBuffer += data;
//         if (_deviceBuffer.contains('\n')) {
//           var lines = _deviceBuffer.split('\n');
//           _deviceBuffer = lines.removeLast();

//           for (var line in lines) {
//             line = line.trim();
//             if (line.isNotEmpty) {
//               _deviceResponses.add('📥 Alındı: $line');

//               if (line.toLowerCase().contains('ok')) {
//                 // OK yanıtı sayacını artır
//                 setState(() {
//                   _okResponseCount++;
//                 });

//                 // OK sayacını mesaja ekle
//                 _deviceResponses.add('📥 Alındı: $line (OK Sayısı: $_okResponseCount)');

//                 _inflight = _inflight > 0 ? _inflight - 1 : 0;
//                 _sendNextAvailable();
//               } else {
//                 // Diğer yanıtlar için normal mesaj
//                 _deviceResponses.add('📥 Alındı: $line');
//               }
//             }
//           }
//           _scrollToEnd(_responseScrollController);

//           if (_isSending && _sendQueue.isEmpty && _inflight == 0) {
//             setState(() {
//               _isComplete = true;
//               _progress = 1.0;
//               _isSending = false;
//             });
//           }
//         }
//       },
//       onError: (error) {
//         _deviceResponses.add('❌ Veri akışı hatası: $error');
//         _scrollToEnd(_responseScrollController);
//       },
//       onDone: () {
//         _deviceResponses.add('⚡ Bağlantı kapandı');
//         _scrollToEnd(_responseScrollController);
//       },
//     );
//   }

//   void _updateProgress() {
//     setState(() {
//       _progress = (widget.gcodeLines.length - _sendQueue.length) / widget.gcodeLines.length;
//     });
//   }

//   void _scrollToEnd(ScrollController controller) {
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (controller.hasClients) {
//         controller.animateTo(
//           controller.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _dataStreamSubscription?.cancel();
//     _sentScrollController.dispose();
//     _responseScrollController.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     _controller.disconnect();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
//       _controller.disconnect();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('GCode Gönderimi: ${widget.deviceName}'),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _sendHomeCommand,
//         backgroundColor: Colors.blue,
//         child: const Icon(Icons.home),
//         tooltip: 'Ana Sayfa Komutu Gönder',
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             LinearProgressIndicator(
//               value: _progress,
//               minHeight: 10,
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 if (!_isSending && !_isComplete)
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: _startSending,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                       ),
//                       child: const Text(
//                         'G-code Gönder',
//                         style: TextStyle(fontSize: 16, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 const SizedBox(width: 10),
//                 // OK sayacını gösteren bilgi kartı
//                 Container(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.blue.shade300),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.check_circle, color: Colors.blue),
//                       const SizedBox(width: 8),
//                       Text(
//                         'OK Sayısı: $_okResponseCount',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           color: Colors.blue,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             if (_isComplete)
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 8.0),
//                 child: Text(
//                   '✅ Gönderim tamamlandı!',
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: _buildLogSection('Gönderilen Komutlar', _sentCommands, _sentScrollController),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: _buildLogSection('Cihazdan Gelen Yanıtlar', _deviceResponses, _responseScrollController),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLogSection(String title, List<String> messages, ScrollController controller) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.black87,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               title,
//               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//           ),
//           const Divider(color: Colors.white24),
//           Expanded(
//             child: ListView.builder(
//               controller: controller,
//               padding: const EdgeInsets.all(8),
//               itemCount: messages.length,
//               itemBuilder: (context, index) => Text(
//                 messages[index],
//                 style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
