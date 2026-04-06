import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/trak_design_system.dart';

/// Feed Screen - Social feed with neon styling
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    themeChangeNotifier.addListener(_onThemeChange);
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    themeChangeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top Bar
          SliverToBoxAdapter(
            child: _buildTopBar(),
          ),
          
          // Stories
          SliverToBoxAdapter(
            child: _buildStories(),
          ),
          
          // Feed Posts
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildFeedPost(index);
              },
              childCount: 5,
            ),
          ),
          
          // Bottom padding for nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      child: Row(
        children: [
          Text(
            'TRAK',
            style: NeonTypography.displaySmall.copyWith(
              color: NeonColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          _buildTopBarButton(
            icon: CupertinoIcons.bell,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _buildTopBarButton(
            icon: CupertinoIcons.search,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTopBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: NeonColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NeonColors.border, width: 1),
        ),
        child: Icon(
          icon,
          color: NeonColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStories() {
    final stories = [
      {'name': 'You', 'isAdd': true, 'emoji': '➕'},
      {'name': 'Alex', 'isAdd': false, 'emoji': '🏃'},
      {'name': 'Sarah', 'isAdd': false, 'emoji': '🚴'},
      {'name': 'Mike', 'isAdd': false, 'emoji': '🏊'},
      {'name': 'Emma', 'isAdd': false, 'emoji': '🥾'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            final isAdd = story['isAdd'] as bool;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 70,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    // Avatar with neon border
                    Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: isAdd ? null : NeonColors.primaryGradient,
                        borderRadius: BorderRadius.circular(30),
                        border: isAdd 
                            ? Border.all(color: NeonColors.border, width: 2)
                            : null,
                        boxShadow: isAdd ? null : NeonShadows.neon(NeonColors.primary),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: NeonColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            story['emoji'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      story['name'] as String,
                      style: NeonTypography.labelSmall.copyWith(
                        color: isAdd 
                            ? NeonColors.textTertiary 
                            : NeonColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeedPost(int index) {
    final posts = [
      {
        'name': 'Alex Johnson',
        'time': '2h ago',
        'title': 'Morning Run 🏃‍♂️',
        'distance': '10.5 km',
        'duration': '52:30',
        'pace': '5:00 /km',
        'likes': 24,
        'comments': 5,
        'shares': 2,
      },
      {
        'name': 'Sarah Chen',
        'time': '4h ago',
        'title': 'Evening Jog 🌙',
        'distance': '5.2 km',
        'duration': '28:15',
        'pace': '5:26 /km',
        'likes': 18,
        'comments': 3,
        'shares': 1,
      },
      {
        'name': 'Mike Rodriguez',
        'time': '6h ago',
        'title': 'Weekend Long Run',
        'distance': '21.1 km',
        'duration': '1:45:30',
        'pace': '5:00 /km',
        'likes': 56,
        'comments': 12,
        'shares': 8,
      },
      {
        'name': 'Emma Wilson',
        'time': '8h ago',
        'title': 'Morning Cycling 🚴',
        'distance': '35.0 km',
        'duration': '1:15:00',
        'pace': '2:08 /km',
        'likes': 42,
        'comments': 7,
        'shares': 4,
      },
      {
        'name': 'James Lee',
        'time': '12h ago',
        'title': 'Trail Hiking 🥾',
        'distance': '12.8 km',
        'duration': '3:20:00',
        'pace': '15:37 /km',
        'likes': 89,
        'comments': 15,
        'shares': 12,
      },
    ];

    final post = posts[index % posts.length];
    final textOnGradient = NeonColors.textOnPrimaryGradient;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 6,
      ),
      child: NeonCard(
        padding: EdgeInsets.zero,
        showBorder: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: NeonColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (post['name'] as String)[0],
                        style: NeonTypography.headlineMedium.copyWith(
                          color: textOnGradient,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['name'] as String,
                          style: NeonTypography.titleMedium.copyWith(
                            color: NeonColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          post['time'] as String,
                          style: NeonTypography.labelSmall.copyWith(
                            color: NeonColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.ellipsis,
                    color: NeonColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post['title'] as String,
                style: NeonTypography.headlineSmall.copyWith(
                  color: NeonColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NeonCard(
                padding: const EdgeInsets.all(14),
                backgroundColor: NeonColors.surface,
                showBorder: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: CupertinoIcons.arrow_left_right,
                      iconColor: NeonColors.iconOnSurface,
                      value: post['distance'] as String,
                      label: 'Distance',
                    ),
                    _buildStatItem(
                      icon: CupertinoIcons.timer,
                      iconColor: NeonColors.iconOnSurfaceSecondary,
                      value: post['duration'] as String,
                      label: 'Time',
                    ),
                    _buildStatItem(
                      icon: CupertinoIcons.flame,
                      iconColor: NeonColors.iconOnSurface,
                      value: post['pace'] as String,
                      label: 'Pace',
                    ),
                  ],
                ),
              ),
            ),
            
            // Map placeholder
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: NeonColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NeonColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.map,
                        color: NeonColors.textTertiary,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Route Map',
                        style: NeonTypography.labelMedium.copyWith(
                          color: NeonColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16, 0, 16, 16,
              ),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: CupertinoIcons.heart,
                    count: post['likes'] as int,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: CupertinoIcons.chat_bubble,
                    count: post['comments'] as int,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: CupertinoIcons.arrow_2_squarepath,
                    count: post['shares'] as int,
                    onTap: () {},
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      CupertinoIcons.bookmark,
                      color: NeonColors.textTertiary,
                      size: 22,
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

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: NeonTypography.titleMedium.copyWith(
            color: NeonColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: NeonTypography.labelSmall.copyWith(
            color: NeonColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: NeonColors.textTertiary, size: 22),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: NeonTypography.bodySmall.copyWith(
              color: NeonColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
