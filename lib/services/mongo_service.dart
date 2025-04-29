import 'package:mongo_dart/mongo_dart.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class MongoService {
  static late Db _db;
  static bool _isConnected = false;
  static late DbCollection farmerVegetablesCollection;

  static Future<void> connect() async {
    if (_isConnected) return;
    _db = await Db.create(
        'mongodb+srv://parvathyysalin:itsme@jeevanicluster.foovzgn.mongodb.net/jeevaniDB?retryWrites=true&w=majority&appName=JeevaniCluster');
    await _db.open();
    _isConnected = true;
    print('MongoService: Connected to database');
  }
  static Future<Location?> _getCoordinatesFromPlace(String placeName) async {
    try {
      final query = "$placeName, Kerala, India";
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      print('Error geocoding $placeName: $e');
      return null;
    }
  }

  static Future<void> updateFarmerProfile({
    required String farmerId,
    required String name,
    required String phone,
    required String location,
  }) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('farmers');
      await collection.updateOne(
        where.eq('_id', ObjectId.parse(farmerId)),
        modify
          ..set('name', name)
          ..set('phonenumber', phone)
          ..set('address', location),
      );
    } catch (e) {
      print('Error updating farmer profile: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getVegetables() async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('vegetables');
      final vegetables = await collection.find().toList();
      return vegetables.map((veg) => {...veg, '_id': veg['_id'].toString()}).toList();
    } catch (e) {
      print('MongoService: Failed to fetch vegetables: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getBuyerById(String buyerId) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('buyers');
      final buyer = await collection.findOne(where.eq('_id', ObjectId.parse(buyerId)));
      if (buyer == null) {
        throw Exception('Buyer not found');
      }
      return {...buyer, '_id': buyer['_id'].toString()};
    } catch (e) {
      print('MongoService: Error fetching buyer by ID: $e');
      rethrow;
    }
  }
 static double _calculateDistance(Location loc1, Location loc2) {
    final Distance distance = Distance();
    return distance(
      LatLng(loc1.latitude, loc1.longitude),
      LatLng(loc2.latitude, loc2.longitude),
    ) / 1000; // Convert to kilometers
  }

  static Future<Map<String, dynamic>> getFarmerById(String farmerId) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('farmers');
      final farmer = await collection.findOne(where.eq('_id', ObjectId.parse(farmerId)));
      if (farmer == null) {
        throw Exception('Farmer not found');
      }
      return {...farmer, '_id': farmer['_id'].toString()};
    } catch (e) {
      print('MongoService: Error fetching farmer by ID: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getFarmerVegetables(String farmerId) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('farmervegetables');
      final farmerVegs = await collection.find(where.eq('farmerId', farmerId)).toList();
      return farmerVegs.map((veg) => {...veg, '_id': veg['_id'].toString()}).toList();
    } catch (e) {
      print('MongoService: Failed to fetch farmer vegetables: $e');
      throw Exception('Failed to fetch farmer vegetables: $e');
    }
  }

