import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMode = 'All';
  String _selectedType = 'All';
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  List<dynamic> _payments = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
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
        _fetchPayments();
      }
    });
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getPayments(
        page: _currentPage,
        search: _searchController.text,
        mode: _selectedMode,
        type: _selectedType,
        startDate:
            _selectedDateRange?.start != null
                ? DateFormat('Y-MM-dd').format(_selectedDateRange!.start)
                : null,
        endDate:
            _selectedDateRange?.end != null
                ? DateFormat('Y-MM-dd').format(_selectedDateRange!.end)
                : null,
      );

      if (response['success']) {
        setState(() {
          _payments = response['data']['data'];
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
          _buildHeader(),
          const SizedBox(height: 32),
          _buildActionBar(),
          const SizedBox(height: 24),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_payments.isEmpty
                        ? _buildEmptyState()
                        : _buildPaymentTable()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthProvider>().user;
    final canCreate = user?.hasPermission('Payments', 'create') ?? false;

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
                      'Payments',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Track all customer payments and balances',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (!isNarrow && canCreate)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        label: const Text('Export PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Payment'),
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
              ],
            ),
            if (isNarrow && canCreate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        label: const Text('Export'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Add Payment'),
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
        final isNarrow = constraints.maxWidth < 900;

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
                          Expanded(child: _buildDateRangeSelector()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModeFilter()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTypeFilter()),
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
                      Expanded(flex: 1, child: _buildDateRangeSelector()),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildModeFilter()),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: _buildTypeFilter()),
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
        hintText: 'Search by mobile number...',
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

  Widget _buildDateRangeSelector() {
    String label = 'Date Range';
    if (_selectedDateRange != null) {
      label =
          '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}';
    }

    return InkWell(
      onTap: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
            _currentPage = 1;
          });
          _fetchPayments();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedMode,
      decoration: InputDecoration(
        hintText: 'Mode',
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
          [
            'All',
            'Cash',
            'UPI',
            'Bank',
          ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
      onChanged: (v) {
        setState(() {
          _selectedMode = v!;
          _currentPage = 1;
        });
        _fetchPayments();
      },
    );
  }

  Widget _buildTypeFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        hintText: 'Type',
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
          [
            'All',
            'New Number',
            'Report Payment',
          ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
      onChanged: (v) {
        setState(() {
          _selectedType = v!;
          _currentPage = 1;
        });
        _fetchPayments();
      },
    );
  }

  Widget _buildResetButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedMode = 'All';
          _selectedType = 'All';
          _selectedDateRange = null;
          _searchController.clear();
          _currentPage = 1;
        });
        _fetchPayments();
      },
      icon: const Icon(Icons.refresh),
      color: AppColors.textSecondary,
      tooltip: 'Reset Filters',
    );
  }

  Widget _buildPaymentTable() {
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
                      'TOTAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PAID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'PROGRESS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PROCESSED BY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
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
                itemCount: _payments.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final p = _payments[index];
                  final double total = double.parse(p['total_amount']);
                  final double paid = double.parse(p['paid_amount']);
                  final double remaining = total - paid;
                  final bool isFullyPaid = remaining <= 0;
                  final double progress = total > 0 ? (paid / total) : 0.0;
                  final DateTime date = DateTime.parse(p['payment_date']);

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p['customer_name'] ?? 'Walk-in',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  p['city'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    p['payment_type'] == 'New Number'
                                        ? Colors.purple.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p['payment_type'] ?? 'Report',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      p['payment_type'] == 'New Number'
                                          ? Colors.purple[700]
                                          : Colors.blue[700],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${p['total_amount']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${p['paid_amount']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.statusAvailable,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey[100],
                                      color:
                                          isFullyPaid
                                              ? AppColors.statusAvailable
                                              : AppColors.primary,
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${remaining.toStringAsFixed(2)} left',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isFullyPaid
                                              ? AppColors.statusAvailable
                                              : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              p['added_by']?['name'] ?? 'System',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (user?.hasPermission('Payments', 'edit') ??
                                    false)
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    color: Colors.blue,
                                    tooltip: 'Edit',
                                    onTap: () => _showPaymentDialog(payment: p),
                                  ),
                                if (user?.hasPermission('Payments', 'edit') ??
                                    false)
                                  const SizedBox(width: 8),
                                if (user?.hasPermission('Payments', 'delete') ??
                                    false)
                                  _buildActionButton(
                                    icon: Icons.delete_outline,
                                    color: AppColors.statusSold,
                                    tooltip: 'Delete',
                                    onTap: () => _showDeleteConfirmation(p),
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
            'Showing ${(_currentPage - 1) * 10 + 1}-${((_currentPage - 1) * 10 + _payments.length)} of $_totalRecords records',
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
              setState(() => _currentPage--);
              _fetchPayments();
            },
          ),
          const SizedBox(width: 8),
          _buildPageNumber(_currentPage, active: true),
          if (_currentPage < _totalPages)
            _buildPageNumber(
              _currentPage + 1,
              onTap: () {
                setState(() => _currentPage++);
                _fetchPayments();
              },
            ),
          const SizedBox(width: 8),
          _buildPageArrow(
            Icons.chevron_right,
            enabled: _currentPage < _totalPages,
            onTap: () {
              setState(() => _currentPage++);
              _fetchPayments();
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
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          const Text(
            'No payment records found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showPaymentDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment'),
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

  Future<void> _exportPdf() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.exportPayments(
        type: _selectedType,
        startDate:
            _selectedDateRange?.start != null
                ? DateFormat('Y-MM-dd').format(_selectedDateRange!.start)
                : null,
        endDate:
            _selectedDateRange?.end != null
                ? DateFormat('Y-MM-dd').format(_selectedDateRange!.end)
                : null,
      );

      if (response['success']) {
        final payments = response['data'];
        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Payment Report',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Exported on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Type: $_selectedType',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          if (_selectedDateRange != null)
                            pw.Text(
                              'Range: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} to ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Type', 'Total', 'Paid', 'Mode'],
                  data:
                      payments.map<List<dynamic>>((p) {
                        return [
                          p['payment_date'],
                          p['payment_type'] ?? 'Report',
                          'INR ${p['total_amount']}',
                          'INR ${p['paid_amount']}',
                          p['payment_mode'],
                        ];
                      }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.center,
                  },
                ),
              ];
            },
          ),
        );

        final bytes = await pdf.save();
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'Payment_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                              'Delete Payment',
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
                          'Are you sure you want to delete payment record for ${item['customer']?['mobile'] ?? 'Unknown'}?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This action cannot be undone and will remove this payment history from your records permanently.',
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
                                    await ApiService.deletePayment(item['id']);
                                    Navigator.pop(context);
                                    _fetchPayments();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Payment deleted'),
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

  void _showPaymentDialog({Map<String, dynamic>? payment}) {
    showDialog(
      context: context,
      builder:
          (context) => PaymentModal(
            paymentData: payment,
            onSave: () {
              _fetchPayments();
            },
          ),
    );
  }
}

