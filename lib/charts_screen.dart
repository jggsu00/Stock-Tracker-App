import 'package:flutter/material.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CHARTS")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            Text("PRICE HISTORY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Placeholder(fallbackHeight: 150), // Line chart placeholder
            SizedBox(height: 20),
            Placeholder(fallbackHeight: 150), // Bar chart placeholder
          ],
        ),
      ),
    );
  }
}
