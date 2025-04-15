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
      home: const TPModule(),
    );
  }
}

class TPModule extends StatefulWidget {
  const TPModule({super.key});

  @override
  State<TPModule> createState() => _TPModuleState();
}

class _TPModuleState extends State<TPModule> {
  final List<String> _messages = [];
  final String _peerId = "poe_tp";
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
      _messages.add("Verification key request sent to poe_es");
    });
  }

  void _handleMessage(String message) async {
    try {
      if (!_isJson(message)) {
        setState(() {
          _messages.add("Error: $message is not in JSON format.");
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
                "ES verification key received: ${payload["es_verification_key"]}");
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
        _messages.add("Error processing message: $e");
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
        _messages.add("ES verification key is null.");
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
            "JSON received from ${data['sourcePeer']}. Valid JSON signature. JSON saved for future verification.");
        _receivedJson = jsonDecode(signedJson);
      });

      _sendChallenge(data['sourcePeer']);
    } else {
      setState(() {
        _messages.add(
            "JSON received from ${data['sourcePeer']}. Invalid JSON signature!");
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
            "Valid challenge! To validate the PoE format and view it, press the 'Show PoE' button below.");
      });
    } else {
      setState(() {
        _messages.add("Invalid challenge signature!");
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
        _messages.add("Challenge sent to Client.");
      });
    } catch (e) {
      setState(() {
        _messages.add("Error sending challenge: $e");
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
              title: const Text('Error'),
              content: Text(_poEToShow),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
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
            // title above the list of messages
            const Text(
              "Received Messages",
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
                  label: const Text('Test connection with poe_client'),
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
                  label: const Text('Test connection with poe_es'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _requestVerificationKey,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Request verification key from ES'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _validateJson,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show PoE'),
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
