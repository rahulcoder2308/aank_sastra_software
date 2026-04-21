import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class NumberInventoryScreen extends StatefulWidget {
  const NumberInventoryScreen({super.key});

  @override
  State<NumberInventoryScreen> createState() => _NumberInventoryScreenState();
}

class _NumberInventoryScreenState extends State<NumberInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = false;
  List<dynamic> _inventory = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _currentPage = 1);
        _fetchInventory();
      }
    });
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getInventory(
        page: _currentPage,
        search: _searchController.text,
        category: _selectedType,
        status: _selectedStatus,
      );

      if (response['success']) {
        setState(() {
          _inventory = response['data']['data'];
          _currentPage = response['data']['current_page'];
          _totalPages = response['data']['last_page'];
          _totalRecords = response['data']['total'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 32),

          // Action Bar
          _buildActionBar(),

          const SizedBox(height: 24),

          // Table
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_inventory.isEmpty
                        ? _buildEmptyState()
                        : _buildInventoryTable()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().user;
    final canCreate = user?.hasPermission('Numbers', 'create') ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number Inventory',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage all available and sold numbers',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (!isNarrow && canCreate)
                  ElevatedButton.icon(
                    onPressed: () => _showNumberDialog(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Number'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
            if (isNarrow && canCreate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showNumberDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Number'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              isNarrow
                  ? Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTypeFilter()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatusFilter()),
                          const SizedBox(width: 8),
                          _buildResetButton(),
                        ],
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(flex: 3, child: _buildSearchField()),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildTypeFilter()),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildStatusFilter()),
                      const SizedBox(width: 16),
                      _buildResetButton(),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search number...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return _buildFilterDropdown(
      'Type',
      ['All', 'Normal', 'VIP'],
      _selectedType,
      (v) {
        setState(() {
          _selectedType = v!;
          _currentPage = 1;
        });
        _fetchInventory();
      },
    );
  }

  Widget _buildStatusFilter() {
    return _buildFilterDropdown(
      'Status',
      ['All', 'Available', 'Sold'],
      _selectedStatus,
      (v) {
        setState(() {
          _selectedStatus = v!;
          _currentPage = 1;
        });
        _fetchInventory();
      },
    );
  }

  Widget _buildResetButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedType = 'All';
          _selectedStatus = 'All';
          _searchController.clear();
          _currentPage = 1;
        });
        _fetchInventory();
      },
      icon: const Icon(Icons.refresh),
      color: AppColors.textSecondary,
      tooltip: 'Reset Filters',
    );
  }

  Widget _buildFilterDropdown(
    String hint,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      items:
          items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildInventoryTable() {
    final user = context.watch<AuthProvider>().user;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'NUMBER',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TYPE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'SYNCER / SELF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ADDED BY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ACTIONS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            // Table Body
            Expanded(
              child: ListView.separated(
                itemCount: _inventory.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final item = _inventory[index];
                  return InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['number']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildTypeBadge(item['category']!),
                          ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'S: ₹${item['syncer_price'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'P: ₹${item['self_price'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildStatusBadge(item['status']!),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              item['added_by']?['name'] ?? 'System',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (user?.hasPermission('Numbers', 'edit') ??
                                    false)
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    color: Colors.blue,
                                    tooltip: 'Edit',
                                    onTap:
                                        () => _showNumberDialog(number: item),
                                  ),
                                if (user?.hasPermission('Numbers', 'edit') ??
                                    false)
                                  const SizedBox(width: 8),
                                if (user?.hasPermission('Numbers', 'delete') ??
                                    false)
                                  _buildActionButton(
                                    icon: Icons.delete_outline,
                                    color: AppColors.statusSold,
                                    tooltip: 'Delete',
                                    onTap: () => _showDeleteConfirmation(item),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final bool isVip = type == 'VIP';
    final Color color = isVip ? AppColors.vip : Colors.grey[600]!;
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVip) ...[
              const Icon(Icons.star, size: 12, color: AppColors.vip),
              const SizedBox(width: 4),
            ],
            Text(
              type,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isAvailable = status == 'Available';
    final Color color =
        isAvailable ? AppColors.statusAvailable : AppColors.statusSold;
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Showing ${(_currentPage - 1) * 10 + 1}-${((_currentPage - 1) * 10 + _inventory.length)} of $_totalRecords records',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 24),
          _buildPageArrow(
            Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () {
              if (_currentPage > 1) {
                setState(() => _currentPage--);
                _fetchInventory();
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPageNumber(_currentPage, active: true),
          if (_currentPage < _totalPages)
            _buildPageNumber(
              _currentPage + 1,
              onTap: () {
                setState(() => _currentPage++);
                _fetchInventory();
              },
            ),
          const SizedBox(width: 8),
          _buildPageArrow(
            Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () {
              if (_currentPage < _totalPages) {
                setState(() => _currentPage++);
                _fetchInventory();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageArrow(
    IconData icon, {
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.textPrimary : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildPageNumber(
    int number, {
    bool active = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: active ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_list_numbered_rtl_rounded,
            size: 80,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          const Text(
            'No numbers available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showNumberDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Number'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 450,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Number',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Confirm permanent deletion',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure you want to delete number ${item['number']}?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This action cannot be undone and will remove this number from your inventory permanently.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await ApiService.deleteInventoryItem(
                                      item['id'],
                                    );
                                    Navigator.pop(context);
                                    _fetchInventory();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Number ${item['number']} deleted',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Delete Record',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showNumberDialog({Map<String, dynamic>? number}) {
    showDialog(
      context: context,
      builder:
          (context) => NumberModal(
            numberData: number,
            onSave: () {
              _fetchInventory();
            },
          ),
    );
  }
}

class NumberModal extends StatefulWidget {
  final Map<String, dynamic>? numberData;
  final VoidCallback onSave;

  const NumberModal({super.key, this.numberData, required this.onSave});

  @override
  State<NumberModal> createState() => _NumberModalState();
}

class _NumberModalState extends State<NumberModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late String _selectedStatus;
  late TextEditingController _numberController;
  late TextEditingController _syncerPriceController;
  late TextEditingController _selfPriceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.numberData?['category'] ?? 'Normal';
    _selectedStatus = widget.numberData?['status'] ?? 'Available';
    _numberController = TextEditingController(
      text: widget.numberData?['number'] ?? '',
    );
    _syncerPriceController = TextEditingController(
      text: widget.numberData?['syncer_price']?.toString() ?? '',
    );
    _selfPriceController = TextEditingController(
      text: widget.numberData?['self_price']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _syncerPriceController.dispose();
    _selfPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.numberData != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_outlined
                          : Icons.format_list_numbered_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Number' : 'Add New Number',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Update inventory entry'
                            : 'Entry for inventory tracking',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('PHONE NUMBER'),
                    const SizedBox(height: 8),
                    _buildTextField(_numberController, 'e.g. 99887 76655'),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('SYNCER PRICE (₹)'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _syncerPriceController,
                                'e.g. 15000',
                                isNumeric: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('SELF PRICE (₹)'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _selfPriceController,
                                'e.g. 18000',
                                isNumeric: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CATEGORY'),
                              const SizedBox(height: 8),
                              _buildTypeDropdown(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('STATUS'),
                              const SizedBox(height: 8),
                              _buildStatusDropdown(),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isSaving
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      isEditing
                                          ? 'Save Changes'
                                          : 'Save Number',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
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

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final data = {
          'number': _numberController.text,
          'syncer_price': _syncerPriceController.text,
          'self_price': _selfPriceController.text,
          'category': _selectedType,
          'status': _selectedStatus,
        };

        if (widget.numberData != null) {
          await ApiService.updateInventoryItem(widget.numberData!['id'], data);
        } else {
          await ApiService.createInventoryItem(data);
        }

        widget.onSave();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.numberData != null
                    ? 'Number updated successfully!'
                    : 'Number added successfully!',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      items:
          ['Normal', 'VIP']
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status)),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedType = value!),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      items:
          ['Available', 'Sold']
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status)),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedStatus = value!),
    );
  }
}
