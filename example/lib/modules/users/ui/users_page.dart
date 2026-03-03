import 'package:air_framework/air_framework.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

/// Users Page - Demonstrates fetching real data using the Adapter pattern.
///
/// Uses [UserService] (registered in [UsersModule]) which calls the
/// JSONPlaceholder API through the abstract [HttpClient] provided
/// by [DioAdapter].
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final UserService _userService;
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userService = AirDI().get<UserService>();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _userService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Users (via Adapter)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Fetching users from API...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading users',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(child: Text('No users found'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          return _buildUserCard(_users[index - 1]);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.indigo.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.power, color: Colors.indigo.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Powered by DioAdapter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    Text(
                      'Data from jsonplaceholder.typicode.com via HttpClient contract',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  '${_users.length} users',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.indigo.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Text(
            user.name.isNotEmpty ? user.name[0] : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    user.email,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${user.company} • ${user.city}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
