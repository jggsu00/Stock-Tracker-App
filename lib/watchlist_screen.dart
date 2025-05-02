import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WATCHLIST")),
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

          return ListView.builder(
            itemCount: symbols.length,
            itemBuilder: (context, index) {
              final symbol = symbols[index];
              return ListTile(
                leading: const Icon(Icons.star),
                title: Text(symbol),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _removeFromWatchlist(symbol);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$symbol removed')));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
