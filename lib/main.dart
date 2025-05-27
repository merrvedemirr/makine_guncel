import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:makine/screens/gcode_nc_converter.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/login.dart';
import 'package:makine/viewmodel/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Yalnızca dikey yönlendirmeyi tercih et
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Sadece dikey mod (normal)
    DeviceOrientation.portraitDown, // Dikey mod ters çevrilmiş
  ]).then((_) {
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      home: const CheckAuthScreen(),
      routes: {
        '/gcode_converter': (context) => const GCodeNCConverter(),
      },
    );
  }
}

class CheckAuthScreen extends ConsumerStatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  ConsumerState<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends ConsumerState<CheckAuthScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? makineId = prefs.getString('makineId');
    final int? kontor = prefs.getInt('kontor');

    if (isLoggedIn && makineId != null && kontor != null) {
      // Uygulama açılışında bir kez otomatik Bluetooth bağlantısı yap
      await _autoConnectBluetooth();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  Future<void> _autoConnectBluetooth() async {
    try {
      // Eğer zaten bir cihaz bağlıysa (state dolu ise) işlem yapma
      if (ref.read(connectedBluetoothDeviceProvider) != null) {
        return;
      }

      final controller = ref.read(bluetoothControllerProvider);

      // İzinleri kontrol et
      bool permissionsGranted = await controller.checkAndRequestPermissions();
      if (!permissionsGranted) {
        print('Bluetooth izinleri reddedildi.');
        return;
      }

      // Bluetooth'u etkinleştir
      bool bluetoothEnabled = await controller.enableBluetooth();
      if (!bluetoothEnabled) {
        print('Bluetooth etkinleştirilemedi.');
        return;
      }

      // Kayıtlı cihaz var mı kontrol et
      final prefs = await SharedPreferences.getInstance();
      final lastAddress = prefs.getString('lastConnectedDeviceAddress');

      if (lastAddress == null) {
        print('Önceden bağlanılmış cihaz bulunamadı.');
        return;
      }

      // Doğrudan adrese bağlan
      bool connected = await controller.connectToDeviceByAddress(lastAddress);

      // Bağlantı başarılıysa state provider'ı güncelle
      if (connected) {
        final connectedDevice = controller.selectedDevice;
        if (connectedDevice != null) {
          ref.read(connectedBluetoothDeviceProvider.notifier).state = connectedDevice;
          print('Otomatik bağlantı başarılı: ${connectedDevice.name}');
        }
      }
    } catch (e) {
      print('Otomatik Bluetooth bağlantısı hatası: $e');
    }
  }
}

// class DraggableImageWithinContainer extends StatefulWidget {
//   const DraggableImageWithinContainer({super.key});

//   @override
//   _DraggableImageWithinContainerState createState() => _DraggableImageWithinContainerState();
// }

// class _DraggableImageWithinContainerState extends State<DraggableImageWithinContainer> {
//   // Resmin başlangıç konumu
//   Offset _imagePosition = Offset(50, 50);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Draggable Image in Container'),
//       ),
//       body: Center(
//         child: Container(
//           width: 300,
//           height: 300,
//           color: Colors.grey.shade300, // Container arka planı
//           child: Stack(
//             children: [
//               // Sürüklenebilir resim
//               Positioned(
//                 left: _imagePosition.dx,
//                 top: _imagePosition.dy,
//                 child: GestureDetector(
//                   onPanUpdate: (details) {
//                     setState(() {
//                       // Yeni pozisyonu hesapla
//                       double newX = _imagePosition.dx + details.delta.dx;
//                       double newY = _imagePosition.dy + details.delta.dy;

//                       // Sınır kontrolü
//                       if (newX < 0) newX = 0; // Sol sınır
//                       if (newY < 0) newY = 0; // Üst sınır
//                       if (newX > 300 - 100) newX = 300 - 100; // Sağ sınır
//                       if (newY > 300 - 100) newY = 300 - 100; // Alt sınır

//                       _imagePosition = Offset(newX, newY);
//                     });
//                   },
//                   child: Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       image: DecorationImage(
//                         image: AssetImage('assets/images/qrCode.png'), // Resminiz
//                         fit: BoxFit.cover,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
