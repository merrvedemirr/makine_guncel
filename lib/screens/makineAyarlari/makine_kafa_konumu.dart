import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/notifier/selection_category.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/makineAyarlari/model_yerlestirme.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/provider.dart';
import 'package:makine/screens/bluetooth/bluetooth_scanner_screen.dart';

class SecilenModelDetay extends ConsumerStatefulWidget {
  final List<EDetay> data; // ModelYerlestirme'ye geçecek data

  const SecilenModelDetay({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<SecilenModelDetay> createState() => _MakineKafaKonumuState();
}

class _MakineKafaKonumuState extends ConsumerState<SecilenModelDetay> {
  bool xAyna = false;
  bool yAyna = false;
  bool malzemeOtomatik = false;
  bool merkezliKes = false;

  @override
  void initState() {
    super.initState();

    //!Bu kısımda Bluetooth bağlantısı kontrol edilecek ve yoksa diyalog açılacak buton basılamaz olacak. Eğer varsa işlemlere devam edilebilir.
    _checkBluetooth();
  }

  void _checkBluetooth() {
    final controller = ref.read(bluetoothControllerProvider);
    final isConnected = controller.isConnected;

    // Provider durumunu güncelle
    ref.read(isBluetoothConnectedProvider.notifier).state = isConnected;

    if (!isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.bluetooth_disabled_outlined,
                  color: Colors.blue,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Uyarı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue),
                ),
              ],
            ),
            content: Text(
              'Bluetooth Bağlantısı Yok. Lütfen Bağlantınızı Kontrol Ediniz.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.blue), borderRadius: BorderRadius.circular(20))),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Kapat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showMessage(String message, bool isError) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(selectionProvider);
    final secimBaslik = '${selection.device ?? ''}/${selection.brand ?? ''}/${selection.model ?? ''}';

    // Provider'dan bluetooth bağlantı durumunu okuyalım
    final isBluetoothConnected = ref.watch(isBluetoothConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          //? Ana Ekrana Yönlendirme
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
              (route) => false,
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                secimBaslik,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(widget.data[0].detayAdi, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Container(
                  width: 220,
                  height: 350,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    widget.data[0].detayResmi,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    value: xAyna,
                    onChanged: (val) => setState(() => xAyna = val!),
                    title: Text("X ayna çevirme"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    value: yAyna,
                    onChanged: (val) => setState(() => yAyna = val!),
                    title: Text("Y ayna çevirme"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: ElevatedButton(
                      //!DEĞİŞTİRİLDİ
                      onPressed: isBluetoothConnected
                          ? () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ModelYerlestirme(data: widget.data),
                              ))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBluetoothConnected ? Colors.blue : Colors.grey,
                      ),
                      child: Text("Devam Et"),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ayar satırı için yardımcı widget
class AyarSatiri extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const AyarSatiri({required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
