import 'dart:convert';
import 'package:flutter/material.dart';

class PoADetailsPage extends StatelessWidget {
  final String proofType;
  final String publicKeyAlgorithm;
  final String publicKeyVerification;
  final bool transferable;
  final String timestampFormat;
  final String timestampTime;
  final double gpsLat;
  final double gpsLng;
  final double gpsAlt;
  final String engagementEncoding;
  final String engagementData;
  final Map<String, String> sensitiveDataHashMap;
  final Map<String, dynamic> otherDataHashMap;

  const PoADetailsPage(
      {super.key,
      required this.proofType,
      required this.publicKeyAlgorithm,
      required this.publicKeyVerification,
      required this.transferable,
      required this.timestampFormat,
      required this.timestampTime,
      required this.gpsLat,
      required this.gpsLng,
      required this.gpsAlt,
      required this.engagementEncoding,
      required this.engagementData,
      required this.sensitiveDataHashMap,
      required this.otherDataHashMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title:
            const Text('Dettagli PoE', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'PoE Valida!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Informazioni Generali"),
                  _buildTable([
                    _buildTableRow('Tipo di Prova', proofType),
                    _buildTableRow(
                        'Algoritmo Chiave Pubblica', publicKeyAlgorithm),
                    _buildTableRow('Chiave di Verifica', publicKeyVerification),
                    _buildTableRow('Trasferibile', transferable ? 'Sì' : 'No'),
                    _buildTableRow('Formato Timestamp', timestampFormat),
                    _buildTableRow('Orario Timestamp', timestampTime),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Dati GPS"),
                  _buildTable([
                    _buildTableRow('Latitudine', gpsLat.toString()),
                    _buildTableRow('Longitudine', gpsLng.toString()),
                    _buildTableRow('Altitudine', gpsAlt.toString()),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Dati di Engagement"),
                  _buildTable([
                    _buildTableRow('Codifica', engagementEncoding),
                    _buildTableRow('Dati', engagementData),
                    _buildTableRow('Dati Decodificati',
                        utf8.decode(base64Decode(engagementData))),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Dati Sensibili"),
                  _buildDataTable(sensitiveDataHashMap),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Altri Dati"),
                  _buildDataTable(otherDataHashMap),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// **Titolo della sezione con icona**
  Widget _buildTitle(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// **Titolo di una sezione**
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  /// **Tabella migliorata**
  Widget _buildTable(List<TableRow> rows) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: rows,
    );
  }

  Widget _buildDataTable(Map<String, dynamic> data) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
      border: TableBorder.all(color: Colors.grey.shade300),
      children: data.entries.map((entry) {
        return _buildTableRow(entry.key, entry.value.toString());
      }).toList(),
    );
  }

  /// **Singola riga della tabella**
  TableRow _buildTableRow(String key, String value) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(5),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
