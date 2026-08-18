import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedPersona = "auditor";
  String _selectedLanguage = "English";
  String _selectedAiModel = "openai/gpt-oss-20b";
  bool _requireBiometrics = false;
  final TextEditingController _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPersona = widget.prefs.getString('persona') ?? "auditor";
    _selectedLanguage = widget.prefs.getString('language') ?? "English";
    _selectedAiModel = widget.prefs.getString('ai_model') ?? "openai/gpt-oss-20b";
    _requireBiometrics = widget.prefs.getBool('requireBiometrics') ?? false;
    _apiUrlController.text = widget.prefs.getString('api_base_url') ?? "https://securai-copilot.onrender.com";
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  void _exportData() {
    final allKeys = widget.prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (var key in allKeys) {
      data[key] = widget.prefs.get(key);
    }
    
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    
    Clipboard.setData(ClipboardData(text: jsonStr));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data copied to clipboard!')),
    );
  }

  void _saveLanguage(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
        widget.prefs.setString('language', value);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language updated to $value')),
      );
    }
  }

  void _saveAiModel(String? value) {
    if (value != null) {
      setState(() {
        _selectedAiModel = value;
        widget.prefs.setString('ai_model', value);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Model updated to $value')),
      );
    }
  }

  void _saveBiometrics(bool value) {
    setState(() {
      _requireBiometrics = value;
      widget.prefs.setBool('requireBiometrics', value);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? 'Biometric App Lock Enabled' : 'Biometric App Lock Disabled')),
    );
  }

  void _savePersona(String? value) {
    if (value != null) {
      setState(() {
        _selectedPersona = value;
        widget.prefs.setString('persona', value);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Persona updated to $value')),
      );
    }
  }

  void _saveApiUrl(String value) {
    widget.prefs.setString('api_base_url', value.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backend API URL updated successfully. Restart app to apply.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Security & Privacy', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Require Biometrics'),
            subtitle: const Text('Use Fingerprint/FaceID to unlock the app'),
            secondary: const Icon(Icons.fingerprint),
            value: _requireBiometrics,
            onChanged: _saveBiometrics,
          ),
          ListTile(
            title: const Text('Export My Data'),
            subtitle: const Text('Download a JSON copy of your personal settings and app data'),
            trailing: const Icon(Icons.download, color: Colors.cyanAccent),
            onTap: _exportData,
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark themes'),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            onChanged: (val) {
              themeProvider.toggleTheme(val);
            },
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('AI Model Selection', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedAiModel,
                  items: const [
                    DropdownMenuItem(value: "openai/gpt-oss-20b", child: Text("GPT-OSS 20B (Recommended)")),
                    DropdownMenuItem(value: "openai/gpt-oss-120b", child: Text("GPT-OSS 120B (Powerful)")),
                    DropdownMenuItem(value: "llama-3.3-70b-versatile", child: Text("Llama 3.3 70B")),
                    DropdownMenuItem(value: "gemma2-9b-it", child: Text("Gemma 2 9B")),
                    DropdownMenuItem(value: "mixtral-8x7b-32768", child: Text("Mixtral 8x7B")),
                  ],
                  onChanged: _saveAiModel,
                ),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('Global Language', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedLanguage,
                  items: const [
                    DropdownMenuItem(value: "English", child: Text("English")),
                    DropdownMenuItem(value: "Spanish", child: Text("Español (Spanish)")),
                    DropdownMenuItem(value: "French", child: Text("Français (French)")),
                    DropdownMenuItem(value: "Japanese", child: Text("日本語 (Japanese)")),
                    DropdownMenuItem(value: "Arabic", child: Text("العربية (Arabic)")),
                    DropdownMenuItem(value: "Urdu", child: Text("اردو (Urdu)")),
                    DropdownMenuItem(value: "Roman Urdu", child: Text("Roman Urdu")),
                  ],
                  onChanged: _saveLanguage,
                ),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('AI Copilot Persona', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text("Security Auditor"),
                  subtitle: const Text("Strict, concise, focuses purely on finding flaws."),
                  value: "auditor",
                  groupValue: _selectedPersona,
                  onChanged: (val) => _savePersona(val!),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                RadioListTile<String>(
                  title: const Text("Patient Teacher"),
                  subtitle: const Text("Explains concepts simply with context and examples."),
                  value: "teacher",
                  groupValue: _selectedPersona,
                  onChanged: (val) => _savePersona(val!),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                RadioListTile<String>(
                  title: const Text("Code Ninja"),
                  subtitle: const Text("Provides fast, secure code snippets with minimal text."),
                  value: "ninja",
                  groupValue: _selectedPersona,
                  onChanged: (val) => _savePersona(val!),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
                  const SizedBox(height: 8),
          const Text("Database Connection", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.green),
              title: const Text("Supabase PostgreSQL"),
              subtitle: const Text("Connected"),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          )
        ],
      ),
    );
  }
}