static Future<void> updateFarmerVegetableQuantity(
  String farmerId, 
  String vegetableId, 
  int quantity
) async {
  if (!_isConnected) await connect();
  final collection = _db.collection('farmervegetables');
  
  // First try to find the existing document
  final existing = await collection.findOne(
    where.eq('farmerId', farmerId).eq('vegetableId', vegetableId)
  );

  if (existing != null) {
    // Update existing document
    await collection.updateOne(
      where.eq('_id', existing['_id']),
      modify.set('quantity', quantity),
    );
  } else {
    // Create new document if doesn't exist
    await collection.insertOne({
      'farmerId': farmerId,
      'vegetableId': vegetableId,
      'quantity': quantity,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

  static Future<bool> deleteFarmerVegetable(String farmerId, String vegetableId) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('farmervegetables');
      final result = await collection.deleteOne(
        where.eq('farmerId', farmerId).eq('vegetableId', vegetableId),
      );
      print('Delete result: ${result.nRemoved} documents removed');
      return result.nRemoved > 0;
    } catch (e) {
      print('Delete error: $e');
      throw Exception('Delete failed: $e');
    }
  }

  static Future<void> createOrder({
    required String buyerId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('orders');
      await collection.insertOne({
        'buyerId': buyerId,
        'items': items,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
      print('MongoService: Order created successfully');
    } catch (e) {
      print('MongoService: Failed to create order: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByBuyer(String buyerId) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('orders');
      final orders = await collection.find(where.eq('buyerId', buyerId)).toList();
      return orders.map((order) => {...order, '_id': order['_id'].toString()}).toList();
    } catch (e) {
      print('MongoService: Failed to fetch orders for buyer $buyerId: $e');
      rethrow;
    }
  }
static Future<void> acceptOrder({
  required String orderId,
  required String farmerId,
  required Map<String, int> itemPrices, // Map of vegetableId to pricePerKg
  required DateTime deliveryDate,
}) async {
  try {
    if (!_isConnected) await connect();
    final collection = _db.collection('orders');
    final cleanOrderId = orderId.replaceAll('ObjectId("', '').replaceAll('")', '');
    final order = await collection.findOne(where.eq('_id', ObjectId.parse(cleanOrderId)));
    if (order == null) throw Exception('Order not found');

    final updatedItems = <Map<String, dynamic>>[];
    double totalAmount = 0.0;

    for (var item in (order['items'] as List)) {
      final vegId = item['vegetableId'].toString();
      final quantity = item['quantity'] as int;
      final pricePerKg = itemPrices[vegId] ?? 0; // Use price from itemPrices, default to 0 if not found
      final itemTotal = pricePerKg * quantity;

      updatedItems.add({
        ...item,
        'pricePerKg': pricePerKg,
        'totalPrice': itemTotal,
      });
      totalAmount += itemTotal;
    }

    await collection.updateOne(
      where.eq('_id', ObjectId.parse(cleanOrderId)),
      modify
        ..set('status', 'accepted') // Changed from 'pending_buyer' to 'accepted'
        ..set('farmerId', farmerId)
        ..set('items', updatedItems)
        ..set('totalAmount', totalAmount)
        ..set('deliveryDate', deliveryDate.toIso8601String())
        ..set('acceptedAt', DateTime.now().toIso8601String()),
    );
  } catch (e) {
    print('Error accepting order: $e');
    throw Exception('Failed to accept order: ${e.toString()}');
  }
}

  static Future<List<Map<String, dynamic>>> getOrdersForFarmer(String farmerId) async {
    try {
      if (!_isConnected) await connect();

      // Get farmer's details including address
      final farmer = await getFarmerById(farmerId);
      final farmerLocation = await _getCoordinatesFromPlace(farmer['location']);
      if (farmerLocation == null) {
        throw Exception('Could not determine farmer location');
      }

      final ordersCollection = _db.collection('orders');
      final pendingOrders = await ordersCollection.find(where.eq('status', 'pending')).toList();
      final farmerVegsCollection = _db.collection('farmervegetables');
      final farmerVegs = await farmerVegsCollection.find(where.eq('farmerId', farmerId)).toList();

      final farmerVegsMap = {
        for (var veg in farmerVegs) veg['vegetableId'].toString(): veg['quantity'] as int
      };

      final fulfillableOrders = <Map<String, dynamic>>[];

      for (var order in pendingOrders) {
        try {
          final orderItems = List<Map<String, dynamic>>.from(order['items']);
          final fulfillableItems = <Map<String, dynamic>>[];
          bool canFulfillOrder = true;

          for (var item in orderItems) {
            final vegId = item['vegetableId'] is ObjectId
                ? item['vegetableId'].toHexString()
                : item['vegetableId'].toString();
            final requiredQty = item['quantity'] as int;
            final availableQty = farmerVegsMap[vegId] ?? 0;

            if (availableQty >= requiredQty) {
              fulfillableItems.add({
                'vegetableId': vegId,
                'name': item['name'],
                'quantity': requiredQty,
              });
            } else {
              canFulfillOrder = false;
              break;
            }
          }

          if (canFulfillOrder && fulfillableItems.isNotEmpty) {
            final buyer = await getBuyerById(order['buyerId']);
            final buyerLocation = await _getCoordinatesFromPlace(buyer['location']);

            double distance = double.infinity;
            if (buyerLocation != null) {
              distance = _calculateDistance(farmerLocation, buyerLocation);
            }

            fulfillableOrders.add({
              '_id': order['_id'].toString(),
              'buyerId': order['buyerId'],
              'buyerName': buyer['name'] ?? 'Unknown',
              'buyerAddress': buyer['location'] ?? 'Unknown',
              'items': fulfillableItems,
              'status': order['status'],
              'createdAt': order['createdAt'],
              'pricePerKg': order['pricePerKg'] ?? 0,
              'distance': distance,
            });
          }
        } catch (e) {
          print('Error processing order ${order['_id']}: $e');
        }
      }

      // Sort by distance
      fulfillableOrders.sort((a, b) => a['distance'].compareTo(b['distance']));

      print('Found ${pendingOrders.length} pending orders');
      print('Farmer can fulfill ${fulfillableOrders.length} orders');
      return fulfillableOrders;
    } catch (e) {
      print('Error in getOrdersForFarmer: $e');
      throw Exception('Failed to fetch orders: ${e.toString()}');
    }
  }
  static Future<void> rejectOrder(String orderId) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('orders');
      // Strip the ObjectId("...") wrapper if present
      final cleanOrderId = orderId.replaceAll('ObjectId("', '').replaceAll('")', '');
      await collection.deleteOne(where.eq('_id', ObjectId.parse(cleanOrderId)));
    } catch (e) {
      print('Error rejecting order: $e');
      throw Exception('Failed to reject order: ${e.toString()}');
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      if (!_isConnected) await connect();
      final collection = _db.collection('orders');
      // Strip the ObjectId("...") wrapper if present
      final cleanOrderId = orderId.replaceAll('ObjectId("', '').replaceAll('")', '');
      await collection.updateOne(
        where.eq('_id', ObjectId.parse(cleanOrderId)),
        modify.set('status', status).set('updatedAt', DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('MongoService: Failed to update order status for $orderId: $e');
      rethrow;
    }
  }
static Future<List<Map<String, dynamic>>> getAcceptedOrdersForFarmer(String farmerId) async {
  try {
    if (!_isConnected) await connect();
    final collection = _db.collection('orders');
    final orders = await collection
        .find(where.eq('farmerId', farmerId).eq('status', 'accepted'))
        .toList();

    final enrichedOrders = <Map<String, dynamic>>[];
    for (var order in orders) {
      final buyer = await getBuyerById(order['buyerId']);
      enrichedOrders.add({
        '_id': order['_id'].toString(),
        'buyerId': order['buyerId'],
        'buyerName': buyer['name'] ?? 'Unknown',
        'buyerAddress': buyer['address'] ?? 'Address not available',
        'items': List<Map<String, dynamic>>.from(order['items']), // Keep the full items array with pricePerKg and totalPrice
        'totalAmount': order['totalAmount'] ?? 0.0, // Include totalAmount from the database
        'status': order['status'],
        'createdAt': order['createdAt'],
        'acceptedAt': order['acceptedAt'],
        'deliveryDate': order['deliveryDate'], // Optional: Add if needed in UI
      });
    }

    return enrichedOrders;
  } catch (e) {
    print('Error fetching accepted orders for farmer: $e');
    throw Exception('Failed to fetch accepted orders: ${e.toString()}');
  }
}

  static Future<void> close() async {
    if (_isConnected) {
      await _db.close();
      _isConnected = false;
      print('MongoService: Database connection closed');
    }
  }
}