import 'package:flutter/cupertino.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../utils/app_utils.dart';
import '../database/database_service.dart';
import 'activity_tracking_screen.dart';
import 'activity_history_screen.dart';

/// Home Screen - Main dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ActivityService _activityService = ActivityService();
  Map<String, dynamic> _weeklyStats = {};
  int _totalActivities = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _weeklyStats = _activityService.getWeeklyStats();
      _totalActivities = DatabaseService.getActivitiesCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Trak'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              _buildGreeting(),
              const SizedBox(height: 24),

              // Quick Stats
              _buildQuickStats(),
              const SizedBox(height: 24),

              // Start Activity Button
              _buildStartButton(),
              const SizedBox(height: 24),

              // Weekly Summary
              _buildWeeklySummary(),
              const SizedBox(height: 24),

              // Recent Activities
              _buildRecentActivities(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppUtils.getGreeting(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready for your next run?',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: CupertinoIcons.flame_fill,
            iconColor: CupertinoColors.systemOrange,
            value: _totalActivities.toString(),
            label: 'Activities',
          ),
          Container(
            width: 1,
            height: 40,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _buildStatItem(
            icon: CupertinoIcons.map_fill,
            iconColor: CupertinoColors.systemGreen,
            value: AppUtils.formatDistanceKm(
              _weeklyStats['totalDistance'] ?? 0,
            ),
            label: 'km this week',
          ),
          Container(
            width: 1,
            height: 40,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          _buildStatItem(
            icon: CupertinoIcons.timer,
            iconColor: CupertinoColors.systemBlue,
            value: AppUtils.formatDuration(
              _weeklyStats['totalDuration'] ?? 0,
            ),
            label: 'Total time',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startActivity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              CupertinoColors.systemOrange,
              CupertinoColors.systemRed,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemOrange.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(
              CupertinoIcons.play_fill,
              color: CupertinoColors.white,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Start Activity',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tap to begin your run',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeeklyStat(
                label: 'Activities',
                value: '${_weeklyStats['totalActivities'] ?? 0}',
              ),
              _buildWeeklyStat(
                label: 'Distance',
                value: '${(_weeklyStats['totalDistanceKm'] ?? 0).toStringAsFixed(1)} km',
              ),
              _buildWeeklyStat(
                label: 'Time',
                value: AppUtils.formatDuration(_weeklyStats['totalDuration'] ?? 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStat({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    final activities = _activityService.getRecentActivities();
    final displayActivities = activities.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const ActivityHistoryScreen(),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.sportscourt,
                    size: 48,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No activities yet',
                    style: TextStyle(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start your first run!',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...displayActivities.map((activity) => _buildActivityCard(activity)),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.sportscourt,
              color: CupertinoColors.systemOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityTypeString,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppUtils.formatDate(activity.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${activity.distanceKm.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activity.formattedDuration,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activity.formattedPace,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startActivity() async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => const ActivityTrackingScreen(),
      ),
    );

    if (result == true) {
      _loadStats();
    }
  }
}
