import 'package:flutter/material.dart';

class DateAndAdetList extends StatelessWidget {
  const DateAndAdetList({
    super.key,
    required this.list,
    required this.date,
    required this.adet,
    this.onTap,
  });

  final List<Map<String, dynamic>> list;
  final String date;
  final String adet;
  final void Function(Map<String, dynamic> item)? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Card(
          color: Colors.white,
          elevation: 7,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final item = list[index];
                return ListTile(
                  title: Text(item[date] ?? ""),
                  trailing: Text(item[adet] ?? ""),
                  onTap: onTap != null ? () => onTap!(item) : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
