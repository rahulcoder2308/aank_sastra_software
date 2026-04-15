import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';

class DailyWorkScreen extends StatefulWidget {
  const DailyWorkScreen({super.key});

  @override
  State<DailyWorkScreen> createState() => _DailyWorkScreenState();
}

class _DailyWorkScreenState extends State<DailyWorkScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isEmpty = false;
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _workEntries = [];

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalEntries = 0;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _fetchWork();
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      try {
        // Fallback for mock/string format: "10 Apr 2026"
        DateTime dt = DateFormat('dd MMM yyyy').parse(dateStr);
        return DateFormat('dd MMM yyyy').format(dt);
      } catch (_) {
        return dateStr; // Return as is if all parsing fails
      }
    }
  }

  Future<void> _fetchWork({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await ApiService.getDailyWork(
        page: page,
        search: _searchController.text,
        date: dateStr,
      );

      setState(() {
        _workEntries = response['data'];
        _currentPage = response['current_page'];
        _lastPage = response['last_page'];
        _totalEntries = response['total'];
        _from = response['from'] ?? 0;
        _to = response['to'] ?? 0;
        _isEmpty = _workEntries.isEmpty;
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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedDate = DateTime.now();
      _currentPage = 1;
    });
    _fetchWork();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
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
                    : (_isEmpty ? _buildEmptyState() : _buildWorkTable()),
          ),
          const SizedBox(height: 24),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return isNarrow
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 20),
                _buildAddButton(),
              ],
            )
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildTitle(), _buildAddButton()],
            );
      },
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Work',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Track daily tasks, problems, and solutions.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => _showWorkDialog(),
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Add Entry',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildActionBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              isNarrow
                  ? Column(
                    children: [
                      _buildDateFilter(),
                      const SizedBox(height: 16),
                      _buildSearchAndActions(),
                    ],
                  )
                  : Row(
                    children: [
                      _buildDateFilter(),
                      const SizedBox(width: 20),
                      Expanded(child: _buildSearchAndActions()),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildDateFilter() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
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
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
            _currentPage = 1;
          });
          _fetchWork();
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat(
                'EEE: dd MMM yyyy',
              ).format(_selectedDate).replaceAll('Today: ', ''),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndActions() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search tasks or contacts...",
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[100]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => _fetchWork(page: 1),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _resetFilters,
          tooltip: 'Reset Filters',
          icon: const Icon(
            Icons.filter_list_off,
            color: AppColors.textSecondary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.grey[50],
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'DATE / CONTACT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'WORK ACHIEVED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'PROBLEM & SOLUTION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'ACTIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Table Body
            Expanded(
              child: ListView.separated(
                itemCount: _workEntries.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final entry = _workEntries[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date & Contact
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(entry['date']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry['contact'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Work Done
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              entry['work_done'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        // Problem & Solution
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextWithStyle(
                                'Problem: ${entry['problem']}',
                                AppColors.statusCancelled,
                              ),
                              const SizedBox(height: 8),
                              _buildTextWithStyle(
                                'Solution: ${entry['solution']}',
                                AppColors.statusAvailable,
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit_outlined,
                                color: AppColors.textSecondary,
                                tooltip: 'Edit',
                                onTap: () => _showWorkDialog(entry: entry),
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete_outline,
                                color: Colors.redAccent,
                                tooltip: 'Delete',
                                onTap: () => _showDeleteConfirmation(entry),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextWithStyle(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalEntries == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return isNarrow
            ? Column(
              children: [
                Text(
                  'Showing $_from–$_to of $_totalEntries entries',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPageControls(),
              ],
            )
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing $_from–$_to of $_totalEntries entries',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                _buildPageControls(),
              ],
            );
      },
    );
  }

  Widget _buildPageControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPageButton(
          '<',
          isEnabled: _currentPage > 1,
          onTap: () => _fetchWork(page: _currentPage - 1),
        ),
        const SizedBox(width: 8),
        // Just show current page for now to keep it simple, or a few pages
        for (int i = 1; i <= _lastPage; i++) ...[
          if (i == 1 ||
              i == _lastPage ||
              (i >= _currentPage - 1 && i <= _currentPage + 1)) ...[
            _buildPageButton(
              i.toString(),
              isSelected: i == _currentPage,
              onTap: () => _fetchWork(page: i),
            ),
            const SizedBox(width: 8),
          ] else if (i == _currentPage - 2 || i == _currentPage + 2) ...[
            const Text('...', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 8),
          ],
        ],
        _buildPageButton(
          '>',
          isEnabled: _currentPage < _lastPage,
          onTap: () => _fetchWork(page: _currentPage + 1),
        ),
      ],
    );
  }

  Widget _buildPageButton(
    String label, {
    bool isSelected = false,
    bool isEnabled = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (isEnabled ? AppColors.textPrimary : Colors.grey[300]),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
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
          Icon(Icons.work_history_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            'No work entries found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your daily tasks and achievements here.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showWorkDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                              'Delete Entry',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'This action cannot be undone',
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
                          'Are you sure you want to delete the entry for ${item['contact']}?',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This record and all its details will be permanently removed from your daily work log.',
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
                                    await ApiService.deleteDailyWork(
                                      item['id'],
                                    );
                                    Navigator.pop(context);
                                    _fetchWork();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Work entry deleted'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } catch (e) {
                                    Navigator.pop(context);
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

  void _showWorkDialog({dynamic entry}) {
    showDialog(
      context: context,
      builder:
          (context) => WorkEntryModal(
            entryData: entry,
            onSave: (data) {
              _fetchWork();
            },
          ),
    );
  }
}

class WorkEntryModal extends StatefulWidget {
  final dynamic entryData;
  final Function(Map<String, dynamic>) onSave;

  const WorkEntryModal({super.key, this.entryData, required this.onSave});

  @override
  State<WorkEntryModal> createState() => _WorkEntryModalState();
}

class _WorkEntryModalState extends State<WorkEntryModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _contactController;
  late TextEditingController _workController;
  late TextEditingController _problemController;
  late TextEditingController _solutionController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text:
          widget.entryData?['date'] ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _contactController = TextEditingController(
      text: widget.entryData?['contact'] ?? '',
    );
    _workController = TextEditingController(
      text: widget.entryData?['work_done'] ?? '',
    );
    _problemController = TextEditingController(
      text: widget.entryData?['problem'] ?? '',
    );
    _solutionController = TextEditingController(
      text: widget.entryData?['solution'] ?? '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _contactController.dispose();
    _workController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entryData != null;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: screenSize.width > 800 ? 700 : screenSize.width * 0.9,
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.9),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Work Entry' : 'Add New Work Entry',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? 'Reference: ${widget.entryData?['contact']}'
                            : 'Enter daily activity details below.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 500) {
                            return Column(
                              children: [
                                _buildField(
                                  'Date',
                                  'Select Date',
                                  _dateController,
                                  icon: Icons.calendar_today,
                                ),
                                const SizedBox(height: 24),
                                _buildContactAutocomplete(),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  'Date',
                                  'Select Date',
                                  _dateController,
                                  icon: Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(child: _buildContactAutocomplete()),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        'Work Done',
                        'What was achieved today?',
                        _workController,
                        isMultiline: true,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        'Problem Encountered',
                        'Any issues or conflicts?',
                        _problemController,
                        isMultiline: true,
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        'Solution / Strategy',
                        'How was it resolved?',
                        _solutionController,
                        isMultiline: true,
                      ),
                      const SizedBox(height: 48),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                            ),
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
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  final data = {
                                    'date': _dateController.text,
                                    'contact': _contactController.text,
                                    'work_done': _workController.text,
                                    'problem': _problemController.text,
                                    'solution': _solutionController.text,
                                  };

                                  if (widget.entryData != null) {
                                    await ApiService.updateDailyWork(
                                      widget.entryData['id'],
                                      data,
                                    );
                                  } else {
                                    await ApiService.createDailyWork(data);
                                  }

                                  widget.onSave(data);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          widget.entryData != null
                                              ? 'Entry updated successfully!'
                                              : 'Entry saved successfully!',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                horizontal: 48,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isEditing ? 'Update Entry' : 'Save Entry',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Autocomplete<Map<String, dynamic>>(
          initialValue: _contactController.value,
          displayStringForOption:
              (option) => "${option['name']} (${option['mobile']})",
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            try {
              final response = await ApiService.getCustomers(
                search: textEditingValue.text,
              );
              final List<dynamic> data = response['data'] ?? [];
              return data.cast<Map<String, dynamic>>();
            } catch (e) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
          },
          onSelected: (Map<String, dynamic> selection) {
            _contactController.text =
                "${selection['name']} (${selection['mobile']})";
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Synchronize controllers
            if (_contactController.text.isNotEmpty && controller.text.isEmpty) {
              controller.text = _contactController.text;
            }
            controller.addListener(() {
              _contactController.text = controller.text;
            });

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onFieldSubmitted: (value) => onFieldSubmitted(),
              decoration: InputDecoration(
                hintText: 'Search Name or Mobile',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 400, // Fixed width for suggestions
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final dynamic option = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            option['name'][0],
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                        title: Text(
                          option['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "${option['mobile']} • ${option['city']}",
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController ctrl, {
    bool isMultiline = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: ctrl,
          maxLines: isMultiline ? 3 : 1,
          validator: (v) => v == null || v.isEmpty ? 'Field required' : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                icon != null
                    ? Icon(icon, size: 20, color: AppColors.primary)
                    : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[100]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
