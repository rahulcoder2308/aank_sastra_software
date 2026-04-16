import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  bool _isLoading = false;
  List<dynamic> _inquiries = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchInquiries();
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
        setState(() {
          _currentPage = 1;
        });
        _fetchInquiries();
      }
    });
  }

  Future<void> _fetchInquiries() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getInquiries(
        page: _currentPage,
        search: _searchController.text,
        status: _selectedStatus,
      );

      if (response['success']) {
        setState(() {
          _inquiries = response['data']['data'];
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
          // Page Header
          _buildHeader(),

          const SizedBox(height: 32),

          // Action Bar
          _buildActionBar(),

          const SizedBox(height: 24),

          // Inquiry Table
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_inquiries.isEmpty
                        ? _buildEmptyState()
                        : _buildInquiryTable()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().user;
    final canCreate = user?.hasPermission('Inquiry', 'create') ?? false;

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
                      'Inquiry / Booking',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage customer inquiries and conversions',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (!isNarrow && canCreate)
                  ElevatedButton.icon(
                    onPressed: () => _showInquiryDialog(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Inquiry'),
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
                  onPressed: () => _showInquiryDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Inquiry'),
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
        hintText: 'Search inquiries...',
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

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: _filterInputDecoration('Status'),
      items:
          ['All', 'New', 'Converted', 'Cancelled']
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status)),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
          _currentPage = 1;
        });
        _fetchInquiries();
      },
    );
  }

  Widget _buildResetButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedStatus = 'All';
          _searchController.clear();
          _currentPage = 1;
        });
        _fetchInquiries();
      },
      icon: const Icon(Icons.refresh),
      color: AppColors.textSecondary,
      tooltip: 'Reset Filters',
    );
  }

  InputDecoration _filterInputDecoration(String hint) {
    return InputDecoration(
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
    );
  }

  Widget _buildInquiryTable() {
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
                    flex: 1,
                    child: Text(
                      'ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'CUSTOMER',
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
                      'MOBILE',
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
                      'SELECTED #',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'PRICE',
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
                itemCount: _inquiries.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final inq = _inquiries[index];
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
                            flex: 1,
                            child: Text(
                              'INQ-${inq['id']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              inq['customer_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              inq['mobile_number'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              inq['selected_number'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '₹${inq['price']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildStatusBadge(inq['status']!),
                          ),
                           Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (user?.hasPermission('Inquiry', 'edit') ?? false)
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    color: Colors.blue,
                                    tooltip: 'Edit',
                                    onTap: () => _showInquiryDialog(inquiry: inq),
                                  ),
                                if (user?.hasPermission('Inquiry', 'edit') ?? false)
                                  const SizedBox(width: 8),
                                if (user?.hasPermission('Inquiry', 'delete') ?? false)
                                  _buildActionButton(
                                    icon: Icons.delete_outline,
                                    color: AppColors.statusCancelled,
                                    tooltip: 'Delete',
                                    onTap: () => _showDeleteConfirmation(inq),
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

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'New':
        badgeColor = AppColors.statusNew;
        break;
      case 'Converted':
        badgeColor = AppColors.statusConverted;
        break;
      case 'Cancelled':
        badgeColor = AppColors.statusCancelled;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: badgeColor,
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
            'Showing ${(_currentPage - 1) * 10 + 1}-${((_currentPage - 1) * 10 + _inquiries.length)} of $_totalRecords records',
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
                _fetchInquiries();
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
                _fetchInquiries();
              },
            ),
          const SizedBox(width: 8),
          _buildPageArrow(
            Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () {
              if (_currentPage < _totalPages) {
                setState(() => _currentPage++);
                _fetchInquiries();
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
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No inquiries found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showInquiryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Inquiry'),
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

  void _showDeleteConfirmation(Map<String, dynamic> inquiry) {
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
                              'Delete Inquiry',
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
                          'Are you sure you want to delete inquiry INQ-${inquiry['id']} for ${inquiry['customer_name']}?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This action cannot be undone and will remove this inquiry record permanently.',
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
                                    await ApiService.deleteInquiry(
                                      inquiry['id'],
                                    );
                                    Navigator.pop(context);
                                    _fetchInquiries();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Inquiry INQ-${inquiry['id']} deleted',
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

  void _showInquiryDialog({Map<String, dynamic>? inquiry}) {
    showDialog(
      context: context,
      builder:
          (context) => InquiryModal(
            inquiry: inquiry,
            onSave: () {
              _fetchInquiries();
            },
          ),
    );
  }
}

class InquiryModal extends StatefulWidget {
  final Map<String, dynamic>? inquiry;
  final VoidCallback onSave;

  const InquiryModal({super.key, this.inquiry, required this.onSave});

  @override
  State<InquiryModal> createState() => _InquiryModalState();
}

class _InquiryModalState extends State<InquiryModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedStatus;
  late TextEditingController _customerController;
  late TextEditingController _mobileController;
  late TextEditingController _numberController;
  late TextEditingController _priceController;
  bool _isSaving = false;
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.inquiry?['status'] ?? 'New';
    _customerController = TextEditingController(
      text: widget.inquiry?['customer_name'] ?? '',
    );
    _mobileController = TextEditingController(
      text: widget.inquiry?['mobile_number'] ?? '',
    );
    _numberController = TextEditingController(
      text: widget.inquiry?['selected_number'] ?? '',
    );
    _priceController = TextEditingController(
      text: widget.inquiry?['price']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    // Only dispose if we are not using Autocomplete's internal controller
    // but here we are using it for editing, so we keep it.
    _customerController.dispose();
    _mobileController.dispose();
    _numberController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.inquiry != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
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
                          : Icons.note_add_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Inquiry' : 'Add New Inquiry',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Update inquiry details'
                            : 'Record a new customer booking',
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
                    const Text(
                      'CUSTOMER NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCustomerAutocomplete(),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MOBILE NUMBER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _mobileController,
                                'e.g. +91 98765 43210',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECTED NUMBER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _numberController,
                                'e.g. 99999 54321',
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
                              const Text(
                                'PRICE (₹)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                _priceController,
                                'e.g. 45000',
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
                              const Text(
                                'STATUS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
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
                            onPressed: _isSaving ? null : _saveInquiry,
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
                                          : 'Save Inquiry',
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

  Future<void> _saveInquiry() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final data = {
          'customer_name': _customerController.text,
          'mobile_number': _mobileController.text,
          'selected_number': _numberController.text,
          'price': _priceController.text,
          'status': _selectedStatus,
        };

        if (widget.inquiry != null) {
          await ApiService.updateInquiry(widget.inquiry!['id'], data);
        } else {
          await ApiService.createInquiry(data);
        }

        widget.onSave();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.inquiry != null
                    ? 'Inquiry updated successfully!'
                    : 'Inquiry added successfully!',
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

  Widget _buildCustomerAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        try {
          setState(() => _isLoadingCustomers = true);
          final response = await ApiService.getCustomers(
            page: 1,
            search: textEditingValue.text,
          );

          if (response['data'] != null) {
            final List<dynamic> data = response['data'];
            return data.map((e) => Map<String, dynamic>.from(e));
          }
        } catch (e) {
          debugPrint('Autocomplete search error: $e');
        } finally {
          if (mounted) setState(() => _isLoadingCustomers = false);
        }

        return const Iterable<Map<String, dynamic>>.empty();
      },
      displayStringForOption: (Map<String, dynamic> option) => option['name'],
      onSelected: (Map<String, dynamic> selection) {
        setState(() {
          _customerController.text = selection['name'];
          _mobileController.text = selection['mobile'] ?? '';
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Synchronize our manual controller with Autocomplete's internal controller
        if (_customerController.text.isNotEmpty && controller.text.isEmpty) {
          controller.text = _customerController.text;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (value) => onFieldSubmitted(),
          onChanged: (value) => _customerController.text = value,
          validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
          decoration: InputDecoration(
            hintText: 'Search or enter customer name',
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon:
                _isLoadingCustomers
                    ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.person_search_outlined),
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 552, // Match modal width minus padding
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> option = options.elementAt(index);
                  return ListTile(
                    title: Text(option['name']),
                    subtitle: Text(option['mobile'] ?? 'No phone'),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
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
          ['New', 'Converted', 'Cancelled']
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status)),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedStatus = value!),
    );
  }
}
