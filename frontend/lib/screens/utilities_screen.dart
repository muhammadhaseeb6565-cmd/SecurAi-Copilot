import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

class UtilitiesScreen extends StatefulWidget {
  const UtilitiesScreen({super.key});

  @override
  _UtilitiesScreenState createState() => _UtilitiesScreenState();
}

class _UtilitiesScreenState extends State<UtilitiesScreen> {
  final _inputController = TextEditingController();
  final _jwtController = TextEditingController();

  String _md5 = "";
  String _sha256 = "";
  String _sha512 = "";

  Map<String, dynamic>? _decodedJwtHeader;
  Map<String, dynamic>? _decodedJwtPayload;
  String _jwtError = "";

  void _generateHashes(String input) {
    if (input.isEmpty) {
      setState(() {
        _md5 = "";
        _sha256 = "";
        _sha512 = "";
      });
      return;
    }
    final bytes = utf8.encode(input);
    setState(() {
      _md5 = md5.convert(bytes).toString();
      _sha256 = sha256.convert(bytes).toString();
      _sha512 = sha512.convert(bytes).toString();
    });
  }

  void _decodeJwt(String token) {
    if (token.isEmpty) {
      setState(() {
        _decodedJwtHeader = null;
        _decodedJwtPayload = null;
        _jwtError = "";
      });
      return;
    }
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT format');

      String decodeBase64Url(String input) {
        String output = input.replaceAll('-', '+').replaceAll('_', '/');
        switch (output.length % 4) {
          case 0:
            break;
          case 2:
            output += '==';
            break;
          case 3:
            output += '=';
            break;
          default:
            throw Exception('Illegal base64url string!');
        }
        return utf8.decode(base64Url.decode(output));
      }

      setState(() {
        _decodedJwtHeader = jsonDecode(decodeBase64Url(parts[0]));
        _decodedJwtPayload = jsonDecode(decodeBase64Url(parts[1]));
        _jwtError = "";
      });
    } catch (e) {
      setState(() {
        _decodedJwtHeader = null;
        _decodedJwtPayload = null;
        _jwtError = "Invalid JWT Token";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            'Crypto Utilities',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.cyanAccent),
          bottom: const TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.security), text: 'Hashes'),
              Tab(icon: Icon(Icons.code), text: 'JWT Decoder'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Hashes
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _inputController,
                    onChanged: _generateHashes,
                    decoration: const InputDecoration(
                      labelText: 'Text to Hash',
                      prefixIcon: Icon(
                        Icons.text_fields,
                        color: Colors.cyanAccent,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  _buildHashResult('MD5', _md5),
                  const SizedBox(height: 16),
                  _buildHashResult('SHA-256', _sha256),
                  const SizedBox(height: 16),
                  _buildHashResult('SHA-512', _sha512),
                ],
              ),
            ),
            // Tab 2: JWT
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _jwtController,
                      onChanged: _decodeJwt,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Paste JWT Token',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (_jwtError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _jwtError,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (_decodedJwtHeader != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Header',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.black.withOpacity(0.5),
                        child: Text(
                          const JsonEncoder.withIndent(
                            '  ',
                          ).convert(_decodedJwtHeader),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Payload',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.black.withOpacity(0.5),
                        child: Text(
                          const JsonEncoder.withIndent(
                            '  ',
                          ).convert(_decodedJwtPayload),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (_decodedJwtHeader!['alg'] == 'none')
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          color: Colors.red.withOpacity(0.2),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "CRITICAL: JWT uses 'none' algorithm! This token is entirely insecure.",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHashResult(String title, String hash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hash.isEmpty ? '...' : hash,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
