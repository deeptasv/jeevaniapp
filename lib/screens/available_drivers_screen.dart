import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

class AvailableDriversScreen extends StatelessWidget {
  final String buyerId;

  AvailableDriversScreen({super.key, required this.buyerId});

  // Dummy data for drivers
  final List<Map<String, dynamic>> drivers = [
    {
      'name': 'John Kurien',
      'phone': '+91 98765 43210',
      'vehicle': 'Tata Ace',
      'location': 'Kowdiar,Thiruvananthapuram',
      'status': 'Available',
    },
    {
      'name': 'Priya Sharma',
      'phone': '+91 87654 32109',
      'vehicle': 'Maruti Omni',
      'location': 'North Paravoor, Ernakulam',
      'status': 'Available',
    },
    {
      'name': 'Amit Patel',
      'phone': '+91 76543 21098',
      'vehicle': 'Mahindra Bolero',
      'location': 'Mannanthala,Thiruvananthapuram',
      'status': 'Busy',
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Available Drivers',
          style: GoogleFonts.poppins(
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
      body: drivers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 80, color: Color(0xFF56ab2f)),
                  const SizedBox(height: 16),
                  Text(
                    'No Drivers Available',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF56ab2f),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for available drivers.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  driver['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: driver['status'] == 'Available'
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    driver['status'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: driver['status'] == 'Available'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Color(0xFF56ab2f), size: 20),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _makePhoneCall(driver['phone']),
                                  child: Text(
                                    driver['phone'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.local_shipping,
                                    color: Color(0xFF56ab2f), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Vehicle: ${driver['vehicle']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Color(0xFF56ab2f), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location: ${driver['location']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}