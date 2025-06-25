// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart'; // Import for theme colors
import 'screens/home_screen.dart'; // <-- THIS IMPORT IS CRITICAL
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/friends_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // NEW METHOD: Define the pages list inside the state.
  // This is a more standard pattern and can be more robust with Flutter's build and state system.
  final List<Widget> _pages = [
    const HomeScreen(),
    const ProgressScreen(),
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Returns the title for the current page.
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
      // The Scaffold must be transparent to allow the Container's gradient to show.
      backgroundColor: Colors.transparent,
      // This allows the body content (the gradient) to extend behind the AppBar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // The title is now a simple Text widget styled to be white.
        title: Text(
          _getPageTitle(_selectedIndex),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        // A transparent background makes the body's gradient visible.
        backgroundColor: Colors.transparent,
        elevation: 0, // No shadow for a cleaner look.
        foregroundColor: Colors.white, // Sets the color for icons and text.
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
            tooltip: 'Settings & Reminders',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      // The body of the Scaffold is a Container that provides the gradient background.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MEDfreeApp.primaryColor,
              MEDfreeApp.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // IndexedStack efficiently switches between pages without losing their state.
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible.
        backgroundColor: Colors.white,
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
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}
