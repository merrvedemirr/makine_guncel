import 'package:flutter/material.dart';

class StatisticDetailDialog extends StatelessWidget {
  final String? anaKategori;
  final String? altKategori;
  final String? model;
  final String? detay;
  final String? tarih;
  final String? kesimSayisi;

  const StatisticDetailDialog({
    super.key,
    this.anaKategori,
    this.altKategori,
    this.model,
    this.detay,
    this.tarih,
    this.kesimSayisi,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Ürün Detayları',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Column(
                    children: [
                      _buildDetailRow('Ana Kategori', anaKategori),
                      _buildDetailRow('Alt Kategori', altKategori),
                      _buildDetailRow('Model', model),
                      _buildDetailRow('Detay', detay),
                      if (tarih != null) _buildDetailRow('Tarih', tarih),
                      _buildDetailRow('Kesim Sayısı', kesimSayisi),
                    ],
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'TAMAM',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
