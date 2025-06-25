// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  // State for Search Tab
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchLoading = false;
  String _searchMessage = 'Search for users by their full name.';
  Timer? _debounce;

  // State for Requests Tab
  late Future<List<Map<String, dynamic>>> _pendingRequestsFuture;

  // State for Friends Tab
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadFutures();
  }

  void _loadFutures() {
    _pendingRequestsFuture = _getPendingRequests();
    _friendsFuture = _getFriends();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Refresh data when switching to the Requests or Friends tab
      if (_tabController.index == 1 || _tabController.index == 2) {
        setState(() {
          _loadFutures();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Search Tab Logic ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 3) {
      setState(() { _searchResults = []; _searchMessage = 'Please enter at least 3 characters.'; });
      return;
    }
    setState(() { _isSearchLoading = true; _searchMessage = ''; });

    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final response = await supabase.from('profiles').select('id, full_name, email').ilike('full_name', '%$query%').not('id', 'eq', currentUserId).limit(10);
      setState(() { _searchResults = response; if (_searchResults.isEmpty) _searchMessage = 'No users found.'; });
    } catch (e) {
      setState(() { _searchMessage = 'An error occurred during search.'; });
    } finally {
      setState(() { _isSearchLoading = false; });
    }
  }

  Future<void> _sendFriendRequest(String friendId) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final userOne = currentUserId.compareTo(friendId) < 0 ? currentUserId : friendId;
      final userTwo = currentUserId.compareTo(friendId) < 0 ? friendId : currentUserId;
      await supabase.from('friendships').insert({
        'user_one_id': userOne,
        'user_two_id': userTwo,
        'status': 'pending',
        'last_action_by': currentUserId,
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!'), backgroundColor: Colors.green));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Could not send request.'), backgroundColor: Colors.red));
    }
  }

  // --- Requests and Friends Tab Logic ---
  Future<List<Map<String, dynamic>>> _getPendingRequests() async {
    return await supabase.rpc('get_pending_requests');
  }

  Future<void> _acceptRequest(String friendId) async {
    await supabase.rpc('update_friendship_status', params: {'p_friend_id': friendId, 'p_new_status': 'accepted'});
    setState(() { _loadFutures(); }); // Refresh lists
  }

  Future<void> _removeFriendship(String friendId) async {
    await supabase.rpc('remove_friendship', params: {'p_friend_id': friendId});
    setState(() { _loadFutures(); }); // Refresh lists
  }

  Future<List<Map<String, dynamic>>> _getFriends() async {
    return await supabase.rpc('get_friends');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make Scaffold transparent
      body: Container( // Wrap body in a Container for the gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0E0FF), // Very light lavender
              Color(0xFFCCEEFF), // Light sky blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.white, // White label for selected tab
              unselectedLabelColor: Colors.white70, // Lighter white for unselected
              indicatorColor: Colors.white, // White indicator
              tabs: const [
                Tab(text: 'Search'),
                Tab(text: 'Requests'),
                Tab(text: 'Friends'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchTab(),
                  _buildFutureList(
                    future: _pendingRequestsFuture,
                    emptyMessage: "No pending friend requests.",
                    itemBuilder: (user) => Card( // Wrap ListTile in Card
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(user['full_name'], style: const TextStyle(color: Colors.black87)),
                        subtitle: Text(user['email'], style: const TextStyle(color: Colors.grey)),
                        trailing: Wrap(spacing: 4, children: [
                          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _acceptRequest(user['id'])),
                          IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _removeFriendship(user['id'])),
                        ],),
                      ),
                    ),
                  ),
                  _buildFutureList(
                    future: _friendsFuture,
                    emptyMessage: "You haven't added any friends yet.",
                    itemBuilder: (user) => Card( // Wrap ListTile in Card
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(user['full_name'], style: const TextStyle(color: Colors.black87)),
                        subtitle: Text(user['email'], style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _removeFriendship(user['id'])),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by full name...',
              // Inherits overall InputDecorationTheme, but specify colors for visibility
              labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87),
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
              fillColor: Colors.white.withOpacity(0.9), // Add a subtle fill color
              filled: true,
            ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black87), // Input text color
          ),
        ),
        Expanded(
          child: _isSearchLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isNotEmpty
                  ? ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Card( // Wrap ListTile in Card
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(user['full_name'], style: const TextStyle(color: Colors.black87)),
                            subtitle: Text(user['email'], style: const TextStyle(color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              onPressed: () => _sendFriendRequest(user['id']),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(child: Text(_searchMessage, style: TextStyle(color: Colors.black54))), // Darker text
        ),
      ],
    );
  }

  Widget _buildFutureList({
    required Future<List<Map<String, dynamic>>> future,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text(emptyMessage, style: TextStyle(color: Colors.black54))); // Darker text
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}
