import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShareRide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ShareRide - Wspólne przejazdy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _apiStatus = 'Nie połączono';
  String _apiMessage = '';
  bool _isLoading = false;

  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
      _apiStatus = 'Łączenie...';
    });

    try {
      final response = await ApiService.getHealth();
      setState(() {
        _apiStatus = 'Połączono!';
        _apiMessage = 'Status: ${response['status']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Błąd połączenia';
        _apiMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _getRootMessage() async {
    setState(() {
      _isLoading = true;
      _apiMessage = 'Pobieranie danych...';
    });

    try {
      final response = await ApiService.getRoot();
      setState(() {
        _apiStatus = 'Sukces!';
        _apiMessage = '${response['message']}\nStatus: ${response['status']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Błąd';
        _apiMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestData() async {
    setState(() {
      _isLoading = true;
      _apiMessage = 'Wysyłanie danych...';
    });

    try {
      final response = await ApiService.postData({
        'name': 'ShareRide',
        'action': 'test',
        'timestamp': DateTime.now().toIso8601String(),
      });
      setState(() {
        _apiStatus = 'Dane wysłane!';
        _apiMessage = '${response['message']}\nStatus: ${response['status']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Błąd';
        _apiMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Witaj w ShareRide!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aplikacja do wspólnych przejazdów',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              // Status połączenia z API
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Status API: $_apiStatus',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_apiMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _apiMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (_isLoading) ...[
                        const SizedBox(height: 10),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Przyciski do testowania API
              ElevatedButton(
                onPressed: _isLoading ? null : _checkHealth,
                child: const Text('Sprawdź status API'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _isLoading ? null : _getRootMessage,
                child: const Text('Pobierz wiadomość'),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: _isLoading ? null : _sendTestData,
                child: const Text('Wyślij testowe dane'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

