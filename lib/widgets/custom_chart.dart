import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CustomChart extends StatefulWidget {
  final List<Map<String, dynamic>> chartList;
  final String date;
  final String adet;

  const CustomChart({
    super.key,
    required this.chartList,
    required this.date,
    required this.adet,
  });

  @override
  State<CustomChart> createState() => _CustomChartState();
}

class _CustomChartState extends State<CustomChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Son 5 günün verisi
    final lastFive =
        widget.chartList.length > 7 ? widget.chartList.sublist(widget.chartList.length - 7) : widget.chartList;

    return AspectRatio(
      aspectRatio: 1.3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final date = lastFive[group.x.toInt()][widget.date] ?? '';
                  final value = rod.toY - 1;
                  return BarTooltipItem(
                    '$date\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: value.toString(),
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
              touchCallback: (event, response) {
                setState(() {
                  if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                    touchedIndex = -1;
                    return;
                  }
                  touchedIndex = response.spot!.touchedBarGroupIndex;
                });
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final label = lastFive[value.toInt()][widget.date] ?? '';
                    return Transform.rotate(
                      angle: -0.5, // Yaklaşık -30 derece

                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(label, style: TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(lastFive.length, (i) {
              final value = double.tryParse(lastFive[i][widget.adet]?.toString() ?? '0') ?? 0;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: touchedIndex == i ? value + 1 : value,
                    width: 22,
                    borderSide: touchedIndex == i ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
                    gradient: LinearGradient(
                      colors: touchedIndex == i
                          ? [Colors.green, Colors.lightGreenAccent, Colors.white]
                          : [
                              const Color.fromARGB(255, 31, 72, 105),
                              Colors.lightBlueAccent,
                              Colors.lightBlueAccent.shade100
                            ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: lastFive
                              .map((e) => double.tryParse(e[widget.adet]?.toString() ?? '0') ?? 0)
                              .reduce((a, b) => a > b ? a : b) +
                          5,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                showingTooltipIndicators: touchedIndex == i ? [0] : [],
              );
            }),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }
}

// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:makine/stringKeys/string_utils.dart';

// class CustomChart extends StatelessWidget {
//   const CustomChart({
//     super.key,
//     required this.chartList,
//     required this.date,
//     required this.adet,
//   });

//   final List<Map<String, dynamic>> chartList;
//   final String date;
//   final String adet;

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: SizedBox(
//           width: chartList.length * 120.0, // Tarih sayısına göre genişlik ayarlandı
//           child: LineChart(
//             LineChartData(
//               minX: 0,
//               maxX: chartList.length - 0.5,
//               minY: 0,
//               maxY: chartList.length + 30, // Y ekseninde boşluk bırakmak için artırıldı
//               lineTouchData: LineTouchData(
//                 enabled: true,
//                 touchTooltipData: LineTouchTooltipData(
//                   getTooltipItems: (touchedSpots) {
//                     return touchedSpots.map((touchedSpot) {
//                       final spot = touchedSpot;
//                       return LineTooltipItem(
//                         '${chartList[spot.x.toInt()][date]}\n${spot.y.toString()}',
//                         const TextStyle(color: Colors.white),
//                       );
//                     }).toList();
//                   },
//                 ),
//               ),
//               borderData: FlBorderData(
//                 show: true,
//                 border: Border.all(color: Colors.black12),
//               ),
//               gridData: const FlGridData(
//                 show: true,
//                 drawVerticalLine: true,
//                 drawHorizontalLine: true,
//                 horizontalInterval: 5,
//                 verticalInterval: 1,
//               ),
//               titlesData: FlTitlesData(
//                 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 leftTitles: const AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 50, // Sol tarafta daha fazla yer bırakıldı
//                     interval: 5, // Her 5 birimde bir gösterim
//                   ),
//                 ),
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     interval: 1, // X ekseni başlıkları için aralık ayarı
//                     getTitlesWidget: (value, meta) {
//                       int index = value.toInt();
//                       // Eğer index geçerli bir aralıkta değilse, boş döndür.
//                       if (index >= 0 && index < chartList.length) {
//                         return Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: Text(chartList[index][date] ?? ""),
//                         );
//                       }
//                       return const Text('');
//                     },
//                     reservedSize: 60, // Alt tarafta daha fazla boşluk bırak
//                   ),
//                 ),
//               ),
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: List.generate(
//                     chartList.length,
//                     (index) => FlSpot(index.toDouble(), double.parse(chartList[index][adet]!)),
//                   ),
//                   isCurved: true, // Grafiği yumuşatmak için
//                   color: Colors.blue, // Çizgi rengi
//                   belowBarData: BarAreaData(
//                     show: true,
//                     gradient: const LinearGradient(
//                       colors: [
//                         ConstanceVariable.bottomBarSelectedColor,
//                         Color.fromARGB(255, 146, 206, 255),
//                         Color.fromARGB(255, 221, 236, 249),
//                       ],
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                     ), // Çizginin altındaki alanın rengi
//                   ),
//                   dotData: const FlDotData(
//                     show: true, // Noktaları göstermek için
//                   ),
//                   showingIndicators: List.generate(chartList.length, (index) => index),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
