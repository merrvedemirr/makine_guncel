import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/notifier/selection_category.dart';
import 'package:makine/notifier/services_notifier.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/model_screen.dart';
import 'package:makine/stringKeys/string_utils.dart';
import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
import 'package:makine/widgets/category_card.dart';
import 'package:makine/widgets/custom_search.dart';

class MarkaScreen extends ConsumerStatefulWidget {
  final String modelId;
  const MarkaScreen({super.key, required this.modelId});

  @override
  ConsumerState<MarkaScreen> createState() => _MarkaScreenState();
}

class _MarkaScreenState extends ConsumerState<MarkaScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    // API'den gelen marka verisini izliyoruz
    final markaAsync = ref.watch(markaProvider(widget.modelId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ConstanceVariable.markaArama,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            tooltip: 'Ana Sayfa',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: CustomSearch(
                message: 'Marka Ara',
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
            ),
            Expanded(
              child: markaAsync.when(
                data: (markaList) {
                  final filteredList = markaList
                      .where((marka) => marka.markaAdi.toLowerCase().contains(searchText.toLowerCase()))
                      .toList();
                  // GridView ile markaları görüntüle
                  return GridView.builder(
                    itemCount: filteredList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final marka = filteredList[index];
                      return InkWell(
                        onTap: () {
                          // Seçilen markayı kaydet
                          ref.read(selectionProvider.notifier).selectBrand(marka.markaAdi);
                          // ModelScreen'e yönlendirme
                          pageRouteBuilder(
                              context,
                              ModelScreen(
                                id: "${marka.id}",
                              ));
                        },
                        child: CategoryCard(
                          image: marka.markaResmi,
                          title: marka.markaAdi,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('Hata: ${error.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
