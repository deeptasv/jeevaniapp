import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DemandPredictorScreen extends StatefulWidget {
  @override
  _DemandPredictorScreenState createState() => _DemandPredictorScreenState();
}

class _DemandPredictorScreenState extends State<DemandPredictorScreen> {
  List<Map<String, dynamic>> vegetables = [];
  bool isLoading = false;

  // Fetch vegetables sorted by demand from the backend
  Future<void> fetchVegetables() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch sorted vegetable list from the backend
      final response = await http.get(
        Uri.parse('http://10.40.12.14:5000/get_vegetable_demand'),  // Your backend URL
      );

      if (response.statusCode == 200) {
        final vegetableData = jsonDecode(response.body);
        setState(() {
          vegetables = List<Map<String, dynamic>>.from(vegetableData);
          isLoading = false;
        });
      } else {
        print('Failed to fetch vegetable list');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching vegetables: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVegetables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('In Demand ',style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),),
        backgroundColor: Color(0xFF56ab2f),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vegetables.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(vegetables[index]['vegetable']),
                    subtitle: Text('Demand: ${vegetables[index]['demand']}'),
                  ),
                );
              },
            ),
    );
  }
}
