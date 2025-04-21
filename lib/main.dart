import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '432Hz Converter',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _youtubeController = TextEditingController();
  bool _isLoading = false;
  String _status = '';

  // 👇 Convert and download function
  Future<void> convertAndDownload(String youtubeUrl) async {
    setState(() {
      _isLoading = true;
      _status = 'Processing...';
    });

    final uri = Uri.parse('http://172.16.16.83:5000/convert'); // <-- Replace this with your actual backend IP

    try {
      // 🔐 Ask for storage permission only on Android
      if (Platform.isAndroid) {
        var permissionStatus = await Permission.storage.request();
        if (!permissionStatus.isGranted) {
          setState(() {
            _status = 'Storage permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      final response = await http.post(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({'url': youtubeUrl}),
      );

      if (response.statusCode == 200) {
        Directory? directory;

        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isIOS || Platform.isMacOS) {
          directory = await getApplicationDocumentsDirectory();
        } else if (Platform.isWindows || Platform.isLinux) {
          directory = await getApplicationSupportDirectory();
        } else {
          setState(() {
            _status = 'This platform is not supported for file saving.';
            _isLoading = false;
          });
          return;
        }

        final filePath = '${directory!.path}/converted_432hz.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _status = 'Download complete! Saved to: $filePath';
        });
      } else {
        setState(() {
          _status = 'Conversion failed: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("432Hz Converter")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _youtubeController,
              decoration: InputDecoration(
                labelText: 'Paste YouTube link',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Convert to 432Hz'),
              onPressed: _isLoading
                  ? null
                  : () {
                      String url = _youtubeController.text.trim();
                      if (url.isNotEmpty) {
                        convertAndDownload(url);
                      }
                    },
            ),
            SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
