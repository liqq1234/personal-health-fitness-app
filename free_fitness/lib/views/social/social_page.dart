import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../apis/social_api_service.dart';
import '../../core/constants/constants.dart';
import '../../models/user_state.dart';
import 'friend_profile_page.dart';
import 'moments_page.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final ValueNotifier<List<User>> _friendsNotifier = ValueNotifier<List<User>>(
    [],
  );
  final ValueNotifier<List<User>> _pendingRequestsNotifier =
      ValueNotifier<List<User>>([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<List<User>> _searchResultsNotifier =
      ValueNotifier<List<User>>([]);
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>("");
  final ValueNotifier<List<User>> _sentRequestsNotifier =
      ValueNotifier<List<User>>([]);
  final ValueNotifier<bool> _showRequestsNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData(isInitial: true);
    });
  }

  @override
  void dispose() {
    _friendsNotifier.dispose();
    _pendingRequestsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _searchResultsNotifier.dispose();
    _searchQueryNotifier.dispose();
    _sentRequestsNotifier.dispose();
    _showRequestsNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isInitial = false}) async {
    if (!mounted) return;
    _isLoadingNotifier.value = true;

    try {
      // 1. 加载好友
      final friendIds = await SocialApiService.getFriends(
        CacheUser.userId,
        showLoading: !isInitial,
      );
      List<User> friends = [];
      for (var id in friendIds) {
        final userData = await SocialApiService.getUser(id);
        if (userData != null) friends.add(User.fromMap(userData));
      }

      // 2. 加载待处理请求
      final pendingIds = await SocialApiService.getPendingRequests(
        CacheUser.userId,
      );
      List<User> pending = [];
      for (var id in pendingIds) {
        final userData = await SocialApiService.getUser(id);
        if (userData != null) pending.add(User.fromMap(userData));
      }

      // 3. 加载已发送请求
      final sentIds = await SocialApiService.getSentRequests(CacheUser.userId);
      List<User> sent = [];
      for (var id in sentIds) {
        final userData = await SocialApiService.getUser(id);
        if (userData != null) sent.add(User.fromMap(userData));
      }

      if (mounted) {
        _friendsNotifier.value = friends;
        _pendingRequestsNotifier.value = pending;
        _sentRequestsNotifier.value = sent;
        _isLoadingNotifier.value = false;
      }
    } catch (e) {
      if (mounted) {
        _isLoadingNotifier.value = false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("加载失败: $e")));
      }
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      _searchResultsNotifier.value = [];
      return;
    }
    try {
      final results = await SocialApiService.searchUsers(query);
      if (mounted) {
        _searchResultsNotifier.value = results
            .map((e) => User.fromMap(e))
            .toList();
      }
    } catch (e) {
      print("搜索失败: $e");
    }
  }

  Future<void> _acceptFriend(int requesterId) async {
    try {
      await SocialApiService.acceptFriend(CacheUser.userId, requesterId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("已接受好友请求")));
        _loadData();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("操作失败: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("社区"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(isInitial: false),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: TextField(
              decoration: InputDecoration(
                hintText: "通过姓名或编号搜索用户...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.sp),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              onChanged: (val) {
                _searchQueryNotifier.value = val;
                _handleSearch(val);
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: _searchQueryNotifier,
              builder: (context, query, _) {
                if (query.isNotEmpty) {
                  return ValueListenableBuilder<List<User>>(
                    valueListenable: _searchResultsNotifier,
                    builder: (context, results, _) {
                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) =>
                            _buildSearchResultTile(results[index]),
                      );
                    },
                  );
                } else {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      if (isLoading)
                        return const Center(child: CircularProgressIndicator());
                      return _buildMainList();
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showRequestsNotifier,
      builder: (context, showRequests, _) {
        return ValueListenableBuilder<List<User>>(
          valueListenable: _pendingRequestsNotifier,
          builder: (context, pending, _) {
            return ValueListenableBuilder<List<User>>(
              valueListenable: _sentRequestsNotifier,
              builder: (context, sent, _) {
                return ValueListenableBuilder<List<User>>(
                  valueListenable: _friendsNotifier,
                  builder: (context, friends, _) {
                    final List<Widget> children = [];

                    if (showRequests) {
                      // Back button to friend list
                      children.add(
                        ListTile(
                          leading: const Icon(Icons.arrow_back),
                          title: const Text("返回通讯录"),
                          onTap: () => _showRequestsNotifier.value = false,
                        ),
                      );

                      if (pending.isNotEmpty) {
                        children.add(
                          _buildSectionHeader("待处理请求 (${pending.length})"),
                        );
                        children.addAll(
                          pending.map((u) => _buildPendingRequestTile(u)),
                        );
                      } else {
                        children.add(
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("暂无待处理请求")),
                          ),
                        );
                      }

                      if (sent.isNotEmpty) {
                        children.add(
                          _buildSectionHeader("已发送请求 (${sent.length})"),
                        );
                        children.addAll(
                          sent.map((u) => _buildSentRequestTile(u)),
                        );
                      } else {
                        children.add(
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("暂无已发送请求")),
                          ),
                        );
                      }
                    } else {
                      // Moments Entry
                      children.add(_buildMomentsEntry());
                      children.add(const Divider(height: 1));

                      // New Friends Entry
                      children.add(_buildNewFriendsEntry(pending.length));
                      children.add(const Divider(height: 1));

                      children.add(
                        _buildSectionHeader("好友列表 (${friends.length})"),
                      );
                      if (friends.isEmpty) {
                        children.add(
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(child: Text("暂无好友，快去搜索添加吧！")),
                          ),
                        );
                      } else {
                        children.addAll(
                          friends.map((u) => _buildFriendTile(u)),
                        );
                      }
                    }

                    return ListView(children: children);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMomentsEntry() {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MomentsPage()),
        );
      },
      leading: Container(
        width: 40.sp,
        height: 40.sp,
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: const Icon(Icons.photo_library, color: Colors.white),
      ),
      title: const Text("朋友圈"),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildNewFriendsEntry(int pendingCount) {
    return ListTile(
      onTap: () => _showRequestsNotifier.value = true,
      leading: Container(
        width: 40.sp,
        height: 40.sp,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      title: const Text("新的朋友"),
      trailing: pendingCount > 0
          ? Container(
              padding: EdgeInsets.all(6.sp),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                pendingCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
    );
  }

  Widget _buildSentRequestTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
            ? NetworkImage(user.avatar!)
            : const AssetImage(defaultAvatarImageUrl) as ImageProvider,
      ),
      title: Text(user.userName),
      subtitle: const Text("等待对方验证..."),
      trailing: const Text("已发送", style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
            ? NetworkImage(user.avatar!)
            : const AssetImage(defaultAvatarImageUrl) as ImageProvider,
      ),
      title: Text(user.userName),
      subtitle: Text("ID: ${user.userCode ?? user.userId}"),
      trailing: user.userId == CacheUser.userId
          ? const Text("本人", style: TextStyle(color: Colors.grey))
          : ElevatedButton(
              onPressed: () async {
                await SocialApiService.requestFriend(
                  CacheUser.userId,
                  user.userId!,
                );
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("请求已发送")));
                  _loadData(); // 添加刷新
                }
              },
              child: const Text("添加"),
            ),
    );
  }

  Widget _buildPendingRequestTile(User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
            ? NetworkImage(user.avatar!)
            : const AssetImage(defaultAvatarImageUrl) as ImageProvider,
      ),
      title: Text(user.userName),
      subtitle: const Text("请求添加你为好友"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _acceptFriend(user.userId!),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () {
              // TODO: Implement decline logic if needed
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(User friend) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendProfilePage(friend: friend),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundImage: (friend.avatar != null && friend.avatar!.isNotEmpty)
            ? NetworkImage(friend.avatar!)
            : const AssetImage(defaultAvatarImageUrl) as ImageProvider,
      ),
      title: Text(friend.userName),
      subtitle: const Text("在线"),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
