import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }


  Future<void> _addToWatchlist(String symbol) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('watchlists').doc(uid);

    await docRef.set({
      'symbols': FieldValue.arrayUnion([symbol])
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("STOCK DASHBOARD"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Search Stock")),
            const SizedBox(height: 20),
            const Text("STOCKS", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _stockCard(context, "AAPL", "\$187.88", "+0.52%"),
            _stockCard(context, "MSFT", "\$312.22", "-1.23%"),
            _stockCard(context, "TSLA", "\$723.12", "+2.01%"),
            TextButton(onPressed: () {}, child: const Text("View More"))
          ],
        ),
      ),
    );
  }


  Widget _stockCard(BuildContext context, String symbol, String price, String change) {
    return Card(
      child: ListTile(
        title: Text("Stock: $symbol - $price ($change)"),
        trailing: IconButton(
          icon: const Icon(Icons.star_border),
          tooltip: 'Add to Watchlist',
          onPressed: () => _addToWatchlist(symbol),
        ),
      ),
    );
  }
}
