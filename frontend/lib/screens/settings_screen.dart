import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedPersona = "auditor";
  String _selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    _selectedPersona = widget.prefs.getString('persona') ?? "auditor";
    _selectedLanguage = widget.prefs.getString('language') ?? "English";
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
          const SizedBox(height: 32),
          const Text("Database Connection (Mock)", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.green),
              title: const Text("Supabase Vector DB"),
              subtitle: const Text("Connected"),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          )
        ],
      ),
    );
  }
}
