import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'network_map_screen.dart';
import 'training_screen.dart';
import 'cve_feed_screen.dart';
import 'utilities_screen.dart';
import '../main.dart';

class MainShell extends StatefulWidget {
  final SharedPreferences prefs;

  const MainShell({super.key, required this.prefs});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 1; // Default to Copilot Chat
  String _activeChatThreadId = "default";

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      const DashboardScreen(),
      ChatScreen(
        prefs: widget.prefs, 
        threadId: _activeChatThreadId,
        key: ValueKey(_activeChatThreadId), // Force rebuild on thread change
      ),
      const ReportsScreen(),
      SettingsScreen(prefs: widget.prefs),
    ];
  }

  void _createNewChat() async {
    final title = "Session ${DateTime.now().hour}:${DateTime.now().minute}";
    try {
      final response = await supabase.from('chat_sessions').insert({
        'title': title,
        'user_id': supabase.auth.currentUser!.id,
      }).select().single();
      
      setState(() {
        _activeChatThreadId = response['id'];
        _currentIndex = 1;
        _initScreens();
      });
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error creating chat: $e")));
    }
  }

  void _loadChat(String threadId) {
    setState(() {
      _activeChatThreadId = threadId;
      _currentIndex = 1;
      _initScreens();
    });
    Navigator.pop(context);
  }

  Future<List<Map<String, dynamic>>> _fetchSessions() async {
    final response = await supabase
        .from('chat_sessions')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.security, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'SecurAI Copilot',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_comment),
            title: const Text('New Chat'),
            onTap: _createNewChat,
          ),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.cyanAccent),
            title: const Text('Live Zero-Day Feed'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CveFeedScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.cyanAccent),
            title: const Text('Crypto Utilities'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UtilitiesScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: const Text('Network Architecture'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NetworkMapScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('DevSecOps Training'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainingScreen()));
            },
          ),
          const Divider(),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchSessions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return const Padding(padding: EdgeInsets.all(16.0), child: Text("Error loading chats", style: TextStyle(color: Colors.red)));
              }
              final threads = snapshot.data ?? [];
              if (threads.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No previous chats", style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: threads.map((session) {
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(session['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _loadChat(session['id']),
                    selected: _activeChatThreadId == session['id'],
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(), // Available across all tabs
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Copilot',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
