import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';
import '../utils/theme_provider.dart';
import '../models/user_model.dart';
import '../widgets/apple_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<User> _users = [];
  bool _isLoading = true;
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUsername = authService.currentUser!.username;
      
      final users = await _databaseService.getAllUsers(exceptUsername: currentUsername);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Error loading users: $e');
    }
  }
  
  Future<void> _approveUser(User user) async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    try {
      await _databaseService.approveUser(user.username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          localization.getText('user_approved').replaceAll('{username}', user.username)
        ))
      );
      _loadUsers();
    } catch (e) {
      _showErrorDialog('Error approving user: $e');
    }
  }
  
  Future<void> _deleteUser(User user) async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.getText('confirm')),
        content: Text(
          localization.getText('confirm_delete_user').replaceAll('{username}', user.username)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localization.getText('back')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.errorColor(context),
            ),
            child: Text(localization.getText('delete_user')),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      try {
        await _databaseService.deleteUser(user.username);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            localization.getText('user_deleted').replaceAll('{username}', user.username)
          ))
        );
        _loadUsers();
      } catch (e) {
        _showErrorDialog('Error deleting user: $e');
      }
    }
  }
  
  Future<void> _toggleUserRole(User user) async {
    try {
      await _databaseService.toggleUserRole(user.username);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Role changed for ${user.username}'
        ))
      );
      _loadUsers();
    } catch (e) {
      _showErrorDialog('Error changing role: $e');
    }
  }
  
  void _showErrorDialog(String message) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localization.getText('back')),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.scaffoldBackground(context),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: themeProvider.cardBackground(context),
            child: Row(
              children: [
                Text(
                  localization.getText('admin'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: themeProvider.secondaryTextColor(context),
                  ),
                ),
                const Spacer(),
                Text(
                  DateTime.now().toString().substring(0, 16),
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            color: themeProvider.cardBackground(context),
            child: TabBar(
              controller: _tabController,
              labelColor: themeProvider.primaryButtonColor(context),
              unselectedLabelColor: themeProvider.secondaryTextColor(context),
              indicatorColor: themeProvider.primaryButtonColor(context),
              tabs: const [
                Tab(text: 'Admin. Usuarios'),
                Tab(text: 'Estadisticas S.'),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // User Management Tab
                _buildUserManagementTab(),
                
                // System Stats Tab (Placeholder for now)
                _buildSystemStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserManagementTab() {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Toolbar
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor(context),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadUsers,
                      tooltip: localization.getText('refresh'),
                    ),
                  ],
                ),
              ),
              
              // User List
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 3,
                  color: themeProvider.cardBackground(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _users.isEmpty
                      ? Center(
                          child: Text(
                            'No users found',
                            style: TextStyle(
                              color: themeProvider.secondaryTextColor(context),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return _UserListItem(
                              user: user,
                              onApprove: () => _approveUser(user),
                              onDelete: () => _deleteUser(user),
                              onToggleRole: () => _toggleUserRole(user),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
  }
  
  Widget _buildSystemStatsTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 3,
        color: themeProvider.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics,
                size: 64,
                color: themeProvider.primaryButtonColor(context),
              ),
              const SizedBox(height: 16),
              Text(
                'Estadisticas del Sistema',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistema de monitorizacion avanzado -> Proximamente!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeProvider.secondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Icon(
                Icons.construction,
                size: 32,
                color: themeProvider.warningColor(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: themeProvider.warningColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onApprove;
  final VoidCallback onDelete;
  final VoidCallback onToggleRole;
  
  const _UserListItem({
    super.key,
    required this.user,
    required this.onApprove,
    required this.onDelete,
    required this.onToggleRole,
  });
  
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: themeProvider.cardBackground(context).withOpacity(0.7),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // User Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: user.isAdmin
                  ? themeProvider.warningColor(context)
                  : themeProvider.primaryButtonColor(context),
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: themeProvider.textColor(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.isAdmin
                              ? themeProvider.warningColor(context)
                              : themeProvider.primaryButtonColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.approved
                              ? themeProvider.successColor(context)
                              : themeProvider.errorColor(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.approved ? 'Approved' : 'Pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User ID: ${user.id}',
                    style: TextStyle(
                      color: themeProvider.secondaryTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                if (!user.approved)
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    color: themeProvider.successColor(context),
                    tooltip: localization.getText('approve'),
                    onPressed: onApprove,
                  ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  color: themeProvider.primaryButtonColor(context),
                  tooltip: localization.getText('toggle_role'),
                  onPressed: onToggleRole,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: themeProvider.errorColor(context),
                  tooltip: localization.getText('delete_user'),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}