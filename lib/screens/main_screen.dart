import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/language_provider.dart';
import '../core/app_colors.dart';
import 'dashboard/dashboard_screen.dart'; // We'll rename some stuff here soon
import 'customers/customer_list_screen.dart';
import 'inquiry/inquiry_list_screen.dart';
import 'inventory/number_inventory_screen.dart';
import 'payments/payment_list_screen.dart';
import 'numerology/numerology_analysis_screen.dart';
import 'reports/reports_screen.dart';
import 'daily_work/daily_work_screen.dart';
import 'settings/settings_screen.dart';
import '../providers/auth_provider.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Window Title Bar / Drag Area
          DragToMoveArea(
            child: Container(
              height: 42,
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 80), // Space for Mac Traffic Lights
                  const Spacer(),
                  const Text(
                    'AANK SASTRA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 80),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),

                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: TopHeader(),
                      ),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardContent();
      case 1:
        return const CustomerListScreen();
      case 2:
        return const InquiryListScreen();
      case 3:
        return const NumberInventoryScreen();
      case 4:
        return const PaymentListScreen();
      case 5:
        return const ReportsScreen();
      case 6:
        return const NumerologyAnalysisScreen();
      case 7:
        return const DailyWorkScreen();
      case 8:
        return const SettingsScreen();
      default:
        final lp = context.read<LanguageProvider>();
        return Center(
          child: Text(
            '${lp.translate('dashboard')} Screen Coming Soon', // Using dashboard as fallback title key
            style: const TextStyle(
              fontSize: 24,
              color: AppColors.textSecondary,
            ),
          ),
        );
    }
  }
}

// Sidebar Component
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return Container(
      width: 260,
      color: AppColors.sidebarBackground,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AANK SASTRA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'DIGITAL ALCHEMIST',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Menu Items - Scrollable
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  0,
                  Icons.grid_view_rounded,
                  lp.translate('dashboard'),
                ),
                _buildMenuItem(
                  context,
                  1,
                  Icons.people_outline,
                  lp.translate('customers'),
                ),
                _buildMenuItem(
                  context,
                  2,
                  Icons.help_outline,
                  lp.translate('inquiry'),
                ),
                _buildMenuItem(
                  context,
                  3,
                  Icons.bar_chart_rounded,
                  lp.translate('numbers'),
                ),
                _buildMenuItem(
                  context,
                  4,
                  Icons.payment_rounded,
                  lp.translate('payments'),
                ),
                _buildMenuItem(
                  context,
                  5,
                  Icons.description_outlined,
                  lp.translate('reports'),
                ),
                _buildMenuItem(
                  context,
                  6,
                  Icons.auto_awesome_outlined,
                  lp.translate('numerology'),
                ),
                _buildMenuItem(
                  context,
                  7,
                  Icons.work_outline,
                  lp.translate('daily_work'),
                ),
                _buildMenuItem(
                  context,
                  8,
                  Icons.settings_outlined,
                  lp.translate('settings'),
                ),
                const SizedBox(height: 12),
                const Divider(indent: 24, endIndent: 24, color: Colors.black12),
                const SizedBox(height: 12),
                _buildLogoutItem(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => _showLogoutDialog(context),
        leading: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 20,
        ),
        title: Text(
          lp.translate('logout'),
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    lp.translate('logout_confirm_title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lp.translate('logout_confirm_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            lp.translate('cancel'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<AuthProvider>().logout();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            lp.translate('confirm'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
  ) {
    bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => onItemSelected(index),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
      ),
    );
  }
}
