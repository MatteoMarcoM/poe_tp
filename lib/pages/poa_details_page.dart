import 'dart:convert';
import 'package:flutter/material.dart';
import '../utility/ui_components.dart';

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
      appBar: UIComponents.buildDetailsAppBar(context, 'Dettagli PoE'),
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
                  UIComponents.buildSectionTitle("Informazioni Generali"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Tipo di Prova', proofType),
                    UIComponents.buildTableRow(
                        'Algoritmo Chiave Pubblica', publicKeyAlgorithm),
                    UIComponents.buildTableRow(
                        'Chiave di Verifica', publicKeyVerification),
                    UIComponents.buildTableRow(
                        'Trasferibile', transferable ? 'Sì' : 'No'),
                    UIComponents.buildTableRow(
                        'Formato Timestamp', timestampFormat),
                    UIComponents.buildTableRow(
                        'Orario Timestamp', timestampTime),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Dati GPS"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Latitudine', gpsLat.toString()),
                    UIComponents.buildTableRow(
                        'Longitudine', gpsLng.toString()),
                    UIComponents.buildTableRow('Altitudine', gpsAlt.toString()),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Dati di Engagement"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Codifica', engagementEncoding),
                    UIComponents.buildTableRow('Dati', engagementData),
                    UIComponents.buildTableRow('Dati Decodificati',
                        utf8.decode(base64Decode(engagementData))),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Dati Sensibili"),
                  UIComponents.buildDataTable(sensitiveDataHashMap),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Altri Dati"),
                  UIComponents.buildDataTable(otherDataHashMap),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
