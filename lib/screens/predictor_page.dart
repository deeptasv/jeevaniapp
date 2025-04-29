import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PricePredictorScreen(),
  ));
}

class PricePredictorScreen extends StatefulWidget {
  @override
  _PricePredictorScreenState createState() => _PricePredictorScreenState();
}

class _PricePredictorScreenState extends State<PricePredictorScreen> {
  final TextEditingController _vegController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  double? predictedPrice;
  bool isLoading = false;

  Future<void> predict() async {
    final vegetable = _vegController.text.trim();
    final quantity = int.tryParse(_qtyController.text.trim()) ?? 0;

    if (vegetable.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid vegetable and quantity.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("http://10.40.12.14:5000/predict_price"); // Replace with your IP

    try {
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
        setState(() {
          predictedPrice = data["predictedPrice"];
        });
      } else {
        print("Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Prediction failed. Try again.")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to connect to the server.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vegetable Price Predictor",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF56ab2f),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Vegetable Input
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _vegController,
                    style: TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Vegetable Name",
                      labelStyle: TextStyle(color: Colors.green[800], fontSize: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Quantity Input
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "Quantity (kg)",
                      labelStyle: TextStyle(color: Colors.green[800], fontSize: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              // Predict Button
              ElevatedButton(
                onPressed: isLoading ? null : predict,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Predict Price", style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF56ab2f),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
              SizedBox(height: 30),
              // Display Predicted Price
              if (predictedPrice != null)
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Predicted Price: ₹${predictedPrice!.toStringAsFixed(2)} per kg",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ),
              // Fallback for no prediction
              if (predictedPrice == null && !isLoading)
                Text(
                  "Enter vegetable and quantity to predict price",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
