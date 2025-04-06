import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class CryptoHelper {
  /// Generates an RSA key pair
  static AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAKeyPair() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(
      List.generate(32, (_) => DateTime.now().millisecond % 256),
    );
    secureRandom.seed(KeyParameter(seed));

    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), 512, 12),
          secureRandom,
        ),
      );

    return keyGen.generateKeyPair();
  }

  /// Signs the JSON content with an RSA private key
  static Uint8List signJson(String jsonString, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));
    return signer.generateSignature(jsonBytes).bytes;
  }

  /// Verifies the digital signature of a JSON file
  static bool verifySignature(
      String jsonString, Uint8List signature, RSAPublicKey publicKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

    final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));
    try {
      return signer.verifySignature(jsonBytes, RSASignature(signature));
    } catch (e) {
      return false;
    }
  }

  /// Converts an RSA public key from Base64
  static RSAPublicKey decodeRSAPublicKeyFromBase64(String base64Key) {
    final keyBytes = base64Decode(base64Key);
    final modulus =
        BigInt.parse(String.fromCharCodes(keyBytes.sublist(0, 256)), radix: 16);
    final exponent =
        BigInt.parse(String.fromCharCodes(keyBytes.sublist(256)), radix: 16);
    return RSAPublicKey(modulus, exponent);
  }
}
