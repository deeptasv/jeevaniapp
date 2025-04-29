import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double?> getPredictedPrice(String vegetable, int quantity) async {
  final url = Uri.parse("http://10.40.12.14:5000/predict_price");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "vegetable": vegetable,
      "quantity": quantity,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["predictedPrice"];
  } else {
    print("API error: ${response.body}");
    return null;
  }
}
