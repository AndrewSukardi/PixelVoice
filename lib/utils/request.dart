import 'dart:convert';
import 'package:http/http.dart' as http;

// Modify the function to accept dynamic parameters and Basic Authentication
Future<Map<String, dynamic>?> makePostRequest(
    dynamic gambar, String link) async {
  // The API endpoint
  final url = Uri.parse(link);
  // Base64 encode the username and password for Basic Auth
  // String basicAuth =
  //     'Basic ' + base64Encode(utf8.encode('$username:$password'));

  // The data to send in the request body
  final Map<String, dynamic> requestData = {'Image': gambar};

  // Send POST request
  try {
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(requestData), // Convert the request data to JSON
        )
        .timeout(const Duration(seconds: 20));

    final Map<String, dynamic> responseData = json.decode(response.body);
    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // Decode the response body as JSON

      // Extract specific values from the JSON response

      return {
        'status': response.statusCode,
        'Generated_Caption': responseData['GeneratedCaption'],
        'Generated_Translated_Caption':
            responseData['GeneratedTranslatedCaption'],
      };
    } else {
      return {
        'status': response.statusCode,
        'error': responseData['error']
      }; // Return null in case of failure
    }
  } catch (e) {
    return {'error': '$e'}; // Return null in case of error
  }
}
