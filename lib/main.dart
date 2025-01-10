import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';
import '../utility/crypto_helper.dart';

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
      // Decodifica del messaggio JSON ricevuto
      final data = jsonDecode(message);

      if (data['payload'] != null) {
        // Decodifica del payload in Base64
        final payloadString = utf8.decode(base64Decode(data['payload']));

        // Decodifica del JSON dal payload
        final payload = jsonDecode(payloadString);
        final sourcePeer = data['sourcePeer'];

        // Verifica il contenuto del payload
        if (payload['signed_challenge'] != null) {
          final signedChallenge = base64Decode(payload['signed_challenge']);
          final verificationKey = CryptoHelper.decodeRSAPublicKeyFromBase64(
              payload['verification_key']);

          // Verifica la firma della challenge
          final isValid = CryptoHelper.verifySignature(
              _challenge!, signedChallenge, verificationKey);
          if (isValid) {
            setState(() {
              _messages
                  .add("Firma della challenge valida dal peer $sourcePeer.");
            });
          } else {
            setState(() {
              _messages.add(
                  "Firma della challenge non valida dal peer $sourcePeer.");
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
              onPressed: _sendChallenge,
              child: const Text('Invia challenge'),
            ),
          ),
        ],
      ),
    );
  }
}
