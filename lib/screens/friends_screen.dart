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

  // State for Requests and Friends Tabs
  late Future<List<Map<String, dynamic>>> _pendingRequestsFuture;
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadFutures(); // Initial load
  }

  /// Reloads data for the requests and friends tabs.
  void _loadFutures() {
    _pendingRequestsFuture = _getPendingRequests();
    _friendsFuture = _getFriends();
  }

  /// Refreshes data when the user switches to the Requests or Friends tab.
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
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

  // --- Search Logic ---
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) _searchUsers(query);
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() { _isSearchLoading = true; _searchMessage = ''; });
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('profiles')
          .select('id, full_name, email')
          .ilike('full_name', '%$query%')
          .not('id', 'eq', currentUserId)
          .limit(10);
      setState(() {
        _searchResults = response;
        if (_searchResults.isEmpty) _searchMessage = 'No users found.';
      });
    } catch (e) {
      setState(() { _searchMessage = 'An error occurred during search.'; });
    } finally {
      setState(() { _isSearchLoading = false; });
    }
  }

  Future<void> _sendFriendRequest(String friendId) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      // Ensure deterministic order for composite primary key
      final userOne = currentUserId.compareTo(friendId) < 0 ? currentUserId : friendId;
      final userTwo = currentUserId.compareTo(friendId) < 0 ? friendId : currentUserId;
      
      await supabase.from('friendships').insert({
        'user_one_id': userOne,
        'user_two_id': userTwo,
        'status': 'pending',
        'last_action_by': currentUserId,
      });

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!'), backgroundColor: Colors.green)
      );
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not send request. You may already have a pending request with this user.'), backgroundColor: Colors.red, duration: Duration(seconds: 5))
      );
    }
  }

  // --- Requests and Friends Logic ---
  Future<List<Map<String, dynamic>>> _getPendingRequests() async =>
      await supabase.rpc('get_pending_requests');

  Future<List<Map<String, dynamic>>> _getFriends() async =>
      await supabase.rpc('get_friends');

  Future<void> _acceptRequest(String friendId) async {
    await supabase.rpc('update_friendship_status', params: {'p_friend_id': friendId, 'p_new_status': 'accepted'});
    setState(_loadFutures); // Refresh lists
  }

  Future<void> _removeFriendship(String friendId) async {
    await supabase.rpc('remove_friendship', params: {'p_friend_id': friendId});
    setState(_loadFutures); // Refresh lists
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Styled TabBar for the gradient background
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.person_add_alt_1), text: 'Requests'),
                Tab(icon: Icon(Icons.people_alt), text: 'Friends'),
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
                    itemBuilder: (user) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(user['full_name']),
                        subtitle: Text(user['email']),
                        trailing: Wrap(spacing: 0, children: [
                          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _acceptRequest(user['id']), tooltip: 'Accept'),
                          IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent), onPressed: () => _removeFriendship(user['id']), tooltip: 'Decline'),
                        ]),
                      ),
                    ),
                  ),
                  _buildFutureList(
                    future: _friendsFuture,
                    emptyMessage: "You haven't added any friends yet.",
                    itemBuilder: (user) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(user['full_name']),
                        subtitle: Text(user['email']),
                        trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _removeFriendship(user['id']), tooltip: 'Remove Friend'),
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

  /// Builds the content for the 'Search' tab.
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
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _isSearchLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _searchResults.isNotEmpty
                  ? ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            title: Text(user['full_name']),
                            subtitle: Text(user['email']),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              onPressed: () => _sendFriendRequest(user['id']),
                              tooltip: 'Send Request',
                            ),
                          ),
                        );
                      },
                    )
                  : Center(child: Text(_searchMessage, style: const TextStyle(color: Colors.white70, fontSize: 16))),
        ),
      ],
    );
  }

  /// A generic builder for displaying lists from a Future.
  Widget _buildFutureList({
    required Future<List<Map<String, dynamic>>> future,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.white70, fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 10),
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index]),
        );
      },
    );
  }
}
