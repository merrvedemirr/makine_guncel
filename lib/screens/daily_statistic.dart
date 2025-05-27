import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/viewmodel/statistics_provider.dart';
import 'package:makine/widgets/custom_chart.dart';
import 'package:makine/widgets/custom_row.dart';
import 'package:makine/widgets/date_and_adet_list.dart';
import 'package:makine/widgets/statistic_detail_dialog.dart';

class DailyStatistic extends ConsumerWidget {
  final String userId;
  const DailyStatistic({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider(userId));

    return statisticsAsync.when(
      data: (data) {
        final dailyList = data?.daily ?? [];
        // Tüm günleri sırala (en eski -> en yeni)
        final allDates = dailyList.map((e) => e.gun).whereType<String>().toList();
        allDates.sort();
        // Son 7 günü al
        final last7Dates = allDates.length > 7 ? allDates.sublist(allDates.length - 7) : allDates;
        // Gün -> item map'i
        final Map<String, dynamic> dailyMap = {for (var item in dailyList) (item.gun ?? ''): item};
        // 7 elemanlı chartList oluştur
        final chartList = List.generate(7, (i) {
          String? date;
          if (last7Dates.length == 7) {
            date = last7Dates[i];
          } else {
            final diff = 7 - last7Dates.length;
            if (i < diff) {
              date = '';
            } else {
              date = last7Dates[i - diff];
            }
          }
          final item = dailyMap[date];
          return {
            'daily': date,
            'adet': item?.toplamKesimSayisi ?? '0',
            'detay': item?.detay,
            'model': item?.model,
          };
        });
        final reversedChartList = chartList.reversed.toList();

        return Padding(
          padding: const EdgeInsets.only(top: 35),
          child: Column(
            children: [
              CustomChart(
                chartList: reversedChartList,
                date: 'daily',
                adet: 'adet',
              ),
              CustomRow(context: context),
              DateAndAdetList(
                list: dailyList
                    .map((item) => {
                          'daily': item.gun ?? '',
                          'adet': item.toplamKesimSayisi,
                          'detay': item.detay,
                          'model': item.model,
                          'ana_kategori': item.anaKategori,
                          'alt_kategori': item.altKategori,
                          'toplam_kesim_sayisi': item.toplamKesimSayisi,
                        })
                    .toList(),
                date: 'daily',
                adet: 'adet',
                onTap: (item) {
                  showDialog(
                    context: context,
                    builder: (context) => StatisticDetailDialog(
                      anaKategori: item['ana_kategori'],
                      altKategori: item['alt_kategori'],
                      model: item['model'],
                      detay: item['detay'],
                      tarih: item['daily'],
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

// ];
