import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:jeevaniapp/services/mongo_service.dart';
import 'package:intl/intl.dart';

class AcceptOrdersPage extends StatefulWidget {
  final String farmerId;

  const AcceptOrdersPage({super.key, required this.farmerId});

  @override
  State<AcceptOrdersPage> createState() => _AcceptOrdersPageState();
}

class _AcceptOrdersPageState extends State<AcceptOrdersPage> {
  List<Map<String, dynamic>> pendingOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, Map<String, TextEditingController>> _priceControllers = {};
  DateTime? _selectedDeliveryDate;
  final TextEditingController _deliveryDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _priceControllers.forEach((orderId, controllers) {
      controllers.forEach((vegId, controller) => controller.dispose());
    });
    _deliveryDateController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading ALL pending orders for farmer ${widget.farmerId}');
      final allOrders = await MongoService.getOrdersForFarmer(widget.farmerId);

      if (!mounted) return;

      _priceControllers.clear();
      for (var order in allOrders) {
        final orderId = order['_id']?.toString() ?? 'NO_ID_${allOrders.indexOf(order)}';
        print('Order ID: $orderId');

        final items = List<Map<String, dynamic>>.from(order['items'] as List);
        _priceControllers[orderId] = {};

        for (var item in items) {
          final vegId = item['vegetableId'].toString();
          _priceControllers[orderId]![vegId] = TextEditingController(
            text: (item['pricePerKg'] ?? '').toString(),
          );
        }
      }

      setState(() {
        pendingOrders = allOrders;
        _isLoading = false;
      });

      print('Displaying ${pendingOrders.length} orders sorted by distance');
    } catch (e) {
      print('Error loading orders: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load orders: $e';
      });
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
        _deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    final cleanOrderId = orderId.replaceAll('ObjectId("', '').replaceAll('")', '');

    if (_selectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a delivery date', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final itemPrices = <String, int>{};
    bool hasInvalidPrice = false;

    final orderData = pendingOrders.firstWhere((order) => order['_id'] == orderId);
    final items = List<Map<String, dynamic>>.from(orderData['items'] as List);

    for (var item in items) {
      final vegId = item['vegetableId'].toString();
      final priceController = _priceControllers[orderId]![vegId];

      if (priceController == null) {
        hasInvalidPrice = true;
        break;
      }

      final priceText = priceController.text;
      final pricePerKg = int.tryParse(priceText);

      if (pricePerKg == null || pricePerKg <= 0) {
        hasInvalidPrice = true;
        break;
      } else {
        itemPrices[vegId] = pricePerKg;
      }
    }

    if (hasInvalidPrice || itemPrices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid prices for all items', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      await MongoService.acceptOrder(
        orderId: cleanOrderId,
        farmerId: widget.farmerId,
        itemPrices: itemPrices,
        deliveryDate: _selectedDeliveryDate!,
      );
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order sent for buyer confirmation!', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF56ab2f),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting order: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await MongoService.rejectOrder(orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order rejected successfully', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF56ab2f),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting order: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pending Orders', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF56ab2f),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadOrders, tooltip: 'Refresh')],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF56ab2f)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Color(0xFF56ab2f)),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: GoogleFonts.poppins(color: const Color(0xFF56ab2f), fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(onPressed: _loadOrders, icon: const Icon(Icons.refresh, color: Colors.white), label: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF56ab2f), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
                    ],
                  ),
                )
              : pendingOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 80, color: Color(0xFF56ab2f)),
                          const SizedBox(height: 16),
                          Text('No Pending Orders', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF56ab2f))),
                          const SizedBox(height: 8),
                          Text('Orders awaiting your approval will appear here.', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: const Color(0xFF56ab2f),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          itemCount: pendingOrders.length,
                          itemBuilder: (context, index) {
                            final order = pendingOrders[index];
                            final orderId = order['_id']?.toString() ?? 'NO_ID_$index';
                            final items = List<Map<String, dynamic>>.from(order['items'] as List);
                            final distance = order['distance'] as double? ?? double.infinity;

                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                          Text('Order ID: ${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('Pending', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange))),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(children: [const Icon(Icons.person, color: Color(0xFF56ab2f), size: 20), const SizedBox(width: 8), Expanded(child: Text('Buyer: ${order['buyerName'] ?? 'Unknown'}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800])))]),
                                      const SizedBox(height: 8),
                                      Row(children: [const Icon(Icons.home, color: Color(0xFF56ab2f), size: 20), const SizedBox(width: 8), Expanded(child: Text('Location: ${order['buyerAddress'] ?? 'Unknown'}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800])))]),
                                      const SizedBox(height: 8),
                                      Row(children: [const Icon(Icons.location_on, color: Color(0xFF56ab2f), size: 20), const SizedBox(width: 8), Expanded(child: Text('Distance: ${distance.isFinite ? '${distance.toStringAsFixed(1)} km' : 'Unknown'}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800])))]),
                                      const SizedBox(height: 12),
                                      Text('Items:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                                      const SizedBox(height: 8),
                                      ...items.map<Widget>((item) {
                                        final vegId = item['vegetableId'].toString();
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.local_florist, color: Color(0xFF56ab2f), size: 18),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text('${item['name'] ?? 'Unknown'} - ${item['quantity'] ?? 0} kg', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87))),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              TextFormField(
                                                controller: _priceControllers[orderId]?[vegId],
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Price per kg (₹)',
                                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                                  filled: true,
                                                  fillColor: Colors.grey[100],
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                ),
                                                style: GoogleFonts.poppins(color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _deliveryDateController,
                                        readOnly: true,
                                        onTap: () => _selectDeliveryDate(context),
                                        decoration: InputDecoration(
                                          labelText: 'Delivery Date',
                                          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF56ab2f)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        ),
                                        style: GoogleFonts.poppins(color: Colors.black87),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () => _rejectOrder(orderId),
                                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                            child: const Text('Reject', style: TextStyle(fontSize: 14)),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            onPressed: () => _acceptOrder(orderId),
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF56ab2f), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                            child: const Text('Accept', style: TextStyle(fontSize: 14)),
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
                    ),
    );
  }
}