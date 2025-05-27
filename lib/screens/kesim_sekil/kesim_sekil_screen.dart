import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/notifier/selection_category.dart';
import 'package:makine/notifier/services_notifier.dart';
import 'package:makine/screens/kesim_sekil/custom_page.dart';

class KesimSekilScreen extends ConsumerStatefulWidget {
  final String modle_id;
  const KesimSekilScreen({super.key, required this.modle_id});

  @override
  ConsumerState<KesimSekilScreen> createState() => _KesimSekilScreenState();
}

class _KesimSekilScreenState extends ConsumerState<KesimSekilScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final modelAsync = ref.watch(extraDetayProvider1(widget.modle_id));
    final selection = ref.watch(selectionProvider);
    final appBarTitle =
        '${selection.device ?? ''}/${selection.brand ?? ''}/${selection.model ?? ''}';

    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Text(
            appBarTitle,
          ),
          bottom: TabBar(
            isScrollable: true, // Sekmeleri kaydırılabilir yapar
            controller: _tabController,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.white, // Sekme göstergesi rengi
            labelColor: Colors.white,
            unselectedLabelColor:
                Colors.white60, // Seçili olmayan sekme metni rengi
            tabs: const [
              Tab(text: 'Cep Telefonu için Ön Ekran'),
              Tab(text: 'Cep Telefonu için Arka Film'),
              Tab(text: 'Kamera Koruyucu Film'),
              Tab(text: '360'),
            ],
          )),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: modelAsync.when(
          data: (detayList) {
            final groupedData = groupByTurId(detayList);
            return TabBarView(
              controller: _tabController,
              children: [
                CustomPage(data: groupedData[1] ?? []),
                CustomPage(data: groupedData[2] ?? []),
                CustomPage(data: groupedData[3] ?? []),
                CustomPage(data: groupedData[4] ?? []),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Veriyi tur_id'ye göre gruplama fonksiyonu
  Map<int, List<EDetay>> groupByTurId(List<EDetay> detayList) {
    return {
      for (var turId in detayList.map((e) => e.turId).toSet())
        turId: detayList.where((detay) => detay.turId == turId).toList()
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 sekme
  }
}
