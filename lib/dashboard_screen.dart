import 'package:flutter/material.dart';
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
            _stockCard("AAPL", "\$187.88", "+0.52%"),
            _stockCard("MSFT", "\$312.22", "-1.23%"),
            _stockCard("TSLA", "\$723.12", "+2.01%"),
            TextButton(onPressed: () {}, child: const Text("View More"))
          ],
        ),
      ),
    );
  }

  Widget _stockCard(String symbol, String price, String change) {
    return Card(
      child: ListTile(
        title: Text("Stock: $symbol - $price ($change)"),
      ),
    );
  }
}
