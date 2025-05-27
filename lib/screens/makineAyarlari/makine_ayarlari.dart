import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/screens/makineAyarlari/onePage.dart';
import 'package:makine/screens/makineAyarlari/twoPage.dart';

final currentPageProvider = StateProvider<int>((ref) => 0);

class MakineAyarlari extends ConsumerStatefulWidget {
  const MakineAyarlari({
    super.key,
    // ignore: non_constant_identifier_names
    required this.tur_id,
  });

  // ignore: non_constant_identifier_names
  final String tur_id;

  @override
  // ignore: library_private_types_in_public_api
  _MakineAyarlariState createState() => _MakineAyarlariState();
}

class _MakineAyarlariState extends ConsumerState<MakineAyarlari> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Makine Ayarları'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            currentPage == 0 ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        ref.read(currentPageProvider.notifier).state = 0;
                        _pageController.jumpToPage(0);
                      },
                      child: Text(
                        'Hazır Ayarlar',
                        style: TextStyle(
                          color: currentPage == 0 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    fit: FlexFit.tight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            currentPage == 1 ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        ref.read(currentPageProvider.notifier).state = 1;
                        _pageController.jumpToPage(1);
                      },
                      child: Text(
                        'Özel Ayarlar',
                        style: TextStyle(
                          color: currentPage == 1 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  ref.read(currentPageProvider.notifier).state = index;
                },
                children: [
                  // Birinci Sayfa
                  OnePage(
                    turId: widget.tur_id,
                  ),

                  // İkinci Sayfa
                  TwoPage(
                    turId: widget.tur_id,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
