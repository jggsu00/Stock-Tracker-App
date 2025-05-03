import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

const String finnhubApiKey = 'd0ag111r01qm3l9l6gh0d0ag111r01qm3l9l6ghg';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchedSymbol;
  double? _searchedPrice;

  final List<String> dashboardSymbols = [
    'AAPL',
    'MSFT',
    'TSLA',
    'GOOGL',
    'AMZN',
    'NVDA',
    'META',
    'NFLX',
    'JPM',
    'DIS',
    'INTC',
    'AMD',
  ];

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

  Future<double?> fetchStockPrice(String symbol) async {
    final url = Uri.parse('https://finnhub.io/api/v1/quote?symbol=$symbol&token=$finnhubApiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['c']?.toDouble();
    } else {
      return null;
    }
  }

  Future<void> _searchStock() async {
    final symbol = _searchController.text.trim().toUpperCase();
    if (symbol.isEmpty) return;

    final price = await fetchStockPrice(symbol);

    if (price == null || price == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Symbol not found")),
      );
      setState(() {
        _searchedSymbol = null;
        _searchedPrice = null;
      });
      return;
    }

    setState(() {
      _searchedSymbol = symbol;
      _searchedPrice = price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        title: const Text(
          "STOCK DASHBOARD",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white,),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(labelText: "Search Stock Symbol", labelStyle: TextStyle(color: Colors.black)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black,),
                  onPressed: _searchStock,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_searchedSymbol != null && _searchedPrice != null)
              Card(
                child: ListTile(
                  title: Text(_searchedSymbol!),
                  subtitle: Text('\$${_searchedPrice!.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.star_border),
                    onPressed: () => _addToWatchlist(_searchedSymbol!),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text("Popular Stocks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: dashboardSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = dashboardSymbols[index];
                  return FutureBuilder<double?>(
                    future: fetchStockPrice(symbol),
                    builder: (context, snapshot) {
                      final price = snapshot.data;
                      return Card(
                        child: ListTile(
                          title: Text(symbol),
                          subtitle: Text(price != null ? '\$${price.toStringAsFixed(2)}' : 'Loading...'),
                          trailing: IconButton(
                            icon: const Icon(Icons.star_border),
                            tooltip: 'Add to Watchlist',
                            onPressed: () => _addToWatchlist(symbol),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
