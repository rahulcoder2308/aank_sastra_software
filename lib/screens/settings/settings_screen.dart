import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import 'staff_permissions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';
  List<dynamic> _usersList = [];
  bool _isUsersLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    // Initialize selected language based on current locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp = context.read<LanguageProvider>();
      setState(() {
        if (lp.currentLocale.languageCode == 'gu')
          _selectedLanguage = 'Gujarati';
        else if (lp.currentLocale.languageCode == 'hi')
          _selectedLanguage = 'Hindi';
        else
          _selectedLanguage = 'English';
      });
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _isUsersLoading = true);
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _usersList = users;
        _isUsersLoading = false;
      });
    } catch (e) {
      setState(() => _isUsersLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this user?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteUser(userId);
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),

          // 1. Language Settings
          _buildLanguageSection(),
          const SizedBox(height: 24),

          // 2. User Management
          _buildUserManagementSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final lp = context.watch<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lp.translate('settings'),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          lp.translate('settings_subtitle'),
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    final lp = context.watch<LanguageProvider>();
    return _buildCard(
      title: lp.translate('language_settings'),
      icon: Icons.language,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lp.translate('choose_language'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildLanguageOption('English', '🇺🇸'),
              const SizedBox(width: 16),
              _buildLanguageOption('Hindi', '🇮🇳'),
              const SizedBox(width: 16),
              _buildLanguageOption('Gujarati', '🇮🇳'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final lp = context.read<LanguageProvider>();
              if (_selectedLanguage == 'English') {
                lp.changeLanguage('en');
              } else if (_selectedLanguage == 'Hindi') {
                lp.changeLanguage('hi');
              } else if (_selectedLanguage == 'Gujarati') {
                lp.changeLanguage('gu');
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lp.translate('lang_saved')),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(lp.translate('apply_changes')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String lang, String flag) {
    bool isSelected = _selectedLanguage == lang;
    return InkWell(
      onTap: () => setState(() => _selectedLanguage = lang),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              lang,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    final lp = context.watch<LanguageProvider>();
    return _buildCard(
      title: lp.translate('user_management'),
      icon: Icons.people_outline,
      headerAction: ElevatedButton.icon(
        onPressed: () => _showUserModal(context),
        icon: const Icon(Icons.add, size: 20),
        label: Text(lp.translate('add_user')),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lp.translate('user_management_subtitle'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_isUsersLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _buildUserTable(),
        ],
      ),
    );
  }

  Widget _buildUserTable() {
    final lp = context.watch<LanguageProvider>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1000,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: Text(
                      lp.translate('full_name').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      lp.translate('role').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: Text(
                      lp.translate('email_username').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      lp.translate('status').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lp.translate('apply').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_usersList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  'No users found',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ..._usersList.map(
              (user) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 250,
                      child: Text(
                        user['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _buildRoleBadge(user['role'] ?? 'Staff'),
                    ),
                    SizedBox(
                      width: 250,
                      child: Text(
                        user['email'] ?? '',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: _buildStatusBadge(
                        'Active',
                      ), // Assuming all in DB are active for now
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (context, anim1, anim2) =>
                                          StaffPermissionsScreen(
                                            userId: user['id'],
                                            staffName: user['name'] ?? '',
                                            staffRole: user['role'] ?? 'Staff',
                                            currentPermissions:
                                                user['permissions'] ?? [],
                                          ),
                                  transitionsBuilder:
                                      (context, anim1, anim2, child) =>
                                          FadeTransition(
                                            opacity: anim1,
                                            child: child,
                                          ),
                                  transitionDuration: const Duration(
                                    milliseconds: 200,
                                  ),
                                ),
                              ).then((_) => _fetchUsers());
                            },
                            icon: const Icon(
                              Icons.shield_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Permissions',
                          ),
                          IconButton(
                            onPressed:
                                () => _showUserModal(context, user: user),
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Colors.blue,
                            ),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => _deleteUser(user['id']),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    bool isAdmin = role == 'Admin';
    Color color = isAdmin ? AppColors.goldAccent : AppColors.accentBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final lp = context.read<LanguageProvider>();
    String key = status.toLowerCase();
    String label = lp.translate(key);

    bool isActive = status == 'Active';
    Color color = isActive ? AppColors.success : Colors.grey;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? headerAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (headerAction != null) headerAction,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(24.0), child: child),
        ],
      ),
    );
  }

  void _showUserModal(BuildContext context, {dynamic user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormModal(user: user),
    ).then((updated) {
      if (updated == true) _fetchUsers();
    });
  }
}

class UserFormModal extends StatefulWidget {
  final dynamic user;
  const UserFormModal({super.key, this.user});

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late String _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?['name'] ?? '');
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.user?['phone'] ?? '');
    _passwordController =
        TextEditingController(); // Empty for new, or left empty for no change in edit
    _role = widget.user?['role'] ?? 'Staff';
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Email are required')),
      );
      return;
    }

    if (widget.user == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required for new user')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'role': _role,
      };

      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }

      if (widget.user != null) {
        await ApiService.updateUser(widget.user['id'], userData);
      } else {
        await ApiService.createUser(userData);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving user: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user == null ? 'Add New User' : 'Edit User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildField('Full Name', 'e.g. Rajesh Kumar', _nameController),
            const SizedBox(height: 20),
            _buildField(
              'Username / Email',
              'e.g. rajesh@aanksastra.com',
              _emailController,
            ),
            const SizedBox(height: 20),
            _buildField(
              'Phone (Optional)',
              'e.g. 9876543210',
              _phoneController,
            ),
            const SizedBox(height: 20),
            _buildField(
              'Password',
              widget.user == null
                  ? 'Enter password'
                  : 'Leave empty to keep current',
              _passwordController,
              isObscure: true,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _role,
                  items:
                      ['Admin', 'Staff']
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _role = v!),
                  decoration: _inputDecoration(),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Save User'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: _inputDecoration().copyWith(hintText: hint),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
