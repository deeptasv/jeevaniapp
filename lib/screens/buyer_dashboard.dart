import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeevaniapp/services/mongo_service.dart';
import 'package:jeevaniapp/screens/cart_screen.dart';
import 'package:jeevaniapp/screens/sent_requests_screen.dart';
import 'package:jeevaniapp/screens/accepted_requests_screen.dart';
import 'package:jeevaniapp/screens/buyer_profile_screen.dart';
import 'package:jeevaniapp/screens/available_drivers_screen.dart';
import 'package:jeevaniapp/screens/predictor_page.dart'; 
class BuyerDashboard extends StatefulWidget {
  final String buyerId;

  const BuyerDashboard({super.key, required this.buyerId});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  List<Map<String, dynamic>> vegetables = [];
  List<Map<String, dynamic>> cart = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVegetables();
  }

  Future<void> _loadVegetables() async {
    setState(() => _isLoading = true);
    try {
      final vegList = await MongoService.getVegetables();
      if (mounted) {
        setState(() {
          vegetables = vegList.map((veg) => {
                '_id': veg['_id'].toString(),
                'name': veg['name'],
                'image': veg['image'],
                'quantity': 0,
              }).toList();
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load vegetables: $e';
        });
      }
    }
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      int newQty = vegetables[index]['quantity'] + delta;
      if (newQty < 0) newQty = 0; // Prevent negative quantities
      vegetables[index]['quantity'] = newQty;
    });
  }

  void _setQuantity(int index) async {
    TextEditingController qtyController = TextEditingController(
      text: vegetables[index]['quantity'].toString(),
    );
    int? newQty = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Quantity for ${vegetables[index]['name']}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF56ab2f), width: 2),
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              int? value = int.tryParse(qtyController.text);
              if (value != null && value >= 0) {
                Navigator.pop(context, value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid quantity',
                        style: GoogleFonts.poppins()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF56ab2f),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Set', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newQty != null && mounted) {
      setState(() {
        vegetables[index]['quantity'] = newQty;
      });
    }
  }

  void _addToCart(int index) {
    if (vegetables[index]['quantity'] > 0) {
      setState(() {
        int existingIndex =
            cart.indexWhere((item) => item['name'] == vegetables[index]['name']);
        if (existingIndex != -1) {
          cart[existingIndex]['quantity'] = vegetables[index]['quantity'];
        } else {
          cart.add(Map.from(vegetables[index]));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${vegetables[index]['name']} Added to Cart!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF56ab2f),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateCart(List<Map<String, dynamic>> updatedCart) {
    setState(() => cart = updatedCart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Fresh Picks',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF56ab2f),
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        cart: cart,
                        onUpdate: _updateCart,
                        buyerId: widget.buyerId,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadVegetables(); // Refresh after successful order
                    }
                    setState(() {}); // Update UI regardless of result
                  });
                },
                tooltip: 'Cart',
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                        color: Color(0xFF56ab2f),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF56ab2f),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Image.asset(
                          'assets/logo.png.jpeg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuyerProfileScreen(buyerId: widget.buyerId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.send,
                      title: 'Sent Requests',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SentRequestsScreen(buyerId: widget.buyerId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.check_circle,
                      title: 'Accepted Requests',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AcceptedRequestsScreen(buyerId: widget.buyerId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.local_shipping,
                      title: 'Available Drivers',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AvailableDriversScreen(buyerId: widget.buyerId),
                        ),
                      ),
                    ),
                     const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.price_check,
                      title: 'Price Prediction',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PricePredictorScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF56ab2f)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Color(0xFF56ab2f)),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF56ab2f),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _loadVegetables,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text('Retry',
                            style: GoogleFonts.poppins(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF56ab2f),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : vegetables.isEmpty
                  ? Center(
                      child: Text(
                        'No Fresh Picks Available',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF56ab2f),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 0.1,
                          mainAxisSpacing: 3,
                          childAspectRatio: 0.57,
                        ),
                        itemCount: vegetables.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color.fromARGB(255, 228, 250, 216)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.7, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: vegetables[index]['image'] != null &&
                                              vegetables[index]['image'].isNotEmpty
                                          ? Image.network(
                                              vegetables[index]['image'],
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 100, color: Colors.grey),
                                            )
                                          : const Icon(Icons.local_florist,
                                              size: 100, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      vegetables[index]['name'] ?? 'Unknown',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Color(0xFF56ab2f)),
                                          onPressed: () => _updateQuantity(index, -1),
                                          tooltip: 'Decrease Quantity',
                                        ),
                                        GestureDetector(
                                          onTap: () => _setQuantity(index),
                                          child: Container(
                                            width: 35,
                                            padding: const EdgeInsets.symmetric(vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF56ab2f)),
                                            ),
                                            child: Text(
                                              '${vegetables[index]['quantity']}',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                color: const Color(0xFF56ab2f),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle,
                                              color: Color(0xFF56ab2f)),
                                          onPressed: () => _updateQuantity(index, 1),
                                          tooltip: 'Increase Quantity',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _addToCart(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        'Add to Cart',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF56ab2f),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}