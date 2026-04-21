import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  bool _isEmpty = false;

  List<dynamic> _customers = [];
  List<String> _cities = [];

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchCities(), _fetchCustomers()]);
  }

  Future<void> _fetchCities() async {
    try {
      final cities = await ApiService.getCities();
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    }
  }

  Future<void> _fetchCustomers({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      String? startDate;
      String? endDate;
      if (_selectedDateRange != null) {
        startDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final response = await ApiService.getCustomers(
        page: page,
        search: _searchController.text,
        city: _selectedCity,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _customers = response['data'];
        _currentPage = response['current_page'];
        _lastPage = response['last_page'];
        _totalRecords = response['total'];
        _from = response['from'] ?? 0;
        _to = response['to'] ?? 0;
        _isEmpty = _customers.isEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title Section
          _buildPageHeader(),

          const SizedBox(height: 32),

          // Action Bar (Filters)
          _buildActionBar(),

          const SizedBox(height: 24),

          // Main Table Area
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_isEmpty ? _buildEmptyState() : _buildCustomerTable()),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    final user = context.watch<AuthProvider>().user;
    final canCreate = user?.hasPermission('Customer', 'create') ?? false;

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
                      'Customers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage all customer records',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (!isNarrow && canCreate)
                  ElevatedButton.icon(
                    onPressed: () => _showCustomerDialog(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                  onPressed: () => _showCustomerDialog(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
        final isNarrow = constraints.maxWidth < 900;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or mobile...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: _filterInputDecoration('City'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Cities'),
                          ),
                          ..._cities.map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                            _currentPage = 1;
                          });
                          _fetchCustomers();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDateRangePicker()),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchCustomers(page: 1),
                  decoration: InputDecoration(
                    hintText: 'Search by name or mobile...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: _filterInputDecoration('City'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Cities'),
                    ),
                    ..._cities.map(
                      (city) =>
                          DropdownMenuItem(value: city, child: Text(city)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                      _currentPage = 1;
                    });
                    _fetchCustomers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildDateRangePicker()),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Filters',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _filterInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    String label = 'Date Range';
    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      label =
          '${start.day}/${start.month}/${start.year.toString().substring(2)} - ${end.day}/${end.month}/${end.year.toString().substring(2)}';
    }

    return InkWell(
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (range != null) {
          setState(() {
            _selectedDateRange = range;
            _currentPage = 1;
          });
          _fetchCustomers();
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
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

  void _resetFilters() {
    setState(() {
      _selectedCity = null;
      _searchController.clear();
      _selectedDateRange = null;
      _currentPage = 1;
    });
    _fetchCustomers();
  }

  Widget _buildCustomerTable() {
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'CUSTOMER ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Text(
                      'CITY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'MOBILE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'ACTIONS',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView.separated(
                itemCount: _customers.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final customer = _customers[index];
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
                            flex: 2,
                            child: Text(
                              customer['customer_code'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Text(
                              customer['city'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              customer['mobile'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              customer['date'] ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (user?.hasPermission('Customer', 'edit') ??
                                    false)
                                  _buildActionButton(
                                    icon: Icons.edit_outlined,
                                    color: Colors.blue,
                                    tooltip: 'Edit',
                                    onTap:
                                        () => _showCustomerDialog(
                                          customer: customer,
                                        ),
                                  ),
                                if (user?.hasPermission('Customer', 'edit') ??
                                    false)
                                  const SizedBox(width: 8),
                                if (user?.hasPermission('Customer', 'delete') ??
                                    false)
                                  _buildActionButton(
                                    icon: Icons.delete_outline,
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                    onTap:
                                        () => _showDeleteConfirmation(customer),
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
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalRecords == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Showing $_from-$_to of $_totalRecords records',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 24),
          _buildPageButton(
            Icons.chevron_left,
            enabled: _currentPage > 1,
            onTap: () => _fetchCustomers(page: _currentPage - 1),
          ),
          const SizedBox(width: 8),

          for (int i = 1; i <= _lastPage; i++) ...[
            if (i == 1 ||
                i == _lastPage ||
                (i >= _currentPage - 1 && i <= _currentPage + 1)) ...[
              _buildPageNumber(
                i,
                active: i == _currentPage,
                onTap: () => _fetchCustomers(page: i),
              ),
            ] else if (i == _currentPage - 2 || i == _currentPage + 2) ...[
              const Text('...', style: TextStyle(color: Colors.grey)),
            ],
          ],

          const SizedBox(width: 8),
          _buildPageButton(
            Icons.chevron_right,
            enabled: _currentPage < _lastPage,
            onTap: () => _fetchCustomers(page: _currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(
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
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
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
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 13,
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
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No customers found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by adding your first customer to the records.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCustomerDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(dynamic customer) {
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
                              'Delete Customer',
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
                          'Are you sure you want to delete ${customer['mobile']}?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This action cannot be undone and will remove all associated records for this customer.',
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
                                    await ApiService.deleteCustomer(
                                      customer['id'] as int,
                                    );
                                    Navigator.pop(context);
                                    _loadInitialData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${customer['mobile']} deleted',
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

  void _showCustomerDialog({dynamic customer}) {
    final isEditing = customer != null;
    final formKey = GlobalKey<FormState>();
    String mobile = customer?['mobile'] ?? '';
    String initialDate =
        customer?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Ensure initial city is valid
    String city =
        customer?['city'] ?? (_cities.isNotEmpty ? _cities.first : 'Mumbai');
    if (!_cities.contains(city) && _cities.isNotEmpty) {
      if (!isEditing) city = _cities.first;
    }

    String newCity = '';
    bool isAddingNewCity = false;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                  // Dialog Header
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
                                ? Icons.edit_outlined
                                : Icons.person_add_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Customer' : 'Add New Customer',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Update customer details'
                                  : 'Create a new customer record',
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
                      key: formKey,
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
                          TextFormField(
                            initialValue: mobile,
                            decoration: _dialogInputDecoration(
                              'e.g. +91 98765 43210',
                              Icons.phone_outlined,
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Please enter mobile'
                                        : null,
                            onChanged: (v) => mobile = v,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'CITY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (context, setDialogState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: isAddingNewCity ? 'ADD_NEW' : city,
                                    decoration: _dialogInputDecoration(
                                      'Select city',
                                      Icons.location_on_outlined,
                                    ),
                                    items: [
                                      if (city.isNotEmpty &&
                                          !_cities.contains(city))
                                        DropdownMenuItem(
                                          value: city,
                                          child: Text(city),
                                        ),
                                      ..._cities.map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ),
                                      ),
                                      const DropdownMenuItem(
                                        value: 'ADD_NEW',
                                        child: Text(
                                          '+ Add New City',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      setDialogState(() {
                                        if (v == 'ADD_NEW') {
                                          isAddingNewCity = true;
                                        } else {
                                          isAddingNewCity = false;
                                          city = v!;
                                        }
                                      });
                                    },
                                  ),
                                  if (isAddingNewCity) ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      decoration: _dialogInputDecoration(
                                        'Enter new city name',
                                        Icons.add_location_alt_outlined,
                                      ),
                                      validator: (v) {
                                        if (isAddingNewCity &&
                                            (v == null || v.isEmpty)) {
                                          return 'Please enter city name';
                                        }
                                        return null;
                                      },
                                      onChanged: (v) => newCity = v,
                                    ),
                                  ],
                                ],
                              );
                            },
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
                                    if (formKey.currentState!.validate()) {
                                      try {
                                        String finalCity =
                                            isAddingNewCity ? newCity : city;
                                        final data = {
                                          'mobile': mobile,
                                          'city': finalCity,
                                          'date': initialDate,
                                        };

                                        if (isEditing) {
                                          await ApiService.updateCustomer(
                                            customer['id'] as int,
                                            data,
                                          );
                                        } else {
                                          await ApiService.createCustomer(data);
                                        }

                                        _loadInitialData();
                                        if (mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isEditing
                                                    ? 'Customer updated successfully!'
                                                    : 'Customer added successfully!',
                                              ),
                                              backgroundColor:
                                                  AppColors.primary,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isEditing
                                        ? 'Save Changes'
                                        : 'Create Record',
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
          ),
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}
