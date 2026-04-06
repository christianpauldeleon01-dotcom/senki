import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DateUtils, Colors;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../utils/app_utils.dart';
import '../theme/trak_design_system.dart';
import 'activity_detail_screen.dart';

enum DateFilter { all, today, week, month, year }

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with TickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];
  DateFilter _currentFilter = DateFilter.all;
  String _selectedActivityType = 'All';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadActivities();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
    
    themeChangeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  void _loadActivities() {
    setState(() {
      _activities = _activityService.getAllActivities();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    
    _filteredActivities = _activities.where((activity) {
      bool passesType = _selectedActivityType == 'All' || 
          activity.activityTypeString == _selectedActivityType;
      
      if (!passesType) return false;
      
      switch (_currentFilter) {
        case DateFilter.all:
          return true;
        case DateFilter.today:
          return activity.date.year == now.year && 
              activity.date.month == now.month && 
              activity.date.day == now.day;
        case DateFilter.week:
          return activity.date.isAfter(startOfWeek) || 
              activity.date.isAtSameMomentAs(startOfWeek);
        case DateFilter.month:
          return activity.date.isAfter(startOfMonth) || 
              activity.date.isAtSameMomentAs(startOfMonth);
        case DateFilter.year:
          return activity.date.isAfter(startOfYear) || 
              activity.date.isAtSameMomentAs(startOfYear);
      }
    }).toList();
    
    _filteredActivities.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  void 
  pose() {
    _animationController.dispose();
    themeChangeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: NeonColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: NeonColors.backgroundSecondary.withValues(alpha: 0.95),
        border: null,
        middle: Text(
          'Activity History',
          style: NeonTypography.headlineSmall.copyWith(
            color: NeonColors.textPrimary,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: NeonColors.primary,
                size: 24,
              ),
              Text(
                'Back',
                style: NeonTypography.bodyLarge.copyWith(
                  color: NeonColors.primary,
                ),
              ),
            ],
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showFilterSheet(),
          child: Icon(
            CupertinoIcons.slider_horizontal_3,
            color: NeonColors.primary,
            size: 24,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: _filteredActivities.isEmpty
              ? _buildEmptyState()
              : _buildActivityList(),
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: NeonColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: NeonColors.border),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NeonColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'FILTER ACTIVITIES',
                style: NeonTypography.titleLarge.copyWith(
                  color: NeonColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIME PERIOD',
                    style: NeonTypography.labelMedium.copyWith(
                      color: NeonColors.textTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVITY TYPE',
                    style: NeonTypography.labelMedium.copyWith(
                      color: NeonColors.textTertiary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityTypeChips(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('All', DateFilter.all),
      ('Today', DateFilter.today),
      ('This Week', DateFilter.week),
      ('This Month', DateFilter.month),
      ('This Year', DateFilter.year),
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final isSelected = _currentFilter == f.$2;
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentFilter = f.$2;
            });
            _applyFilters();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? NeonColors.primary : NeonColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? NeonColors.primary : NeonColors.border,
              ),
            ),
            child: Text(
              f.$1,
              style: NeonTypography.labelMedium.copyWith(
                color: isSelected ? NeonColors.background : NeonColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityTypeChips() {
    final types = ['All', 'Running', 'Cycling', 'Walking', 'Swimming'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _selectedActivityType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedActivityType = type;
            });
            _applyFilters();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? NeonColors.primary : NeonColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? NeonColors.primary : NeonColors.border,
              ),
            ),
            child: Text(
              type,
              style: NeonTypography.labelMedium.copyWith(
                color: isSelected ? NeonColors.background : NeonColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NeonColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: NeonColors.border, width: 1),
              ),
              child: Icon(
                CupertinoIcons.sportscourt,
                size: 56,
                color: NeonColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No activities yet',
              style: NeonTypography.headlineMedium.copyWith(
                color: NeonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first run to see it here',
              style: NeonTypography.bodyMedium.copyWith(
                color: NeonColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeaderSection()),
        SliverToBoxAdapter(child: _buildCalendarHeatmap()),
        SliverToBoxAdapter(child: _buildRecordsSection()),
        SliverToBoxAdapter(child: _buildStatsOverview()),
        ..._buildGroupedActivities(),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ACTIVITIES',
            style: NeonTypography.titleLarge.copyWith(
              color: NeonColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          Text(
            '${_filteredActivities.length} activities',
            style: NeonTypography.labelMedium.copyWith(
              color: NeonColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeatmap() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now).toUpperCase(),
                style: NeonTypography.labelMedium.copyWith(
                  color: NeonColors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot(0.0),
                  const SizedBox(width: 4),
                  Text(
                    'Less',
                    style: NeonTypography.labelSmall.copyWith(
                      color: NeonColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildLegendDot(0.5),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: NeonTypography.labelSmall.copyWith(
                      color: NeonColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => SizedBox(
                  width: 36,
                  child: Text(
                    d,
                    style: NeonTypography.labelSmall.copyWith(
                      color: NeonColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ))
                .toList(),
          ),
          const SizedBox(height: 4),
          _buildCalendarGrid(daysInMonth, startingWeekday),
        ],
      ),
    );
  }

  Widget _buildLegendDot(double intensity) {
    final color = intensity == 0 
        ? NeonColors.surface 
        : Color.lerp(NeonColors.surface, NeonColors.primary, intensity)!;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int startingWeekday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDays = <int, int>{};
    
    for (var activity in _activities) {
      if (activity.date.year == now.year && activity.date.month == now.month) {
        activityDays[activity.date.day] = (activityDays[activity.date.day] ?? 0) + 1;
      }
    }
    
    final maxActivities = activityDays.values.fold<int>(0, (a, b) => a > b ? a : b);
    
    final cells = <Widget>[];
    
    for (var i = 0; i < startingWeekday - 1; i++) {
      cells.add(const SizedBox(width: 36, height: 36));
    }
    
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(now.year, now.month, day);
      final count = activityDays[day] ?? 0;
      final intensity = maxActivities > 0 ? count / maxActivities : 0.0;
      final isToday = date.isAtSameMomentAs(today);
      final isFuture = date.isAfter(today);
      
      cells.add(
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isFuture 
                ? Colors.transparent 
                : (intensity == 0 
                    ? NeonColors.surface 
                    : Color.lerp(NeonColors.surface, NeonColors.primary, intensity)!),
            borderRadius: BorderRadius.circular(4),
            border: isToday 
                ? Border.all(color: NeonColors.primary, width: 2) 
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: NeonTypography.labelSmall.copyWith(
                color: isFuture 
                    ? NeonColors.textMuted 
                    : NeonColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: cells,
    );
  }

  Widget _buildRecordsSection() {
    final records = _findPersonalRecords();
    if (records.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'PERSONAL RECORDS',
            style: NeonTypography.titleLarge.copyWith(
              color: NeonColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildRecordCard(records[index]),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _findPersonalRecords() {
    final records = <MapEntry<String, String>>[];
    
    if (_activities.isEmpty) return records;
    
    double longestRun = 0;
    Activity? longestRunActivity;
    double fastestPace = double.infinity;
    Activity? fastestPaceActivity;
    int mostMinutes = 0;
    Activity? mostMinutesActivity;
    
    for (var activity in _activities) {
      if (activity.distanceMeters > longestRun) {
        longestRun = activity.distanceMeters;
        longestRunActivity = activity;
      }
      if (activity.averagePaceSecondsPerKm > 0 && 
          activity.averagePaceSecondsPerKm < fastestPace) {
        fastestPace = activity.averagePaceSecondsPerKm;
        fastestPaceActivity = activity;
      }
      if (activity.durationSeconds > mostMinutes) {
        mostMinutes = activity.durationSeconds;
        mostMinutesActivity = activity;
      }
    }
    
    if (longestRunActivity != null && longestRun > 0) {
      records.add(MapEntry(
        'Longest Run',
        '${longestRunActivity.distanceKm.toStringAsFixed(1)} km',
      ));
    }
    
    if (fastestPaceActivity != null && fastestPace < double.infinity) {
      records.add(MapEntry(
        'Best Pace',
        '${fastestPaceActivity.formattedPace}/km',
      ));
    }
    
    if (mostMinutesActivity != null && mostMinutes > 0) {
      final hours = mostMinutes ~/ 3600;
      final minutes = (mostMinutes % 3600) ~/ 60;
      records.add(MapEntry(
        'Longest Time',
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
      ));
    }
    
    return records;
  }

  Widget _buildRecordCard(MapEntry<String, String> record) {
    final textOnGradient = NeonColors.textOnPrimaryGradient;
    
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: NeonColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: NeonShadows.neon(NeonColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            record.key,
            style: NeonTypography.labelSmall.copyWith(
              color: textOnGradient,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.value,
            style: NeonTypography.headlineMedium.copyWith(
              color: textOnGradient,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalDistance = _filteredActivities.fold<double>(
      0,
      (sum, a) => sum + a.distanceMeters,
    );
    final totalDuration = _filteredActivities.fold<int>(
      0,
      (sum, a) => sum + a.durationSeconds,
    );
    final avgPace = _filteredActivities.isNotEmpty && totalDistance > 0
        ? totalDuration / (totalDistance / 1000)
        : 0.0;
    
    final totalActivities = _filteredActivities.length;
    final avgDistance = totalActivities > 0 ? totalDistance / totalActivities / 1000 : 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NeonColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeonColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  value: AppUtils.formatDistanceKm(totalDistance),
                  label: 'Distance',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: NeonColors.border,
                ),
                _buildStatItem(
                  value: _formatDuration(totalDuration),
                  label: 'Time',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: NeonColors.border,
                ),
                _buildStatItem(
                  value: avgPace > 0 ? '${(avgPace ~/ 60)}:${(avgPace % 60).toString().padLeft(2, '0')}' : '--:--',
                  label: 'Avg Pace',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeonColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeonColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$totalActivities',
                        style: NeonTypography.headlineMedium.copyWith(
                          color: NeonColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ACTIVITIES',
                        style: NeonTypography.labelSmall.copyWith(
                          color: NeonColors.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeonColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NeonColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        avgDistance.toStringAsFixed(1),
                        style: NeonTypography.headlineMedium.copyWith(
                          color: NeonColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AVG KM',
                        style: NeonTypography.labelSmall.copyWith(
                          color: NeonColors.textTertiary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: NeonTypography.titleLarge.copyWith(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: NeonTypography.labelSmall.copyWith(
            color: NeonColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  List<Widget> _buildGroupedActivities() {
    final grouped = <String, List<Activity>>{};
    
    for (var activity in _filteredActivities) {
      final key = _getDateGroupKey(activity.date);
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    
    final widgets = <Widget>[];
    
    grouped.forEach((key, activities) {
      widgets.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            key.toUpperCase(),
            style: NeonTypography.labelMedium.copyWith(
              color: NeonColors.textTertiary,
              letterSpacing: 1,
            ),
          ),
        ),
      ));
      
      widgets.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final activity = activities[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildActivityItem(activity),
            );
          },
          childCount: activities.length,
        ),
      ));
    });
    
    return widgets;
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return 'This Week';
    if (date.month == now.month && date.year == now.year) return 'This Month';
    if (date.year == now.year) return 'Earlier This Year';
    return DateFormat('MMMM yyyy').format(date);
  }

  Widget _buildActivityItem(Activity activity) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _openActivityDetail(activity);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeonColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _getActivityGradient(activity.activityTypeString),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getActivityEmoji(activity.activityTypeString),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.activityTypeString,
                          style: NeonTypography.titleMedium.copyWith(
                            color: NeonColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, h:mm a').format(activity.date),
                          style: NeonTypography.labelSmall.copyWith(
                            color: NeonColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: NeonColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActivityStat(
                      icon: CupertinoIcons.map,
                      iconColor: NeonColors.primary,
                      value: activity.distanceKm.toStringAsFixed(2),
                      unit: 'km',
                    ),
                  ),
                  Expanded(
                    child: _buildActivityStat(
                      icon: CupertinoIcons.timer,
                      iconColor: NeonColors.secondary,
                      value: activity.formattedDuration,
                      unit: '',
                    ),
                  ),
                  Expanded(
                    child: _buildActivityStat(
                      icon: CupertinoIcons.speedometer,
                      iconColor: NeonColors.accent,
                      value: activity.formattedPace,
                      unit: '/km',
                    ),
                  ),
                  if (activity.elevationGain != null && activity.elevationGain! > 0)
                    Expanded(
                      child: _buildActivityStat(
                        icon: CupertinoIcons.arrow_up_right,
                        iconColor: NeonColors.iconOnSurface,
                        value: activity.elevationGain!.toStringAsFixed(0),
                        unit: 'm',
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

  Widget _buildActivityStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: NeonTypography.labelMedium.copyWith(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: NeonTypography.labelSmall.copyWith(
              color: NeonColors.textTertiary,
            ),
          ),
      ],
    );
  }

  LinearGradient _getActivityGradient(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return NeonColors.primaryGradient;
      case 'cycling':
        return LinearGradient(
          colors: [NeonColors.secondary, NeonColors.secondaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'swimming':
        return LinearGradient(
          colors: [NeonColors.accent, NeonColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'walking':
        return LinearGradient(
          colors: [NeonColors.success, NeonColors.successDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return NeonColors.primaryGradient;
    }
  }

  String _getActivityEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'running': return '🏃';
      case 'cycling': return '🚴';
      case 'swimming': return '🏊';
      case 'walking': return '🚶';
      case 'hiking': return '🥾';
      default: return '🏃';
    }
  }

  void _openActivityDetail(Activity activity) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ActivityDetailScreen(activityId: activity.id),
      ),
    );
    _loadActivities();
  }
}
