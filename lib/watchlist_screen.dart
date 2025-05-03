import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String finnhubApiKey = 'd0ag111r01qm3l9l6gh0d0ag111r01qm3l9l6ghg';

final Map<String, String> stockCategories = {
  'AAPL': 'Tech',
  'MSFT': 'Tech',
  'GOOGL': 'Tech',
  'TSLA': 'Tech',
  'AMZN': 'Tech',
  'JPM': 'Finance',
  'BAC': 'Finance',
  'WFC': 'Finance',
  'XOM': 'Energy',
  'CVX': 'Energy',
};

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late Future<List<String>> _watchlistFuture;

  @override
  void initState() {
    super.initState();
    _watchlistFuture = _fetchWatchlist();
  }

  Future<List<String>> _fetchWatchlist() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final doc = await FirebaseFirestore.instance.collection('watchlists').doc(uid).get();

    if (!doc.exists || !doc.data()!.containsKey('symbols')) {
      return [];
    }

    List<dynamic> rawList = doc['symbols'];
    return List<String>.from(rawList);
  }

  Future<void> _removeFromWatchlist(String symbol) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('watchlists').doc(uid);

    await docRef.update({
      'symbols': FieldValue.arrayRemove([symbol])
    });

    setState(() {
      _watchlistFuture = _fetchWatchlist();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$symbol removed')),
    );
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

  Map<String, List<String>> categorizeSymbols(List<String> symbols) {
    final Map<String, List<String>> categorized = {};

    for (var symbol in symbols) {
      final category = stockCategories[symbol] ?? 'Other';
      categorized.putIfAbsent(category, () => []).add(symbol);
    }

    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        title: const Text(
          "WATCHLIST",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: FutureBuilder<List<String>>(
        future: _watchlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading watchlist."));
          }

          final symbols = snapshot.data ?? [];
          if (symbols.isEmpty) {
            return const Center(child: Text("No stocks in your watchlist."));
          }

          final categorized = categorizeSymbols(symbols);

          return ListView(
            children: categorized.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...entry.value.map((symbol) {
                    return FutureBuilder<double?>(
                      future: fetchStockPrice(symbol),
                      builder: (context, priceSnapshot) {
                        final price = priceSnapshot.data;
                        return ListTile(
                          leading: const Icon(Icons.trending_up),
                          title: Text(symbol),
                          subtitle: Text(
                            price != null ? '\$${price.toStringAsFixed(2)}' : 'Loading...',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeFromWatchlist(symbol),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
