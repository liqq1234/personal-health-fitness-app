import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../apis/social_api_service.dart';
import '../../core/constants/constants.dart';
import '../../models/user_state.dart';

class FriendProfilePage extends StatefulWidget {
  final User friend;
  const FriendProfilePage({super.key, required this.friend});

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final data = await SocialApiService.getFriendHealthSummary(
        widget.friend.userId!,
      );
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("加载数据失败: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("好友资料"),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 100.sp),
            // Header: Avatar & Name
            CircleAvatar(
              radius: 50.sp,
              backgroundImage:
                  (widget.friend.avatar != null &&
                      widget.friend.avatar!.isNotEmpty)
                  ? NetworkImage(widget.friend.avatar!)
                  : const AssetImage(defaultAvatarImageUrl) as ImageProvider,
            ),
            SizedBox(height: 16.sp),
            Text(
              widget.friend.userName,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "ID: ${widget.friend.userCode ?? widget.friend.userId}",
              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
            ),
            SizedBox(height: 32.sp),

            // Health Stats Section
            Expanded(
              child: Container(
                padding: EdgeInsets.all(24.sp),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.sp),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStatsContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "最近7天健康摘要",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.sp),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16.sp,
            crossAxisSpacing: 16.sp,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                "总步数",
                "${_summary['totalSteps'] ?? 0}",
                Icons.directions_walk,
                Colors.orange,
              ),
              _buildStatCard(
                "总里程",
                "${(_summary['totalDistance'] ?? 0.0).toStringAsFixed(2)} km",
                Icons.straighten,
                Colors.blue,
              ),
              _buildStatCard(
                "消耗热量",
                "${(_summary['totalCalories'] ?? 0.0).toStringAsFixed(0)} kcal",
                Icons.local_fire_department,
                Colors.red,
              ),
              _buildStatCard(
                "达标天数",
                "${_summary['activeDays'] ?? 0} 天",
                Icons.event_available,
                Colors.green,
              ),
            ],
          ),
          SizedBox(height: 32.sp),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.sp),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                "个人简介",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.sp),
          Text(
            widget.friend.description ?? "这个小伙伴很懒，什么都没有留下~",
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
