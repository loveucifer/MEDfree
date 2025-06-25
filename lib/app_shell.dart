// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/friends_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ProgressScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Progress';
      case 2:
        return 'Friends';
      case 3:
        return 'Profile';
      default:
        return 'MEDfree';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The scaffold background should be transparent to let the body of the child screen show through
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true, // Crucial to allow body content to extend under the transparent AppBar
      appBar: AppBar(
        title: ShaderMask( // Apply gradient to text
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFFEDE7F6), // Top left (white-ish)
                Color(0xFF673AB7), // Bottom right (deep purple)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            _getPageTitle(_selectedIndex),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white, // This color will be masked by the shader
            ),
          ),
        ),
        // Make the AppBar transparent to let the flexibleSpace gradient show through
        backgroundColor: Colors.transparent,
        elevation: 0, // No shadow
        foregroundColor: Colors.white, // Default icon/text color for app bar
        flexibleSpace: Container( // This container will provide the gradient background for the AppBar
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFEDE7F6), // Top left (white-ish)
                Color(0xFFD1C4E9), // Light purple
                Color(0xFF9575CD), // Medium purple
                Color(0xFF673AB7), // Bottom right (deep purple)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined), // Inherits foregroundColor (white)
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
            tooltip: 'Settings & Reminders',
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Inherits foregroundColor (white)
            onPressed: () => Supabase.instance.client.auth.signOut(),
            tooltip: 'Sign Out'
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, // MediumPurple
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}
