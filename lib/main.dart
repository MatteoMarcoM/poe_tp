import 'dart:convert';
import 'package:flutter/material.dart';
import '../utility/websocket_service.dart';
import '../utility/crypto_helper.dart';
import '../utility/poa_parser.dart';
import '../utility/common_widgets.dart';
import '../utility/ui_components.dart';
import '../pages/poa_details_page.dart';
import 'package:pointycastle/pointycastle.dart' as pc;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoE TP',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebSocketPage(),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key});

  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  final List<String> _messages = [];
  final String _peerId = "poe_tp";
  final String _targetPeer = "poe_client";
  String? _challenge;
  Map<String, dynamic>? _receivedJson;
  String _poEToShow = "";
  late WebSocketService _webSocketService;
  pc.RSAPublicKey? _verificationKey;

  @override
  void initState() {
    super.initState();
    _webSocketService = WebSocketService(
      peerId: _peerId,
      onMessage: _handleMessage,
    );
  }

  void _sendMessage(Map<String, dynamic> message) {
    _webSocketService.sendMessage(message);
  }

  void _requestVerificationKey() {
    final requestJson = jsonEncode({"request": "es_verification_key"});

    final requestMessage = {
      "sourcePeer": "poe_tp",
      "targetPeer": "poe_es",
      "payload": base64Encode(utf8.encode(requestJson))
    };

    _sendMessage(requestMessage);

    setState(() {
      _messages.add("Richiesta della chiave di verifica inviata al poe_es");
    });
  }

  void _handleMessage(String message) async {
    try {
      if (!_isJson(message)) {
        setState(() {
          _messages.add("Errore: $message non è in formato JSON.");
        });
        return;
      }

      final data = jsonDecode(message);

      if (data['payload'] != null) {
        final payloadString = utf8.decode(base64Decode(data['payload']));
        final payload = jsonDecode(payloadString);

        if (payload['json'] != null && payload['signature'] != null) {
          _processSignedJson(payload, data);
        } else if (payload['signed_challenge'] != null &&
            payload['verification_key'] != null &&
            payload['verification_key'] ==
                _receivedJson!['public_key']['verification_key']) {
          _processChallenge(payload, data);
        } else if (payload.containsKey("es_verification_key")) {
          setState(() {
            _verificationKey = CryptoHelper.decodeRSAPublicKeyFromBase64(
                payload["es_verification_key"]);
            _messages.add(
                "Chiave di verifica di ES ricevuta: ${payload["es_verification_key"]}");
          });
        } else if (payload['hello'] != null) {
          setState(() {
            _messages.add(payload['hello']);
          });
          final targetPeerName = data['sourcePeer'];
          _sendMessage(_webSocketService.buildHelloMessage(
              targetPeerName, 'responseHello'));
        } else if (payload['responseHello'] != null) {
          setState(() {
            _messages.add(payload['responseHello']);
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add("Errore durante l'elaborazione del messaggio: $e");
      });
    }
  }

  bool _isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _processSignedJson(
      Map<String, dynamic> payload, Map<String, dynamic> data) {
    if (_verificationKey == null) {
      setState(() {
        _messages.add("La chiave di verifica di ES e' null.");
      });
      return;
    }

    final signedJson = payload['json'];
    final signature = base64Decode(payload['signature']);

    final isValid =
        CryptoHelper.verifySignature(signedJson, signature, _verificationKey!);

    if (isValid) {
      setState(() {
        _messages.add(
            "JSON ricevuto da ${data['sourcePeer']}. Firma del JSON valida. JSON salvato per la verifica futura.");
        _receivedJson = jsonDecode(signedJson);
      });

      _sendChallenge(data['sourcePeer']);
    } else {
      setState(() {
        _messages.add(
            "JSON ricevuto da ${data['sourcePeer']}. Firma del JSON non valida!");
      });
    }
  }

  void _processChallenge(
      Map<String, dynamic> payload, Map<String, dynamic> data) {
    final signedChallenge = base64Decode(payload['signed_challenge']);
    final verificationKey =
        CryptoHelper.decodeRSAPublicKeyFromBase64(payload['verification_key']);

    final isChallengeValid = CryptoHelper.verifySignature(
        _challenge!, signedChallenge, verificationKey);

    if (isChallengeValid && _receivedJson != null) {
      setState(() {
        _messages.add(
            "Challenge valida! Per validare il formato della PoE e visualizzarla premere il pulsante 'Mostra PoE' in basso.");

        // Valida e mostra il JSON salvato
        // FATTO COL BOTTONE?
        //_validateJson();
      });
    } else {
      setState(() {
        _messages.add("Firma della challenge non valida!");
      });
    }
  }

  void _sendChallenge(String targetPeer) {
    try {
      _challenge = "Challenge_${DateTime.now().millisecondsSinceEpoch}";
      final challengeMessage = {
        "sourcePeer": _peerId,
        "targetPeer": targetPeer,
        "payload":
            base64Encode(utf8.encode(jsonEncode({"challenge": _challenge}))),
      };
      _sendMessage(challengeMessage);
      setState(() {
        _messages.add("Challenge inviata al Client.");
      });
    } catch (e) {
      setState(() {
        _messages.add("Errore durante l'invio della challenge: $e");
      });
    }
  }

  void _validateJson() {
    if (_receivedJson == null) {
      setState(() {
        _messages.add("PoE JSON is null.");
      });
      return;
    }
    final jsonString = jsonEncode(_receivedJson!);
    var parser = PoAParser(jsonString);
    final bool isValid = parser.validateAndParse();

    setState(() {
      if (isValid) {
        _receivedJson = null;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PoADetailsPage(
              proofType: parser.proofType,
              publicKeyAlgorithm: parser.publicKeyAlgorithm,
              publicKeyVerification: parser.publicKeyVerification,
              transferable: parser.transferable,
              timestampFormat: parser.timestampFormat,
              timestampTime: parser.timestampTime,
              gpsLat: parser.gpsLat,
              gpsLng: parser.gpsLng,
              gpsAlt: parser.gpsAlt,
              engagementEncoding: parser.engagementEncoding,
              engagementData: parser.engagementData,
              sensitiveDataHashMap: parser.sensitiveDataHashMap,
              otherDataHashMap: parser.otherDataHashMap,
            ),
          ),
        );
      } else {
        _poEToShow = parser.validate();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: Text(_poEToShow),
              actions: <Widget>[
                TextButton(
                  child: const Text('Chiudi'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIComponents.buildDefaultAppBar(context, 'PoE TP'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titolo sopra la lista dei messaggi
            const Text(
              "Messaggi ricevuti",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CommonWidgets.buildMessageList(_messages),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendMessage(
                    _webSocketService.buildHelloMessage("poe_client", 'hello'),
                  ),
                  icon: const Icon(Icons.network_check),
                  label: const Text('Testa connessione con poe_client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendMessage(
                    _webSocketService.buildHelloMessage("poe_es", 'hello'),
                  ),
                  icon: const Icon(Icons.network_check),
                  label: const Text('Testa connessione con poe_es'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _requestVerificationKey,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Chiedi chiave di verifica a ES'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _validateJson,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Mostra PoE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
