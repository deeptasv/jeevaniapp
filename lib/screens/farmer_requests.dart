import 'package:flutter/material.dart';

class AcceptRejectRequestsPage extends StatefulWidget {
  const AcceptRejectRequestsPage({super.key});

  @override
  State<AcceptRejectRequestsPage> createState() => _AcceptRejectRequestsPageState();
}

class _AcceptRejectRequestsPageState extends State<AcceptRejectRequestsPage> {
  final List<Map<String, dynamic>> requests = [
    {'buyer': 'John Doe', 'vegetable': 'Tomato', 'quantity': 10},
    {'buyer': 'Jane Smith', 'vegetable': 'Carrot', 'quantity': 5},
  ];

  void _acceptRequest(int index) {
    setState(() {
      requests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request accepted successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rejectRequest(int index) {
    setState(() {
      requests.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Request rejected successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests to Accept/Reject',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF56ab2f),
      ),
      body: requests.isEmpty
          ? const Center(child: Text('No pending requests.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text('${requests[index]['buyer']} requested ${requests[index]['quantity']} kg of ${requests[index]['vegetable']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _acceptRequest(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _rejectRequest(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
