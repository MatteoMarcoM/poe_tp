import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';
import '../utility/crypto_helper.dart';
import '../utility/poa_parser.dart';
import '../pages/poa_details_page.dart';

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
  late WebSocketChannel _channel;
  final List<String> _messages = [];
  final String _peerId = "poe_tp"; // ID del peer
  String? _challenge; // Challenge generata
  Map<String, dynamic>? _receivedJson; // JSON ricevuto e verificato
  String _poEToShow = "";

  @override
  void initState() {
    super.initState();
    _channel = HtmlWebSocketChannel.connect('ws://localhost:8080');

    // Registra il peer al server inviando solo l'ID
    _channel.sink.add(_peerId);

    // Ascolta i messaggi ricevuti
    _channel.stream.listen((message) {
      _handleMessage(message);
    });
  }

  /// Gestisce i messaggi ricevuti dal WebSocket
  void _handleMessage(String message) async {
    try {
      // Controlla se il messaggio è un JSON valido
      if (!_isJson(message)) {
        setState(() {
          _messages.add("Peer connesso: $message");
        });
        return;
      }

      // Decodifica il messaggio JSON
      final data = jsonDecode(message);

      if (data['payload'] != null) {
        // Decodifica il payload in Base64
        final payloadString = utf8.decode(base64Decode(data['payload']));
        final payload = jsonDecode(payloadString);

        if (payload['json'] != null && payload['signature'] != null) {
          // Caso 1: Ricezione del JSON iniziale firmato
          final signedJson = utf8.decode(base64Decode(payload['json']));
          final signature = base64Decode(payload['signature']);
          final signingPublicKey = CryptoHelper.decodeRSAPublicKeyFromBase64(
              payload['signing_public_key']);

          // Verifica la firma del JSON
          final isValid = CryptoHelper.verifySignature(
              signedJson, signature, signingPublicKey);

          if (isValid) {
            setState(() {
              _messages.add(
                  "Firma del JSON valida. Salvato per la verifica futura. Invio della challenge al Client...");
              _receivedJson = jsonDecode(signedJson); // Salva il JSON per dopo
            });

            // Genera e invia una challenge al client
            _challenge = "Challenge_${DateTime.now().millisecondsSinceEpoch}";
            final challengeMessage = {
              "sourcePeer": _peerId,
              "targetPeer": data['sourcePeer'],
              "payload": base64Encode(
                  utf8.encode(jsonEncode({"challenge": _challenge}))),
            };
            _channel.sink.add(jsonEncode(challengeMessage));
          } else {
            setState(() {
              _messages.add("Firma del JSON non valida!");
            });
          }
        } else if (payload['signed_challenge'] != null &&
            payload['verification_key'] != null) {
          // Caso 2: Ricezione della challenge firmata
          final signedChallenge = base64Decode(payload['signed_challenge']);
          final verificationKey = CryptoHelper.decodeRSAPublicKeyFromBase64(
              payload['verification_key']);

          // Verifica la firma della challenge
          final isChallengeValid = CryptoHelper.verifySignature(
              _challenge!, signedChallenge, verificationKey);

          if (isChallengeValid && _receivedJson != null) {
            setState(() {
              _messages.add(
                  "Challenge valida! Per visualizzare e validare il formato della PoE premere il pulsante 'Mostra PoE' in basso.");

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
      }
    } catch (e) {
      setState(() {
        _messages.add("Errore durante l'elaborazione del messaggio: $e");
      });
    }
  }

  /// Controlla se una stringa è un JSON valido
  bool _isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Genera una nuova challenge e la invia al peer client
  void _sendChallenge() {
    try {
      // Genera una nuova challenge
      _challenge = "Challenge_${DateTime.now().millisecondsSinceEpoch}";

      // Crea il payload
      final payload = base64Encode(utf8.encode(jsonEncode({
        "challenge": _challenge,
      })));

      // Invia il messaggio
      final message = {
        "sourcePeer": _peerId,
        "targetPeer": "poe_client",
        "payload": payload,
      };
      _channel.sink.add(jsonEncode(message));

      setState(() {
        _messages.add("Challenge inviata al peer poe_client.");
      });
    } catch (e) {
      setState(() {
        _messages.add("Errore durante l'invio della challenge: $e");
      });
    }
  }

  // Metodo per verificare il JSON firmato ricevuto dal client
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
        // Mostra un messaggio di errore
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
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PoE TP')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_messages[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _validateJson,
              child: const Text('Mostra PoE'),
            ),
          ),
          /*if (_receivedJson != null) // Mostra il JSON ricevuto
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'JSON Ricevuto:\n${jsonEncode(_receivedJson)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _sendChallenge,
              child: const Text('Invia challenge'),
            ),
          ),*/
        ],
      ),
    );
  }
}
