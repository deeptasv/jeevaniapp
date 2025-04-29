
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:jeevaniapp/services/mongo_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AcceptedOrdersPage extends StatefulWidget {
  final String farmerId;

  const AcceptedOrdersPage({Key? key, required this.farmerId})
      : super(key: key);

  @override
  State<AcceptedOrdersPage> createState() => _AcceptedOrdersPageState();
}

class _AcceptedOrdersPageState extends State<AcceptedOrdersPage> {
  List<Map<String, dynamic>> acceptedOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, Map<String, dynamic>> _buyerCache = {};

  @override
  void initState() {
    super.initState();
    _fetchAcceptedOrders();
  }

  Future<void> _fetchAcceptedOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders =
          await MongoService.getAcceptedOrdersForFarmer(widget.farmerId);

      for (var order in orders) {
        final buyerId = order['buyerId'];
        if (buyerId != null && !_buyerCache.containsKey(buyerId)) {
          final buyer = await MongoService.getBuyerById(buyerId);
          _buyerCache[buyerId] = buyer;
          print("Fetched buyer: $buyer");
        }
      }

      if (!mounted) return;
      setState(() {
        acceptedOrders =
            orders..sort((a, b) => b['acceptedAt'].compareTo(a['acceptedAt']));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load accepted orders: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      try {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        return date;
      }
    } else if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return 'Not Specified';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    print("Calling: $phoneNumber");
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
      appBar: AppBar(
        title: Text(
          'Accepted Orders',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF56ab2f),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAcceptedOrders,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF56ab2f)),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _fetchAcceptedOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF56ab2f),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : acceptedOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inbox,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No accepted orders yet.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All your accepted orders will appear here',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchAcceptedOrders,
                            color: const Color(0xFF56ab2f),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: acceptedOrders.length,
                              itemBuilder: (context, index) {
                                final order = acceptedOrders[index];
                                final items = List<Map<String, dynamic>>.from(
                                    order['items']);
                                final totalQuantity = items.fold(
                                    0,
                                    (sum, item) =>
                                        sum + (item['quantity'] as int));
                                final totalPrice = order['totalAmount'] ??
                                    0;
                                final buyer = _buyerCache[order['buyerId']] ?? {};
                                final buyerName = buyer['name'] ?? 'Unknown';
                                final buyerAddress =
                                    buyer['location'] ?? 'Address not available';
                                final deliveryDate = order['deliveryDate'];
                                String buyerContact =
                                    buyer['phone'] ?? 'Not Available'; // Corrected line here

                                print("Raw buyer contact: $buyerContact");

                                buyerContact = buyerContact.trim();
                                buyerContact =
                                    buyerContact.replaceAll(RegExp(r'[^0-9+]'), '');
                                final isPhoneNumberValid =
                                    buyerContact.isNotEmpty &&
                                        (buyerContact.length >= 10);

                                print("Cleaned buyer contact: $buyerContact, Valid: $isPhoneNumberValid");

                                return FadeInUp(
                                  delay: Duration(milliseconds: 100 * index),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF56ab2f)
                                                .withOpacity(0.1),
                                        child: Text(
                                          buyerName[0].toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF56ab2f),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'Order ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Buyer: $buyerName',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Accepted: ${_formatDate(order['acceptedAt'])}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Buyer Address:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                buyerAddress,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Delivery Date:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(deliveryDate),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Buyer Contact:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              GestureDetector(
                                                onTap: isPhoneNumberValid
                                                    ? () =>
                                                        _makePhoneCall(buyerContact)
                                                    : null,
                                                child: Text(
                                                  buyerContact == 'Not Available'
                                                      ? buyerContact
                                                      : buyerContact.isEmpty
                                                          ? 'Not Available'
                                                          : buyerContact,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: isPhoneNumberValid
                                                        ? Colors.blue
                                                        : Colors.grey[600],
                                                    decoration: isPhoneNumberValid
                                                        ? TextDecoration.underline
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Order Items:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...items.map((item) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.local_florist,
                                                          color:
                                                              Color(0xFF56ab2f),
                                                          size: 20,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            item['name'],
                                                            style:
                                                                GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          '${item['quantity']} kg',
                                                          style:
                                                              GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.grey[600],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          '₹${item['pricePerKg'] ?? 'N/A'}',
                                                          style:
                                                              GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                              const Divider(height: 24),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Total Quantity:',
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$totalQuantity kg',
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Total Amount:',
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹$totalPrice',
                                                    style:
                                                        GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          const Color(0xFF56ab2f),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}