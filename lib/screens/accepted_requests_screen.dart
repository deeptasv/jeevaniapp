import 'package:flutter/material.dart';
import 'package:jeevaniapp/services/mongo_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class AcceptedRequestsScreen extends StatefulWidget {
  final String buyerId;

  const AcceptedRequestsScreen({Key? key, required this.buyerId}) : super(key: key);

  @override
  State<AcceptedRequestsScreen> createState() => _AcceptedRequestsScreenState();
}

class _AcceptedRequestsScreenState extends State<AcceptedRequestsScreen> {
  List<Map<String, dynamic>> acceptedRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAcceptedRequests();
  }

  Future<void> _fetchAcceptedRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await MongoService.getOrdersByBuyer(widget.buyerId);
      if (!mounted) return;

      // Filter accepted orders and fetch farmer details
      List<Map<String, dynamic>> filteredOrders = orders
          .where((order) => order['status'].toLowerCase() == 'accepted')
          .toList()
        ..sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      // Fetch farmer details for each order
      for (var order in filteredOrders) {
        if (order['farmerId'] != null) {
          try {
            final farmerData = await MongoService.getFarmerById(order['farmerId']);
            order['farmerDetails'] = {
              'name': farmerData['name'] ?? 'Unknown Farmer',
              'address': farmerData['location'] ?? 'Not provided',
              'phone': farmerData['phone'] ?? 'Not provided', // Use farmerData['phone']
            };
          } catch (e) {
            order['farmerDetails'] = {
              'name': 'Unknown Farmer',
              'address': 'Not provided',
              'phone': 'Not provided',
            };
            print(
                'Error fetching farmer details for farmerId ${order['farmerId']}: $e');
          }
        } else {
          order['farmerDetails'] = {
            'name': 'Unknown Farmer',
            'address': 'Not provided',
            'phone': 'Not provided',
          };
        }
      }

      if (!mounted) return;
      setState(() {
        acceptedRequests = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load accepted requests: $e';
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) {
      return 'Not provided';
    }

    if (date is String) {
      try {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
      } catch (e) {
        return date; // Return the original string if parsing fails
      }
    } else if (date is DateTime) {
      return DateFormat('yyyy-MM-dd').format(date);
    } else {
      return date.toString(); // Fallback to toString()
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Accepted Requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF56ab2f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF56ab2f)),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Color(0xFF56ab2f),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF56ab2f),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _fetchAcceptedRequests,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF56ab2f),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : acceptedRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Color(0xFF56ab2f),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Accepted Requests',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF56ab2f),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your accepted orders will appear here.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: acceptedRequests.length,
                        itemBuilder: (context, index) {
                          final order = acceptedRequests[index];
                          final items =
                              List<Map<String, dynamic>>.from(order['items']);
                          final farmerDetails =
                              order['farmerDetails'] as Map<String, dynamic>;
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color.fromARGB(255, 250, 252, 249)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.7, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF56ab2f),
                                  child: Text(
                                    items[0]['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Order #${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Accepted on: ${_formatDate(order['updatedAt'] ?? order['createdAt'])}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Farmer: ${farmerDetails['name']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Address: ${farmerDetails['address']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: farmerDetails['phone'] != 'Not provided'
                                          ? () => _makePhoneCall(farmerDetails['phone'])
                                          : null,
                                      child: Text(
                                        'Phone: ${farmerDetails['phone']}',
                                        style: TextStyle(
                                          color: farmerDetails['phone'] != 'Not provided' ? Colors.blue : Colors.grey[600],
                                          fontSize: 14,
                                          decoration: farmerDetails['phone'] != 'Not provided' ? TextDecoration.underline : null,
                                        ),
                                      ),
                                    ),
                                    if (order['deliveryDate'] != null)
                                      Text(
                                        'Delivery Date: ${_formatDate(order['deliveryDate'])}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (order['totalAmount'] != null)
                                      Text(
                                        'Total Amount: ₹${order['totalAmount']}',
                                        style: const TextStyle(
                                          color: Color(0xFF56ab2f),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                                children: items.map<Widget>((item) {
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.local_florist,
                                      color: Color(0xFF56ab2f),
                                      size: 24,
                                    ),
                                    title: Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Quantity: ${item['quantity']} kg',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (item['pricePerKg'] != null)
                                          Text(
                                            'Price: ₹${item['pricePerKg']} per kg',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (item['totalPrice'] != null)
                                          Text(
                                            'Item Total: ₹${item['totalPrice']}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}