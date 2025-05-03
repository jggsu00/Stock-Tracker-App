import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

const String finnhubApiKey = 'd0ag111r01qm3l9l6gh0d0ag111r01qm3l9l6ghg';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;
  final TextEditingController _symbolController = TextEditingController();
  String _currentSymbol = 'general';

  @override
  void initState() {
    super.initState();
    _newsFuture = fetchMarketNews(_currentSymbol);
  }

  Future<List<Map<String, dynamic>>> fetchMarketNews(String symbol) async {
    final categoryOrSymbol = symbol.isEmpty || symbol == 'general'
        ? 'general'
        : symbol.toUpperCase();
    final url = symbol == 'general'
        ? Uri.parse('https://finnhub.io/api/v1/news?category=general&token=$finnhubApiKey')
        : Uri.parse('https://finnhub.io/api/v1/company-news?symbol=$categoryOrSymbol&from=2024-12-01&to=2025-12-31&token=$finnhubApiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((e) => {
        'headline': e['headline'],
        'url': e['url'],
        'source': e['source'],
        'datetime': DateTime.fromMillisecondsSinceEpoch(e['datetime'] * 1000),
        'image': e['image'],
      }).toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Link copied")),
    );
  }

  void _searchNews() {
    setState(() {
      _currentSymbol = _symbolController.text.trim().toUpperCase();
      _newsFuture = fetchMarketNews(_currentSymbol);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MARKET NEWS")),
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
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchNews,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Failed to load news"));
                }

                final articles = snapshot.data ?? [];

                if (articles.isEmpty) {
                  return const Center(child: Text("No articles found."));
                }

                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: article['image'] != null && article['image'].toString().isNotEmpty
                            ? Image.network(article['image'], width: 60, height: 60, fit: BoxFit.cover)
                            : const Icon(Icons.article),
                        title: Text(article['headline']),
                        subtitle: Text(
                          '${article['source']} • ${timeago.format(article['datetime'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(article['url']),
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
    );
  }
}
