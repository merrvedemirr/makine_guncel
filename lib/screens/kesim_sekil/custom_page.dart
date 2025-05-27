import 'package:flutter/material.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/screens/makineAyarlari/makine_kafa_konumu.dart';
import 'package:makine/screens/makineAyarlari/model_yerlestirme.dart';
import 'package:makine/widgets/category_card.dart';

class CustomPage extends StatelessWidget {
  final List<EDetay> data;

  const CustomPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final detay = data[index];
        return InkWell(
            onTap: () {
              print("Seçilen detay - ID: ${detay.id}, ModelId: ${detay.modelId}, DetayAdi: ${detay.detayAdi}");
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SecilenModelDetay(data: [detay]),
              ));
            },
            child: CategoryCard(image: detay.detayResmi, title: detay.detayAdi));
      },
    );
  }
}
//  MakineAyarlari(tur_id: "${detay.id}")
