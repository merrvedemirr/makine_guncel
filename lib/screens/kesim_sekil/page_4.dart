// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:machine_software/widgets/category_card.dart';

// class Page4 extends ConsumerStatefulWidget {
//   const Page4({super.key});

//   @override
//   ConsumerState<Page4> createState() => _Page4State();
// }

// class _Page4State extends ConsumerState<Page4> {
//   final List<Map<String, String>> categories = [
//     {'title': '16 360 filmi', 'image': 'assets/images/phone.png'},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: GridView.builder(
//         itemCount: categories.length,
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//         ),
//         itemBuilder: (context, index) {
//           final category = categories[index];
//           return InkWell(
//             onTap: () {
//               //todo: Burada veri girecek
//             },
//             child: CategoryCard(
//               image: category['image']!,
//               title: category['title']!,
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
