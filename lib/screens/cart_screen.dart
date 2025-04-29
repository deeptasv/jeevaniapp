import 'package:flutter/material.dart';
import 'package:jeevaniapp/services/mongo_service.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final void Function(List<Map<String, dynamic>>) onUpdate;
  final String buyerId;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onUpdate,
    required this.buyerId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isRequestingOrder = false;

  Future<void> _requestOrder(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Confirm Order',
          style: TextStyle(color: Color(0xFF56ab2f), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to request this order?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF56ab2f),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRequestingOrder = true);

    try {
      final orderItems = widget.cart.map((item) => {
            'vegetableId': item['_id'],
            'name': item['name'],
            'quantity': item['quantity'],
          }).toList();

      await MongoService.createOrder(
        buyerId: widget.buyerId,
        items: orderItems,
      );

      widget.onUpdate([]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order requested successfully!'),
            backgroundColor: const Color(0xFF56ab2f),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request order: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, false); // Return false on failure
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Your Cart',
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
          onPressed: () => Navigator.pop(context, false), // Return false if back pressed
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Color(0xFF56ab2f),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your Cart is Empty',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF56ab2f),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add some fresh picks to get started!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color.fromARGB(255, 194, 239, 173)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: widget.cart[index]['image'] != null &&
                                      widget.cart[index]['image'].isNotEmpty
                                  ? Image.network(
                                      widget.cart[index]['image'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image,
                                              size: 50, color: Colors.white70),
                                    )
                                  : const Icon(Icons.local_florist,
                                      size: 50, color: Colors.white70),
                            ),
                            title: Text(
                              widget.cart[index]['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              'Qty: ${widget.cart[index]['quantity']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                final updatedCart =
                                    List<Map<String, dynamic>>.from(widget.cart);
                                updatedCart.removeAt(index);
                                widget.onUpdate(updatedCart);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: !_isRequestingOrder ? () => _requestOrder(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF56ab2f),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: _isRequestingOrder
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Request Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}