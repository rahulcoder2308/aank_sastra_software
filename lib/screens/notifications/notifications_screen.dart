import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/app_colors.dart';
import '../../core/localization/language_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Window Title Bar / Drag Area
          const DragToMoveArea(
            child: SizedBox(
              height: 32,
              width: double.infinity,
            ),
          ),
          
          // Custom Header (instead of AppBar to avoid overlap)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  lp.translate('notifications'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.done_all, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Mark all as read',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionTitle('Today'),
                _buildNotificationItem(
                  icon: Icons.payment_rounded,
                  iconColor: Colors.green,
                  title: 'New Payment Received',
                  message: 'A payment of ₹5,000 has been received from Rajesh Kumar.',
                  time: '2 hours ago',
                  isUnread: true,
                ),
                _buildNotificationItem(
                  icon: Icons.person_add_rounded,
                  iconColor: AppColors.info,
                  title: 'New Customer Inquiry',
                  message: 'Suresh Mehta has inquired about Business Numerology.',
                  time: '4 hours ago',
                  isUnread: true,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Yesterday'),
                _buildNotificationItem(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warning,
                  title: 'System Maintenance',
                  message: 'The system will undergo maintenance tonight at 12:00 AM.',
                  time: 'Yesterday, 10:30 PM',
                  isUnread: false,
                ),
                _buildNotificationItem(
                  icon: Icons.auto_awesome,
                  iconColor: AppColors.goldAccent,
                  title: 'Premium Insight Ready',
                  message: 'Your analysis for "Elite Enterprises" is now available.',
                  time: 'Yesterday, 02:15 PM',
                  isUnread: false,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Earlier this week'),
                _buildNotificationItem(
                  icon: Icons.backup_rounded,
                  iconColor: Colors.blueGrey,
                  title: 'Auto-Backup Successful',
                  message: 'The weekly system backup has been completed successfully.',
                  time: '3 days ago',
                  isUnread: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    bool isUnread = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnread ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnread ? AppColors.primary.withOpacity(0.7) : AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
