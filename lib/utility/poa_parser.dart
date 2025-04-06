import 'dart:convert';

const String successMessage = 'Valid JSON!';
const String failMessage = 'Error: Invalid JSON!';

class PoAParser {
  final String rawJson;
  late Map<String, dynamic> parsedJson;

  PoAParser(this.rawJson);

  // Information extracted from JSON
  String proofType = '';
  bool transferable = false;
  String publicKeyAlgorithm = '';
  String publicKeyVerification = '';
  String timestampFormat = '';
  String timestampTime = '';
  double gpsLat = 0;
  double gpsLng = 0;
  double gpsAlt = 0;
  String engagementEncoding = '';
  String engagementData = '';
  Map<String, String> sensitiveDataHashMap = {'': ''};
  Map<String, dynamic> otherDataHashMap = {'': ''};

  bool validateAndParse() {
    String validationMessage = validate();
    if (validationMessage == successMessage) {
      // Complete field parsing
      proofType = parsedJson['proof_type'];
      transferable = parsedJson['transferable'];

      // Public key parsing
      final publicKey = parsedJson['public_key'];
      publicKeyAlgorithm = publicKey['algorithm'];
      publicKeyVerification = publicKey['verification_key'];

      // Timestamp parsing
      final timestamp = parsedJson['timestamp'];
      timestampFormat = timestamp['time_format'];
      timestampTime = timestamp['time'];

      // GPS coordinates parsing
      final gps = parsedJson['gps'];
      gpsLat = gps['lat'].toDouble();
      gpsLng = gps['lng'].toDouble();
      gpsAlt = gps['alt'].toDouble();

      // Engagement data parsing
      final engagement = parsedJson['engagement_data'];
      engagementEncoding = engagement['encoding'];
      engagementData = engagement['data'];

      // Sensitive data parsing
      final sensitiveData = parsedJson['sensitive_data'];
      sensitiveData.forEach((key, value) {
        sensitiveDataHashMap[key] = value;
      });

      // Other data parsing
      if (parsedJson.containsKey('other_data')) {
        otherDataHashMap = parsedJson['other_data'];
      }

      return true;
    }

    return false;
  }

  String validate() {
    try {
      parsedJson = jsonDecode(rawJson);

      // Checking main keys
      if (!parsedJson.containsKey('proof_type') ||
          parsedJson['proof_type'] is! String) {
        return 'Error: The "proof_type" field is missing or not a string.';
      }
      if (!parsedJson.containsKey('transferable') ||
          parsedJson['transferable'] is! bool) {
        return 'Error: The "transferable" field is missing or not a boolean.';
      }
      if (!parsedJson.containsKey('public_key') ||
          parsedJson['public_key'] is! Map) {
        return 'Error: The "public_key" field is missing or not an object.';
      }

      // Public key verification
      final publicKey = parsedJson['public_key'];
      if (!publicKey.containsKey('algorithm') ||
          publicKey['algorithm'] is! String) {
        return 'Error: The "algorithm" field is missing or not a string.';
      }
      if (!publicKey.containsKey('verification_key') ||
          publicKey['verification_key'] is! String) {
        return 'Error: The "verification_key" field is missing or not a string.';
      }

      // Timestamp verification
      if (!parsedJson.containsKey('timestamp') ||
          parsedJson['timestamp'] is! Map) {
        return 'Error: The "timestamp" field is missing or not an object.';
      }
      final timestamp = parsedJson['timestamp'];
      if (!timestamp.containsKey('time_format') ||
          timestamp['time_format'] is! String) {
        return 'Error: The "time_format" field is missing or not a string.';
      }
      if (!timestamp.containsKey('time') || timestamp['time'] is! String) {
        return 'Error: The "time" field is missing or not a string.';
      }

      // GPS coordinates verification
      if (!parsedJson.containsKey('gps') || parsedJson['gps'] is! Map) {
        return 'Error: The "gps" field is missing or not an object.';
      }
      final gps = parsedJson['gps'];
      if (!gps.containsKey('lat') || gps['lat'] is! num) {
        return 'Error: The "lat" field is missing or not a number.';
      }
      if (!gps.containsKey('lng') || gps['lng'] is! num) {
        return 'Error: The "lng" field is missing or not a number.';
      }
      if (!gps.containsKey('alt') || gps['alt'] is! num) {
        return 'Error: The "alt" field is missing or not a number.';
      }

      // Engagement data verification
      if (!parsedJson.containsKey('engagement_data') ||
          parsedJson['engagement_data'] is! Map) {
        return 'Error: The "engagement_data" field is missing or not an object.';
      }
      final engagementData = parsedJson['engagement_data'];
      if (!engagementData.containsKey('encoding') ||
          engagementData['encoding'] is! String) {
        return 'Error: The "encoding" field is missing or not a string.';
      }
      if (!engagementData.containsKey('data') ||
          engagementData['data'] is! String) {
        return 'Error: The "data" field is missing or not a string.';
      }

      // Sensitive data verification
      if (!parsedJson.containsKey('sensitive_data') ||
          parsedJson['sensitive_data'] is! Map) {
        return 'Error: The "sensitive_data" field is missing or not an object.';
      }
      final sensitiveData = parsedJson['sensitive_data'];
      sensitiveData.forEach((key, value) {
        if (value is! String) {
          return 'Error: The "$key" field in sensitive data is not a string.';
        }
      });

      // Other data verification (optional)
      if (parsedJson.containsKey('other_data') &&
          parsedJson['other_data'] is! Map) {
        return 'Error: The "other_data" field is not a valid JSON object.';
      }

      return successMessage;
    } catch (e) {
      return failMessage;
    }
  }
}
