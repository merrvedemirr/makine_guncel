import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/notifier/selection_category.dart';
import 'package:makine/notifier/services_notifier.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/kesim_sekil/kesim_sekil_screen.dart';
import 'package:makine/stringKeys/string_utils.dart';
import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
import 'package:makine/widgets/category_card.dart';
import 'package:makine/widgets/custom_search.dart';

class ModelScreen extends ConsumerStatefulWidget {
  final String id;
  const ModelScreen({super.key, required this.id});

  @override
  ConsumerState<ModelScreen> createState() => _ModelScreenState();
}

class _ModelScreenState extends ConsumerState<ModelScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    final modelAsync = ref.watch(modelProvider(widget.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ConstanceVariable.modelArama,
        ),
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
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: CustomSearch(
                message: ConstanceVariable.markaAra,
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
            ),
            Expanded(
              child: modelAsync.when(
                data: (modelList) {
                  final filteredList = modelList
                      .where((model) => model.modelAdi.toLowerCase().contains(searchText.toLowerCase()))
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
                      final model = filteredList[index];
                      return InkWell(
                        onTap: () {
                          // Seçilen markayı kaydet
                          ref.read(selectionProvider.notifier).selectModel(model.modelAdi);
                          // ModelScreen'e yönlendirme
                          pageRouteBuilder(
                              context,
                              KesimSekilScreen(
                                modle_id: "${model.id}",
                              ));
                        },
                        child: CategoryCard(
                          image: model.modelResmi,
                          title: model.modelAdi,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text('Hata: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
