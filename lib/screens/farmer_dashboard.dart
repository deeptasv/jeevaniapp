import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:jeevaniapp/screens/demand.dart';
//import 'package:jeevaniapp/screens/demand.dart';
import 'package:jeevaniapp/services/mongo_service.dart';
import 'profile_page.dart';
import 'accepted_orders_page.dart';
import 'accept_orders_page.dart';

class FarmerDashboard extends StatefulWidget {
  final String farmerId;

  const FarmerDashboard({super.key, required this.farmerId});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  List<Map<String, dynamic>> allVegetables = [];
  List<Map<String, dynamic>> farmerVegetables = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        MongoService.getVegetables(),
        MongoService.getFarmerVegetables(widget.farmerId),
      ]);

      if (!mounted) return;
      setState(() {
        allVegetables = results[0];
        farmerVegetables = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _farmerVegetablesWithDetails {
    return farmerVegetables.map((fv) {
      final vegetableId = fv['vegetableId']?.toString();
      if (vegetableId == null) {
        return {
          ...fv,
          'name': 'Unknown Vegetable',
          'image': '',
          'quantity': fv['quantity'] ?? 0,
        };
      }
      final vegetable = allVegetables.firstWhere(
        (v) => v['_id']?.toString() == vegetableId,
        orElse: () => {'name': 'Unknown Vegetable', 'image': ''},
      );
      return {
        ...fv,
        'vegetableId': vegetableId,
        'name': vegetable['name'] ?? 'Unknown Vegetable',
        'image': vegetable['image'] ?? '',
        'quantity': fv['quantity'] ?? 0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _availableVegetablesToAdd {
    final farmerVegIds = farmerVegetables
        .map((v) => v['vegetableId']?.toString())
        .where((id) => id != null)
        .toSet();
    return allVegetables.where((veg) {
      final vegId = veg['_id']?.toString();
      return vegId != null && !farmerVegIds.contains(vegId);
    }).map((veg) {
      return {
        ...veg,
        '_id': veg['_id']?.toString(),
        'name': veg['name'] ?? 'Unknown Vegetable',
        'image': veg['image'] ?? '',
        'quantity': 0,
      };
    }).toList();
  }

  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> vegetable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete ${vegetable['name']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove ${vegetable['name']} from your stock?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF56ab2f))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final deleted = await MongoService.deleteFarmerVegetable(
          widget.farmerId,
          vegetable['vegetableId'].toString(),
        );
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted ? '${vegetable['name']} deleted successfully' : 'Vegetable not found in stock',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: deleted ? const Color(0xFF56ab2f) : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ${vegetable['name']}: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> vegetable, bool isUpdate) async {
    await showDialog(
      context: context,
      builder: (context) => QuantityDialog(
        vegetable: vegetable,
        isUpdate: isUpdate,
        initialQuantity: isUpdate ? (vegetable['quantity'] ?? 0) : 0,
        onConfirm: (int quantity) async {
          try {
            final vegetableId = isUpdate ? vegetable['vegetableId'].toString() : vegetable['_id'].toString();
            await MongoService.updateFarmerVegetableQuantity(widget.farmerId, vegetableId, quantity);
            await _loadData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isUpdate ? 'Quantity updated successfully' : 'Vegetable added successfully',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: const Color(0xFF56ab2f),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e', style: GoogleFonts.poppins()),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildVegetableCard(Map<String, dynamic> vegetable, bool isExisting) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 242, 246, 240)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.7, 1.0],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: vegetable['image'] != null && vegetable['image'].toString().isNotEmpty
                    ? Image.network(
                        vegetable['image'].toString(),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultVegetableIcon(),
                      )
                    : _buildDefaultVegetableIcon(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vegetable['name'] ?? 'Unknown Vegetable',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExisting ? '${vegetable['quantity']} kg in stock' : 'Add to stock',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isExisting ? const Color(0xFF56ab2f) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(isExisting ? Icons.edit : Icons.add_circle, color: const Color(0xFF56ab2f)),
                    onPressed: () => _showQuantityDialog(vegetable, isExisting),
                  ),
                  if (isExisting)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirmationDialog(vegetable),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultVegetableIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.local_florist, color: Color(0xFF56ab2f), size: 30),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF56ab2f),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50, // Adjusted radius to fit logo comfortably
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Padding to ensure logo fits within circle
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png.jpeg', // Adjust path if needed
                          fit: BoxFit.contain,
                          width: 70, // Fixed size to ensure proper scaling
                          height: 70,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.local_florist,
                            size: 40,
                            color: Color(0xFF56ab2f),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menu',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                        builder: (context) => FarmerProfileScreen(farmerId: widget.farmerId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.check_circle,
                    title: 'Accepted Orders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AcceptedOrdersPage(farmerId: widget.farmerId)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.pending_actions,
                    title: 'Accept Orders',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AcceptOrdersPage(farmerId: widget.farmerId)),
                    ),
                  ),
               const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.pending_actions,
                    title: 'Demand',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DemandPredictorScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Vegetables',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF56ab2f),
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF56ab2f)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Color(0xFF56ab2f)),
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
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF56ab2f),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF56ab2f),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'My Current Stock',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF56ab2f),
                            ),
                          ),
                        ),
                      ),
                      _farmerVegetablesWithDetails.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'No vegetables in stock yet',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => FadeInUp(
                                  delay: Duration(milliseconds: 100 * index),
                                  child: _buildVegetableCard(_farmerVegetablesWithDetails[index], true),
                                ),
                                childCount: _farmerVegetablesWithDetails.length,
                              ),
                            ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Add New Vegetables',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF56ab2f),
                            ),
                          ),
                        ),
                      ),
                      _availableVegetablesToAdd.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'No new vegetables available',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => FadeInUp(
                                  delay: Duration(milliseconds: 100 * index),
                                  child: _buildVegetableCard(_availableVegetablesToAdd[index], false),
                                ),
                                childCount: _availableVegetablesToAdd.length,
                              ),
                            ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: const Color(0xFF56ab2f),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

class QuantityDialog extends StatefulWidget {
  final Map<String, dynamic> vegetable;
  final bool isUpdate;
  final int initialQuantity;
  final Future<void> Function(int) onConfirm;

  const QuantityDialog({
    super.key,
    required this.vegetable,
    required this.isUpdate,
    required this.initialQuantity,
    required this.onConfirm,
  });

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.initialQuantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        widget.isUpdate ? 'Update ${widget.vegetable['name']}' : 'Add ${widget.vegetable['name']}',
        style: GoogleFonts.poppins(
          color: const Color(0xFF56ab2f),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity (kg)',
            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF56ab2f), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: GoogleFonts.poppins(color: Colors.black87),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter quantity';
            final qty = int.tryParse(value);
            if (qty == null || qty < 0) return 'Enter a valid quantity';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.poppins(color: const Color(0xFF56ab2f))),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isProcessing = true);
                    try {
                      await widget.onConfirm(int.parse(_quantityController.text));
                      if (mounted) Navigator.pop(context);
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF56ab2f),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  widget.isUpdate ? 'Update' : 'Add',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}