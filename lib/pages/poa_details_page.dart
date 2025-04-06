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
      appBar: UIComponents.buildDetailsAppBar(context, 'PoE Details'),
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
                        'Valid PoE!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("General Information"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Proof Type', proofType),
                    UIComponents.buildTableRow(
                        'Public Key Algorithm', publicKeyAlgorithm),
                    UIComponents.buildTableRow(
                        'Verification Key', publicKeyVerification),
                    UIComponents.buildTableRow(
                        'Transferable', transferable ? 'Yes' : 'No'),
                    UIComponents.buildTableRow(
                        'Timestamp Format', timestampFormat),
                    UIComponents.buildTableRow('Timestamp Time', timestampTime),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("GPS Data"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Latitude', gpsLat.toString()),
                    UIComponents.buildTableRow('Longitude', gpsLng.toString()),
                    UIComponents.buildTableRow('Altitude', gpsAlt.toString()),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Engagement Data"),
                  UIComponents.buildTable([
                    UIComponents.buildTableRow('Encoding', engagementEncoding),
                    UIComponents.buildTableRow('Data', engagementData),
                    UIComponents.buildTableRow('Decoded Data',
                        utf8.decode(base64Decode(engagementData))),
                  ]),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Sensitive Data"),
                  UIComponents.buildDataTable(sensitiveDataHashMap),
                  const SizedBox(height: 20),
                  UIComponents.buildSectionTitle("Other Data"),
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
