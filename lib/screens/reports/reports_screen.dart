import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
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
          _buildCustomTabBar(),
          const SizedBox(height: 32),
          _buildFilterBar(),
          const SizedBox(height: 40),
          _getActiveTabContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        return isNarrow
            ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 24),
                _buildHeaderActions(),
              ],
            )
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildHeaderInfo(), _buildHeaderActions()],
            );
      },
    );
  }

  Widget _buildHeaderInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'View and analyze business data insights.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildExportButton(
          'Export PDF',
          Icons.picture_as_pdf_outlined,
          Colors.red[400]!,
        ),
        const SizedBox(width: 12),
        _buildExportButton(
          'Export Excel',
          Icons.table_view_outlined,
          Colors.green[600]!,
        ),
      ],
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    _buildTabItem(0, 'Sales'),
                    _buildTabItem(1, 'Customer'),
                  ],
                ),
                Row(
                  children: [
                    _buildTabItem(2, 'Payment'),
                    _buildTabItem(3, 'Work'),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              _buildTabItem(0, 'Sales Report'),
              _buildTabItem(1, 'Customer Report'),
              _buildTabItem(2, 'Payment Report'),
              _buildTabItem(3, 'Daily Work'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    bool isSelected = _tabController.index == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1000;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child:
              isNarrow
                  ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterItem(
                              'Date Range',
                              '01 Apr - 10 Apr',
                              Icons.calendar_today_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterItem(
                              'Customer',
                              'All Customers',
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFilterItem(
                              'City',
                              'All Cities',
                              Icons.location_on_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildResetButton(),
                          const SizedBox(width: 16),
                          _buildApplyButton(),
                        ],
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      _buildFilterItem(
                        'Date Range',
                        '01 Apr - 10 Apr',
                        Icons.calendar_today_outlined,
                      ),
                      const SizedBox(width: 24),
                      _buildFilterItem(
                        'Customer',
                        'All Customers',
                        Icons.person_outline,
                      ),
                      const SizedBox(width: 24),
                      _buildFilterItem(
                        'City',
                        'All Cities',
                        Icons.location_on_outlined,
                      ),
                      const Spacer(),
                      _buildResetButton(),
                      const SizedBox(width: 16),
                      _buildApplyButton(),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildResetButton() {
    return TextButton(
      onPressed: () {},
      child: const Text(
        'Reset',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text(
        'Apply Filters',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilterItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getActiveTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildSalesReport();
      case 1:
        return _buildCustomerReport();
      case 2:
        return _buildPaymentReport();
      case 3:
        return _buildDailyWorkReport();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- SALES REPORT TAB ---
  Widget _buildSalesReport() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return Column(
          children: [
            if (isNarrow)
              Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Sales',
                        '₹1,24,500',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Total Orders',
                        '42',
                        Icons.shopping_bag_outlined,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Avg. Sale Value',
                        '₹2,964',
                        Icons.analytics_outlined,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  _buildStatCard(
                    'Total Sales',
                    '₹1,24,500',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'Total Orders',
                    '42',
                    Icons.shopping_bag_outlined,
                    Colors.orange,
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'Avg. Sale Value',
                    '₹2,964',
                    Icons.analytics_outlined,
                    Colors.purple,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            _buildChartCard(
              'Sales Trend',
              'Daily sales performance over the selected period',
            ),
            const SizedBox(height: 32),
            _buildReportTable([
              ['Date', 'Customer', 'Number Sold', 'Amount'],
              ['10 Apr 2026', 'Rajesh Kumar', '98765 43210', '₹12,000'],
              ['09 Apr 2026', 'Amit Shah', '88888 77777', '₹45,000'],
              ['08 Apr 2026', 'Suresh Patel', '99112 23344', '₹8,500'],
            ]),
          ],
        );
      },
    );
  }

  // --- CUSTOMER REPORT TAB ---
  Widget _buildCustomerReport() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return Column(
          children: [
            if (isNarrow)
              Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Customers',
                        '1,240',
                        Icons.people_outline,
                        Colors.indigo,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'New This Month',
                        '+142',
                        Icons.person_add_outlined,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Active Customers',
                        '856',
                        Icons.check_circle_outline,
                        Colors.teal,
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  _buildStatCard(
                    'Total Customers',
                    '1,240',
                    Icons.people_outline,
                    Colors.indigo,
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'New This Month',
                    '+142',
                    Icons.person_add_outlined,
                    Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'Active Customers',
                    '856',
                    Icons.check_circle_outline,
                    Colors.teal,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            _buildReportTable([
              ['Customer Name', 'City', 'Total Purchases', 'Total Amount'],
              ['Rajesh Kumar', 'Surat', '3', '₹24,000'],
              ['Amit Shah', 'Ahmedabad', '1', '₹45,000'],
              ['Suresh Patel', 'Rajkot', '5', '₹18,500'],
            ]),
          ],
        );
      },
    );
  }

  // --- PAYMENT REPORT TAB ---
  Widget _buildPaymentReport() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        return Column(
          children: [
            if (isNarrow)
              Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        'Total Payments',
                        '₹4,85,000',
                        Icons.payments_outlined,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Paid Amount',
                        '₹3,20,000',
                        Icons.check_circle_outlined,
                        AppColors.statusAvailable,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Pending Amount',
                        '₹1,65,000',
                        Icons.error_outline,
                        AppColors.statusCancelled,
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  _buildStatCard(
                    'Total Payments',
                    '₹4,85,000',
                    Icons.payments_outlined,
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'Paid Amount',
                    '₹3,20,000',
                    Icons.check_circle_outlined,
                    AppColors.statusAvailable,
                  ),
                  const SizedBox(width: 24),
                  _buildStatCard(
                    'Pending Amount',
                    '₹1,65,000',
                    Icons.error_outline,
                    AppColors.statusCancelled,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            _buildReportTable([
              ['Customer', 'Total', 'Paid', 'Remaining', 'Status'],
              ['Rajesh Kumar', '₹24,000', '₹24,000', '₹0', 'PAID'],
              ['Suresh Patel', '₹18,500', '₹10,000', '₹8,500', 'PENDING'],
              ['Amit Shah', '₹45,000', '₹15,000', '₹30,000', 'PENDING'],
            ], statusColumnIndex: 4),
          ],
        );
      },
    );
  }

  // --- DAILY WORK REPORT TAB ---
  Widget _buildDailyWorkReport() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              'Total Entries',
              '156',
              Icons.edit_note,
              Colors.blueGrey,
            ),
            const SizedBox(width: 24),
            _buildStatCard(
              'Tasks Completed',
              '142',
              Icons.task_alt,
              Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildReportTable([
          ['Date', 'Contact', 'Work Done', 'Problem', 'Solution'],
          ['10 Apr', 'Vijay Mehta', 'Numerology Analysis', 'None', 'Completed'],
          ['10 Apr', 'Kiran Shah', 'Payment Followup', 'Delayed', 'Rescheduled'],
          [
            '09 Apr',
            'Rahul Jain',
            'Number Selection',
            'VIP Choice',
            'Locked #007',
          ],
        ]),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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

  Widget _buildChartCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 40),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'Interactive Chart Visualization',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable(List<List<String>> data, {int? statusColumnIndex}) {
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: data[0].asMap().entries.map((entry) {
                  return Expanded(
                    flex: entry.key == 1 ? 2 : 1, // Give more space to name
                    child: Text(
                      entry.value.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Table Body
            ...List.generate(data.length - 1, (index) {
              final row = data[index + 1];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Row(
                  children: List.generate(row.length, (cellIndex) {
                    final text = row[cellIndex];
                    bool isStatus = statusColumnIndex == cellIndex;
                    final child =
                        isStatus
                            ? _buildStatusBadge(text)
                            : Text(
                              text,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                    return Expanded(
                      flex: cellIndex == 1 ? 2 : 1,
                      child: child,
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color =
        status == 'PAID'
            ? AppColors.statusAvailable
            : AppColors.statusCancelled;
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
