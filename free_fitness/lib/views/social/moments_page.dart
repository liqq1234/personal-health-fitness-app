import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../apis/social_api_service.dart';
import '../../core/constants/constants.dart';
import '../../models/social.dart';
import 'post_moment_page.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final ValueNotifier<List<SocialMoment>> _momentsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void dispose() {
    _momentsNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadTimeline() async {
    _isLoadingNotifier.value = true;
    try {
      final timeline = await SocialApiService.getTimeline(CacheUser.userId);
      if (mounted) {
        _momentsNotifier.value = timeline;
        _isLoadingNotifier.value = false;
      }
    } catch (e) {
      if (mounted) {
        _isLoadingNotifier.value = false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("加载朋友圈失败: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("朋友圈"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTimeline),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ValueListenableBuilder<List<SocialMoment>>(
            valueListenable: _momentsNotifier,
            builder: (context, moments, _) {
              if (moments.isEmpty) {
                return const Center(child: Text("暂无动态，快去分享你的运动生活吧！"));
              }
              return ListView.separated(
                padding: EdgeInsets.all(16.sp),
                itemCount: moments.length,
                separatorBuilder: (context, index) => Divider(height: 32.sp),
                itemBuilder: (context, index) =>
                    _buildMomentItem(moments[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final posted = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostMomentPage()),
          );
          if (posted == true) {
            _loadTimeline();
          }
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildMomentItem(SocialMoment moment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FutureBuilder<dynamic>(
              future: SocialApiService.getUser(moment.userId),
              builder: (context, snapshot) {
                final userMap = snapshot.data;
                final avatar = (userMap != null && userMap['avatar'] != null)
                    ? userMap['avatar']
                    : null;
                final name = (userMap != null) ? userMap['userName'] : "加载中...";
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20.sp,
                      backgroundImage: (avatar != null && avatar.isNotEmpty)
                          ? NetworkImage(avatar)
                          : const AssetImage(defaultAvatarImageUrl)
                                as ImageProvider,
                    ),
                    SizedBox(width: 12.sp),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Text(moment.content, style: TextStyle(fontSize: 15.sp)),
        if (moment.images != null && moment.images!.isNotEmpty) ...[
          SizedBox(height: 12.sp),
          _buildImages(moment.images!),
        ],
        SizedBox(height: 12.sp),
        Row(
          children: [
            Text(
              moment.gmtCreate,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            const Spacer(),
            _buildInteractionBar(moment),
          ],
        ),
        _buildLikeAndCommentSection(moment),
      ],
    );
  }

  Widget _buildInteractionBar(SocialMoment moment) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          children: [
            FutureBuilder<bool>(
              future: SocialApiService.isLikedByUser(
                CacheUser.userId,
                moment.momentId!,
              ),
              builder: (context, snapshot) {
                final isLiked = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                    size: 20.sp,
                  ),
                  onPressed: () async {
                    await SocialApiService.toggleLike(
                      CacheUser.userId,
                      moment.momentId!,
                    );
                    setState(() {}); // Refresh this item
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                size: 20.sp,
                color: Colors.grey,
              ),
              onPressed: () => _showCommentDialog(moment.momentId!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLikeAndCommentSection(SocialMoment moment) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.sp),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLikeList(moment.momentId!),
          _buildCommentList(moment.momentId!),
        ],
      ),
    );
  }

  Widget _buildLikeList(int momentId) {
    return FutureBuilder<List<int>>(
      future: SocialApiService.getLikeUserIds(momentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox();
        final userIds = snapshot.data!;
        return Padding(
          padding: EdgeInsets.only(bottom: 4.sp),
          child: Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 14.sp,
                color: Colors.blueAccent,
              ),
              SizedBox(width: 4.sp),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait(
                    userIds.take(5).map((id) => SocialApiService.getUser(id)),
                  ),
                  builder: (context, subSnapshot) {
                    if (!subSnapshot.hasData) return const Text("...");
                    final users = subSnapshot.data!;
                    final names = users.map((u) => u['userName']).join(", ");
                    return Text(
                      "$names ${userIds.length > 5 ? '等${userIds.length}人' : ''}觉得很赞",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blueAccent,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentList(int momentId) {
    return FutureBuilder<List<SocialComment>>(
      future: SocialApiService.getComments(momentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox();
        final comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return FutureBuilder<dynamic>(
              future: SocialApiService.getUser(comment.userId),
              builder: (context, userSnapshot) {
                final name = userSnapshot.data?['userName'] ?? "...";
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.sp),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13.sp),
                      children: [
                        TextSpan(
                          text: "$name: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        TextSpan(
                          text: comment.content,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCommentDialog(int momentId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("发表评论"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "说点什么..."),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final comment = SocialComment(
                momentId: momentId,
                userId: CacheUser.userId,
                content: controller.text.trim(),
                gmtCreate: DateTime.now().toIso8601String(),
              );
              await SocialApiService.postComment(comment);
              if (mounted) {
                Navigator.pop(context);
                _loadTimeline(); // Refresh to show new comment
              }
            },
            child: const Text("发表"),
          ),
        ],
      ),
    );
  }

  Widget _buildImages(String images) {
    final imageList = images.split(',');
    if (imageList.length == 1) {
      return _buildSingleImage(imageList[0]);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.sp,
        mainAxisSpacing: 8.sp,
      ),
      itemCount: imageList.length,
      itemBuilder: (context, index) =>
          _buildSingleImage(imageList[index], isGrid: true),
    );
  }

  Widget _buildSingleImage(String path, {bool isGrid = false}) {
    final isNetwork = path.startsWith('http');
    final borderRadius = BorderRadius.circular(isGrid ? 4.sp : 8.sp);

    Widget image;
    if (isNetwork) {
      image = Image.network(path, fit: isGrid ? BoxFit.cover : BoxFit.fitWidth);
    } else {
      image = Image.file(
        File(path),
        fit: isGrid ? BoxFit.cover : BoxFit.fitWidth,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: isGrid ? null : 0.6.sw, child: image),
    );
  }
}
