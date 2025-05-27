import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/notifier/selection_category.dart';
import 'package:makine/notifier/services_notifier.dart';
import 'package:makine/screens/marka_screen.dart';
import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
import 'package:makine/widgets/category_card.dart';
import 'package:makine/widgets/custom_search.dart';

class SiniflandirmaScreen extends ConsumerStatefulWidget {
  const SiniflandirmaScreen({super.key});

  @override
  ConsumerState<SiniflandirmaScreen> createState() => _SiniflandirmaScreenState();
}

class _SiniflandirmaScreenState extends ConsumerState<SiniflandirmaScreen> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    final urunAsync = ref.watch(urunProvider);

    return Column(
      children: [
        CustomSearch(
          message: 'Ürün Ara',
          onChanged: (value) {
            setState(() {
              searchText = value;
            });
          },
        ),
        SizedBox(
          height: 10,
        ),
        Expanded(
          child: urunAsync.when(
            data: (urunList) {
              final filteredList = urunList
                  .where((product) => product.urunAdi.toLowerCase().contains(searchText.toLowerCase()))
                  .toList();
              return GridView.builder(
                itemCount: filteredList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final product = filteredList[index];
                  return InkWell(
                    onTap: () {
                      // Seçilen ürün başlığını sağlayıcıya yaz
                      ref.read(selectionProvider.notifier).selectDevice(product.urunAdi);
                      pageRouteBuilder(
                          context,
                          MarkaScreen(
                            modelId: product.id,
                          ));
                    },
                    child: CategoryCard(
                      image: product.urunResmi,
                      title: product.urunAdi,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Bir Hata Oluştu. Lütfen bağlantınızı kontrol edin'),
            ),
          ),
        ),
      ],
    );
  }
}
