import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class GCodeSender {
  final BluetoothConnection connection;
  final List<String> gcodeLines;
  final int windowSize;
  final int timeoutSeconds;

  int inflight = 0;
  int pointer = 0;
  Queue<String> sendQueue = Queue();
  bool isListening = false;
  String buffer = '';

  // Timeout için map
  final Map<int, DateTime> _sentCommands = {};

  // Yeniden deneme sayısı
  final Map<int, int> _retryCount = {};
  static const int MAX_RETRIES = 3;

  final Function(double progress, String status)? onProgressUpdate;
  final Function(String message)? onLog;
  final Function(List<String> activeCommands)? onActiveCommandsUpdate;

  Timer? _timeoutTimer;

  GCodeSender({
    required this.connection,
    required this.gcodeLines,
    this.windowSize = 4,
    this.timeoutSeconds = 30,
    this.onProgressUpdate,
    this.onLog,
    this.onActiveCommandsUpdate,
  });

  void start() {
    try {
      _log('GCode gönderimi başlatılıyor...');
      _initializeQueues();
      _listenForResponses();
      _startTimeoutCheck();
      _sendNextAvailable();
    } catch (e) {
      _log('Başlatma hatası: $e');
      // Hatayı yukarı ilet
      rethrow;
    }
  }

  void _initializeQueues() {
    sendQueue.clear();
    _sentCommands.clear();
    _retryCount.clear();
    pointer = 0;
    inflight = 0;

    // Geçerli komutları kuyruğa ekle
    for (var line in gcodeLines) {
      line = line.trim();
      if (line.isNotEmpty) {
        sendQueue.add(line);
      }
    }
    _log('${sendQueue.length} komut kuyruğa eklendi');
  }

  Future<void> _sendCommand(String line, int index) async {
    try {
      connection.output.add(Uint8List.fromList('$line\n'.codeUnits));
      await connection.output.allSent.timeout(Duration(seconds: 5), onTimeout: () {
        _log('Gönderim zaman aşımı[$index]: $line');
        throw TimeoutException('Komut gönderimi zaman aşımına uğradı');
      });
      ;
      _sentCommands[index] = DateTime.now();
      inflight++;
      _log('📤 Gönderildi[$index]: $line');
      _updateActiveCommands(); // Yeni komut gönderildiğinde güncelle
    } catch (e) {
      _log('❌ Gönderim hatası[$index]: $e');
      _handleError(index, 'Gönderim hatası: $e');
    }
  }

  void _sendNextAvailable() {
    while (inflight < windowSize && pointer < gcodeLines.length) {
      final line = gcodeLines[pointer].trim();
      if (line.isNotEmpty) {
        _sendCommand(line, pointer);
        pointer++;
      }
      _updateProgress();
    }
  }

  void _handleDeviceResponse(String line) {
    _log("📥 Cihazdan gelen: $line");

    if (line == 'ok') {
      inflight = inflight > 0 ? inflight - 1 : 0;

      if (_sentCommands.isNotEmpty) {
        final oldestIndex = _sentCommands.keys.reduce((a, b) => a < b ? a : b);
        final command = gcodeLines[oldestIndex];
        _sentCommands.remove(oldestIndex);
        _retryCount.remove(oldestIndex);
        _log('✅ Onaylandı[$oldestIndex]: $command');
      }

      _updateActiveCommands();
      _sendNextAvailable();
    } else if (line.startsWith('error') || line.contains('alarm') || line.contains('MSG:ERR')) {
      _log('⚠️ Hata yanıtı: $line');
      // isteğe bağlı olarak error durumunu da ele al
    }

    _updateActiveCommands();
  }

  void _listenForResponses() {
    if (isListening) return;
    isListening = true;

    connection.input!.listen(
      (Uint8List data) {
        buffer += String.fromCharCodes(data);
        while (buffer.contains('\n')) {
          int index = buffer.indexOf('\n');
          String line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          _handleDeviceResponse(line);
        }
      },
      onError: (error) {
        _log('Bağlantı hatası: $error');
        stop();
      },
      onDone: () {
        _log('Bağlantı kapandı');
        stop();
      },
    );
  }

  void _processBuffer() {
    // OK yanıtlarını işle
    while (buffer.contains('ok')) {
      inflight = inflight > 0 ? inflight - 1 : 0;

      if (_sentCommands.isNotEmpty) {
        final oldestIndex = _sentCommands.keys.reduce((a, b) => a < b ? a : b);
        final command = gcodeLines[oldestIndex];
        _sentCommands.remove(oldestIndex);
        _retryCount.remove(oldestIndex);
        _log('✅ Onaylandı[$oldestIndex]: $command');
      }

      buffer = buffer.substring(buffer.indexOf('ok') + 2);
      _updateActiveCommands(); // Buffer değiştiğinde güncelle
      _sendNextAvailable();
    }

    // Her buffer değişiminde aktif komutları güncelle
    _updateActiveCommands();
  }

  void _startTimeoutCheck() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();

      _sentCommands.forEach((index, sentTime) {
        if (now.difference(sentTime).inSeconds > timeoutSeconds) {
          _handleError(index, 'Timeout');
        }
      });
    });
  }

  void _handleError(int commandIndex, String error) {
    _retryCount[commandIndex] = (_retryCount[commandIndex] ?? 0) + 1;

    if (_retryCount[commandIndex]! <= MAX_RETRIES) {
      _log('Yeniden deneniyor[$commandIndex] (${_retryCount[commandIndex]}/$MAX_RETRIES)');
      _sendCommand(gcodeLines[commandIndex], commandIndex);
    } else {
      _log('Maksimum yeniden deneme sayısına ulaşıldı[$commandIndex]');
      stop();
    }
  }

  void pause() {
    isListening = false;
    _timeoutTimer?.cancel();
    _log('Gönderim duraklatıldı');
    onProgressUpdate?.call(_calculateProgress(), 'Duraklatıldı');
  }

  void resume() {
    if (!isListening) {
      isListening = true;
      _startTimeoutCheck();
      _sendNextAvailable();
      _log('Gönderim devam ediyor');
      onProgressUpdate?.call(_calculateProgress(), 'Devam ediyor');
    }
  }

  void stop() {
    isListening = false;
    _timeoutTimer?.cancel();
    inflight = 0;
    pointer = 0;
    sendQueue.clear();
    _sentCommands.clear();
    _retryCount.clear();
    _log('Gönderim durduruldu');
    onProgressUpdate?.call(0, 'Durduruldu');
  }

  double _calculateProgress() {
    return gcodeLines.isEmpty ? 0.0 : pointer / gcodeLines.length;
  }

  void _updateProgress() {
    onProgressUpdate?.call(_calculateProgress(), _getStatus());
  }

  String _getStatus() {
    if (!isListening) return 'Durdu';
    if (pointer >= gcodeLines.length && inflight == 0) return 'Tamamlandı';
    return 'Gönderiliyor ($pointer/${gcodeLines.length})';
  }

  void _log(String message) {
    onLog?.call('${DateTime.now().toString().substring(11, 19)}: $message');
  }

  Future<void> dispose() async {
    _timeoutTimer?.cancel();
    stop();
    try {
      // Bağlantı kapatma işlemine timeout ekle
      await connection.close().timeout(
        Duration(seconds: 2),
        onTimeout: () {
          _log('Bağlantı kapatma zaman aşımı');
          // Zorla dispose et
        },
      );
    } catch (e) {
      _log('Bağlantı kapatma hatası: $e');
    }
  }

  void _updateActiveCommands() {
    List<String> commands = [];

    // Buffer durumunu ekle
    if (buffer.isNotEmpty) {
      commands.add("📥 Buffer içeriği: $buffer");
    }

    // Aktif komutları ekle
    _sentCommands.forEach((index, time) {
      final command = gcodeLines[index];
      final waitingTime = DateTime.now().difference(time).inSeconds;
      commands.add("📤 [$index] $command\n    ⌛ OK yanıtı bekleniyor... (${waitingTime}s)");
    });

    onActiveCommandsUpdate?.call(commands);
  }
}
