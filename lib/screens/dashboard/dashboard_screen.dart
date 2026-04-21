import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    // Silently refresh user profile so permission changes by Admin
    // are reflected immediately without requiring a re-login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().refreshProfile();
      }
    });
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDashboardStats();
      if (response['success']) {
        setState(() => _dashboardData = response['data']);
      }
    } catch (e) {
      debugPrint('Dashboard Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _dashboardData?['summary'];
    final distribution = _dashboardData?['distribution'];
    final recentActivity = _dashboardData?['recent_activity'] as List<dynamic>?;
    final revenueStats = _dashboardData?['revenue_growth'] as List<dynamic>?;

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Executive Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Transforming numbers into strategic destiny.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SummaryGrid(summary: summary),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      RevenueGrowthChart(data: revenueStats),
                      const SizedBox(height: 24),
                      ActivityDistribution(distribution: distribution),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: RevenueGrowthChart(data: revenueStats),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: ActivityDistribution(distribution: distribution),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            RecentActivityTable(activities: recentActivity),
          ],
        ),
      ),
    );
  }
}
// Fixing the build logic above - wait, I'll rewrite the whole file for better consistency

class TopHeader extends StatelessWidget {
  const TopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Row(
      children: [
        const Spacer(),
        // Profile
        InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      user?.name ?? 'Guest User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.role.toUpperCase() ?? 'ANALIZER',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SummaryGrid extends StatelessWidget {
  final Map<String, dynamic>? summary;
  const SummaryGrid({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildGridItem(
              SummaryCard(
                label: 'TOTAL CUSTOMERS',
                value: summary?['total_customers'] ?? '0',
                change: '+100%',
                icon: Icons.people_outline,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 16),
            _buildGridItem(
              SummaryCard(
                label: 'TOTAL SALES',
                value: summary?['total_sales'] ?? '₹0',
                change: '+100%',
                icon: Icons.shopping_bag_outlined,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 16),
            _buildGridItem(
              SummaryCard(
                label: 'PENDING PAYMENTS',
                value: summary?['pending_payments'] ?? '₹0',
                change: 'Current',
                icon: Icons.pending_actions_outlined,
                isPositive: false,
              ),
            ),
            const SizedBox(width: 16),
            _buildGridItem(
              SummaryCard(
                label: 'AVAILABLE NUMBERS',
                value: summary?['available_numbers'] ?? '0',
                change: 'Stable',
                icon: Icons.numbers_outlined,
                isNeutral: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(Widget child, {double width = 220}) {
    return SizedBox(width: width, child: child);
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final bool isPositive;
  final bool isNeutral;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    this.isPositive = true,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isNeutral
                          ? Colors.blue[50]
                          : (isPositive ? Colors.green[50] : Colors.red[50]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color:
                        isNeutral
                            ? Colors.blue
                            : (isPositive ? Colors.green : Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class RevenueGrowthChart extends StatelessWidget {
  final List<dynamic>? data;
  const RevenueGrowthChart({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Growth',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Recent revenue collection analysis',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 200,
            width: double.infinity,
            child:
                data == null || data!.isEmpty
                    ? const Center(child: Text('Not enough data'))
                    : CustomPaint(painter: ChartPainter(data: data!)),
          ),
          if (data != null && data!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    data!
                        .map(
                          (e) => Text(
                            e['month'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class ActivityDistribution extends StatelessWidget {
  final Map<String, dynamic>? distribution;
  const ActivityDistribution({super.key, this.distribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildProgressRow(
            'Numerology Reports',
            (distribution?['numerology'] ?? 0) / 100,
            AppColors.primary,
          ),
          const SizedBox(height: 20),
          _buildProgressRow(
            'Number Sales',
            (distribution?['number_sales'] ?? 0) / 100,
            Colors.blue[900]!,
          ),
          const SizedBox(height: 20),
          _buildProgressRow(
            'Inquiries',
            (distribution?['inquiries'] ?? 0) / 100,
            AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<dynamic> data;
  ChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint =
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    final path = Path();
    double maxVal = data
        .map((e) => double.tryParse(e['total'].toString()) ?? 0.0)
        .fold(0.0, (m, v) => v > m ? v : m);
    if (maxVal == 0) maxVal = 1;

    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      double val = double.tryParse(data[i]['total'].toString()) ?? 0.0;
      double x = i * stepX;
      double y = size.height - (val / maxVal * size.height * 0.8);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RecentActivityTable extends StatelessWidget {
  final List<dynamic>? activities;
  const RecentActivityTable({super.key, this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (activities == null || activities!.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No recent activity'),
              ),
            )
          else
            Column(
              children: [
                _buildTableHeader(),
                const Divider(),
                ...activities!.map(
                  (a) => _buildTableRow(
                    a['id']?.toString() ?? 'N/A',
                    a['customer']?.toString() ?? 'Unknown',
                    a['type']?.toString() ?? 'Record',
                    a['amount']?.toString() ?? '₹0',
                    a['status']?.toString() ?? 'Pending',
                    a['color'] == 'green'
                        ? Colors.green
                        : (a['color'] == 'blue' ? Colors.blue : Colors.grey),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'ID',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'CUSTOMER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'TYPE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'AMOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String id,
    String customer,
    String type,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              id,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              customer,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              type,
              style: TextStyle(
                fontSize: 11,
                color: type == 'Payment' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
