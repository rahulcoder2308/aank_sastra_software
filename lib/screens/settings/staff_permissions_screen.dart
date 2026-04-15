import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';

class StaffPermissionsScreen extends StatefulWidget {
  final int userId;
  final String staffName;
  final String staffRole;
  final List<dynamic> currentPermissions;

  const StaffPermissionsScreen({
    super.key,
    required this.userId,
    required this.staffName,
    required this.staffRole,
    required this.currentPermissions,
  });

  @override
  State<StaffPermissionsScreen> createState() => _StaffPermissionsScreenState();
}

class _StaffPermissionsScreenState extends State<StaffPermissionsScreen> {
  final List<String> _modules = [
    'Customer',
    'Inquiry',
    'Numbers',
    'Payments',
    'Reports',
    'Numerology',
    'Daily Work',
  ];

  // Map to store permissions: { Module: { 'view': true, 'create': false, ... } }
  final Map<String, Map<String, bool>> _permissions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with all modules default to false
    for (var module in _modules) {
      _permissions[module] = {
        'view': false,
        'create': false,
        'edit': false,
        'delete': false,
      };
    }

    // Apply current permissions from user data
    if (widget.staffRole == 'Admin') {
      for (var module in _modules) {
        _permissions[module] = {
          'view': true,
          'create': true,
          'edit': true,
          'delete': true,
        };
      }
    } else {
      for (var perm in widget.currentPermissions) {
        String module = perm['module'];
        if (_permissions.containsKey(module)) {
          _permissions[module]!['view'] =
              perm['can_view'] == 1 || perm['can_view'] == true;
          _permissions[module]!['create'] =
              perm['can_create'] == 1 || perm['can_create'] == true;
          _permissions[module]!['edit'] =
              perm['can_edit'] == 1 || perm['can_edit'] == true;
          _permissions[module]!['delete'] =
              perm['can_delete'] == 1 || perm['can_delete'] == true;
        }
      }
    }
  }

  void _togglePermission(String module, String action, bool? value) {
    setState(() {
      _permissions[module]![action] = value ?? false;
    });
  }

  void _toggleAll(String module, bool? value) {
    setState(() {
      _permissions[module]!['view'] = value ?? false;
      _permissions[module]!['create'] = value ?? false;
      _permissions[module]!['edit'] = value ?? false;
      _permissions[module]!['delete'] = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    final bool isEditingSelf = currentUser?.id == widget.userId;
    final bool isAdmin = widget.staffRole == 'Admin';
    final bool canEdit = !isEditingSelf && !isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Role Permissions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditingSelf)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You cannot modify your own permissions for security reasons.',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isAdmin)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text(
                          'Administrators have full access to all modules by default.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildStaffHeader(),
                const SizedBox(height: 40),
                IgnorePointer(
                  ignoring: !canEdit,
                  child: Opacity(
                    opacity: canEdit ? 1.0 : 0.8,
                    child: _buildPermissionsTable(),
                  ),
                ),
                const SizedBox(height: 40),
                if (canEdit) _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.staffName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.staffRole == 'Admin'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.staffRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.staffRole == 'Admin'
                            ? Colors.blue
                            : Colors.orange,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Access Level',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                'Custom Permissions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'MODULE NAME',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'VIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'CREATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'EDIT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'DELETE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'ALL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _modules.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, color: Colors.grey[100]),
            itemBuilder: (context, index) {
              final module = _modules[index];
              final perms = _permissions[module]!;
              final allSelected =
                  perms['view']! &&
                  perms['create']! &&
                  perms['edit']! &&
                  perms['delete']!;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Icon(
                            _getModuleIcon(module),
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            module,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(child: _buildCheckbox(module, 'view')),
                    ),
                    Expanded(
                      child: Center(child: _buildCheckbox(module, 'create')),
                    ),
                    Expanded(
                      child: Center(child: _buildCheckbox(module, 'edit')),
                    ),
                    Expanded(
                      child: Center(child: _buildCheckbox(module, 'delete')),
                    ),
                    Expanded(
                      child: Center(
                        child: Checkbox(
                          value: allSelected,
                          onChanged: (val) => _toggleAll(module, val),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String module, String action) {
    return Checkbox(
      value: _permissions[module]![action],
      onChanged: (val) => _togglePermission(module, action, val),
      activeColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  IconData _getModuleIcon(String module) {
    switch (module) {
      case 'Customer':
        return Icons.people_outline;
      case 'Inquiry':
        return Icons.record_voice_over_outlined;
      case 'Numbers':
        return Icons.grid_3x3;
      case 'Payments':
        return Icons.payments_outlined;
      case 'Reports':
        return Icons.analytics_outlined;
      case 'Numerology':
        return Icons.auto_awesome_outlined;
      case 'Daily Work':
        return Icons.today_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
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
                  : const Text(
                    'SAVE PERMISSIONS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      // Prepare permissions data for backend
      List<Map<String, dynamic>> permissionData = [];
      _permissions.forEach((module, actions) {
        permissionData.add({
          'module': module,
          'can_view': actions['view'],
          'can_create': actions['create'],
          'can_edit': actions['edit'],
          'can_delete': actions['delete'],
        });
      });

      await ApiService.updateUserPermissions(widget.userId, permissionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving permissions: $e')));
      }
    }
  }
}
