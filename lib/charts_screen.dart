import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

const String finnhubApiKey = 'd0ag111r01qm3l9l6gh0d0ag111r01qm3l9l6ghg';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final TextEditingController _symbolController = TextEditingController();
  Map<String, dynamic>? _quoteData;
  bool _loading = false;
  String _error = '';

  Future<void> fetchQuoteData(String symbol) async {
    setState(() {
      _loading = true;
      _error = '';
      _quoteData = null;
    });

    final url = Uri.parse(
        'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$finnhubApiKey');
    final response = await http.get(url);

    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['c'] != null && data['c'] > 0) {
        setState(() {
          _quoteData = data;
        });
      } else {
        setState(() {
          _error = 'No data found for $symbol';
        });
      }
    } else {
      setState(() {
        _error = 'Failed to load data';
      });
    }

    setState(() {
      _loading = false;
    });
  }

  Widget buildQuoteChart() {
    final double current = _quoteData!['c'];
    final double high = _quoteData!['h'];
    final double low = _quoteData!['l'];
    final double open = _quoteData!['o'];
    final double prevClose = _quoteData!['pc'];

    final labels = ['Open', 'Low', 'Current', 'High', 'Prev'];
    final values = [open, low, current, high, prevClose];
    final maxY = (values.reduce((a, b) => a > b ? a : b)) * 1.1;

    return Card(
      margin: const EdgeInsets.only(top: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              barGroups: List.generate(values.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: values[index],
                      width: 20,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.grey[200],
                      ),
                    )
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, _) {
                      int i = value.toInt();
                      return SideTitleWidget(
                        axisSide: AxisSide.bottom,
                        child: Text(
                            labels[i], style: const TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: (maxY / 5).ceilToDouble(),
                  ),
                ),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        title: const Text(
          "STOCK CHARTS",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _symbolController,
                    decoration: const InputDecoration(
                      labelText: "Search Stock Symbol",
                      labelStyle: TextStyle(color: Colors.black)
                    ),
                    onSubmitted: (value) {
                      if (value
                          .trim()
                          .isNotEmpty) {
                        fetchQuoteData(value.trim().toUpperCase());
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black,),
                  onPressed: () {
                    final symbol = _symbolController.text.trim().toUpperCase();
                    if (symbol.isNotEmpty) {
                      fetchQuoteData(symbol);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(
                child: Text(_error, style: const TextStyle(color: Colors.red)))
                : _quoteData != null
                ? buildQuoteChart()
                : const Center(child: Text("Enter a symbol to view chart")),
          ),
        ],
      ),
    );
  }
}