class PaymentModal extends StatefulWidget {
  final Map<String, dynamic>? paymentData;
  final VoidCallback onSave;

  const PaymentModal({super.key, this.paymentData, required this.onSave});

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mobileController;
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _totalController;
  late TextEditingController _paidController;
  late String _selectedMode;
  late String _selectedType;
  double _remaining = 0;
  bool _isSaving = false;
  int? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(
      text: widget.paymentData?['customer']?['mobile'] ?? '',
    );
    _nameController = TextEditingController(
      text: widget.paymentData?['customer_name'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.paymentData?['city'] ?? '',
    );
    _totalController = TextEditingController(
      text: (widget.paymentData?['total_amount'] ?? 0).toString(),
    );
    _paidController = TextEditingController(
      text: (widget.paymentData?['paid_amount'] ?? 0).toString(),
    );
    _selectedMode = widget.paymentData?['payment_mode'] ?? 'Cash';
    _selectedType = widget.paymentData?['payment_type'] ?? 'Report Payment';
    _selectedCustomerId = widget.paymentData?['customer_id'];
    _updateRemaining();
  }

  void _updateRemaining() {
    final double total = double.tryParse(_totalController.text) ?? 0.0;
    final double paid = double.tryParse(_paidController.text) ?? 0.0;
    setState(() => _remaining = total - paid);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _totalController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.paymentData != null;

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
                          ? Icons.visibility_outlined
                          : Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Payment Details' : 'Add New Payment',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'View and update payment information'
                            : 'Record a customer payment transaction',
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
                      'CUSTOMER DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCustomerAutocomplete(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(_cityController, 'City'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
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
                    _buildTextField(_nameController, 'e.g. John Doe'),

                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAYMENT FOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
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
                          ),
                          items:
                              ['New Number', 'Report Payment']
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAmountField(
                            'TOTAL AMOUNT (₹)',
                            _totalController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAmountField(
                            'PAID AMOUNT (₹)',
                            _paidController,
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
                                'REMAINING BALANCE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _remaining > 0
                                          ? Colors.orange[50]
                                          : Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        _remaining > 0
                                            ? Colors.orange[200]!
                                            : Colors.green[200]!,
                                  ),
                                ),
                                child: Text(
                                  '₹${_remaining.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _remaining > 0
                                            ? Colors.orange[900]
                                            : Colors.green[900],
                                  ),
                                ),
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
                                'PAYMENT MODE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedMode,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                items:
                                    ['Cash', 'UPI', 'Bank']
                                        .map(
                                          (m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(m),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setState(() => _selectedMode = v!),
                              ),
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
                            onPressed: _isSaving ? null : _savePayment,
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
                                          ? 'Update Payment'
                                          : 'Save Payment',
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

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final data = {
          'customer_id': _selectedCustomerId,
          'customer_name': _nameController.text,
          'city': _cityController.text,
          'payment_type': _selectedType,
          'total_amount': _totalController.text,
          'paid_amount': _paidController.text,
          'payment_mode': _selectedMode,
          'payment_date':
              widget.paymentData?['payment_date'] ??
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
        };

        if (widget.paymentData != null) {
          await ApiService.updatePayment(widget.paymentData!['id'], data);
        } else {
          await ApiService.createPayment(data);
        }

        widget.onSave();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.paymentData != null
                    ? 'Payment updated successfully!'
                    : 'Payment recorded successfully!',
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
          final response = await ApiService.getCustomers(
            search: textEditingValue.text,
          );
          if (response['data'] != null) {
            final List<dynamic> data = response['data'];
            return data.map((e) => Map<String, dynamic>.from(e));
          }
        } catch (e) {
          debugPrint('Error: $e');
        }
        return const Iterable<Map<String, dynamic>>.empty();
      },
      displayStringForOption:
          (Map<String, dynamic> option) => option['mobile'] ?? '',
      onSelected: (Map<String, dynamic> selection) {
        setState(() {
          _selectedCustomerId = selection['id'];
          _mobileController.text = selection['mobile'] ?? '';
          _nameController.text = selection['name'] ?? '';
          _cityController.text = selection['city'] ?? '';
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (_mobileController.text.isNotEmpty && controller.text.isEmpty) {
          controller.text = _mobileController.text;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onFieldSubmitted: (v) => onFieldSubmitted(),
          onChanged: (value) => _mobileController.text = value,
          decoration: InputDecoration(
            hintText: 'Search or enter mobile number',
            prefixIcon: const Icon(Icons.person_outline, size: 18),
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
          ),
          validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
        );
      },
    );
  }

  Widget _buildAmountField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => _updateRemaining(),
          decoration: InputDecoration(
            hintText: '0',
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
          ),
          validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
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
      ),
      validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
    );
  }
}
