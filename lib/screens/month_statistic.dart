import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/viewmodel/statistics_provider.dart';
import 'package:makine/widgets/custom_chart.dart';
import 'package:makine/widgets/date_and_adet_list.dart';
import 'package:makine/widgets/statistic_detail_dialog.dart';

class MonthStatistic extends ConsumerWidget {
  final String userId;
  const MonthStatistic({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider(userId));

    return statisticsAsync.when(
      data: (data) {
        final monthlyList = data?.monthly ?? [];
        // Tüm ayları sırala (en eski -> en yeni)
        final allMonths = monthlyList.map((e) => e.ay).whereType<String>().toList();
        allMonths.sort();
        // Son 7 ayı al
        final last7Months = allMonths.length > 7 ? allMonths.sublist(allMonths.length - 7) : allMonths;
        // Ay -> item map'i
        final Map<String, dynamic> monthlyMap = {for (var item in monthlyList) (item.ay ?? ''): item};
        // 7 elemanlı chartList oluştur
        final chartList = List.generate(7, (i) {
          String? month;
          if (last7Months.length == 7) {
            month = last7Months[i];
          } else {
            final diff = 7 - last7Months.length;
            if (i < diff) {
              month = '';
            } else {
              month = last7Months[i - diff];
            }
          }
          final item = monthlyMap[month];
          return {
            'month': month ?? '',
            'adet': item?.toplamKesimSayisi ?? '0',
            'detay': item?.detay,
            'model': item?.model,
            'toplam_kesim_sayisi': item?.toplamKesimSayisi,
          };
        });

        final reversedChartList = chartList.reversed.toList();

        return Padding(
          padding: const EdgeInsets.only(top: 35),
          child: Column(
            children: [
              CustomChart(
                chartList: reversedChartList,
                date: 'month',
                adet: 'adet',
              ),
              DateAndAdetList(
                list: monthlyList
                    .map((item) => {
                          'month': item.ay ?? '',
                          'adet': item.toplamKesimSayisi,
                          'detay': item.detay,
                          'model': item.model,
                          'ana_kategori': item.anaKategori,
                          'alt_kategori': item.altKategori,
                          'toplam_kesim_sayisi': item.toplamKesimSayisi,
                        })
                    .toList(),
                date: 'month',
                adet: 'adet',
                onTap: (item) {
                  showDialog(
                    context: context,
                    builder: (context) => StatisticDetailDialog(
                      anaKategori: item['ana_kategori'],
                      altKategori: item['alt_kategori'],
                      model: item['model'],
                      detay: item['detay'],
                      tarih: item['month'],
                      kesimSayisi: item['toplam_kesim_sayisi']?.toString(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
    );
  }
}
