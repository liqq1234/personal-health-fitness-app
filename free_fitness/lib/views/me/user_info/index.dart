import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/tool_widgets.dart';
import '../../../core/utils/tools.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';
import '../../../core/dio_client/cus_http_client.dart';
import 'modify_user/index.dart';

class UserInfo extends StatefulWidget {
  const UserInfo({super.key});

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  User user = User(userName: "");
  // 用户头像路径
  String _avatarPath = "";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _queryLoginedUserInfo();
  }

  Future<void> _queryLoginedUserInfo() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    User? tempUser;

    // 1. 尝试从云端获取最新数据 (Try getting latest from Cloud)
    try {
      var response = await HttpUtils.get(
        path: "/users/${CacheUser.userId}",
        showLoading: false,
      );
      if (response != null && response['data'] != null) {
        tempUser = User.fromMap(response['data']);
      }
    } catch (e) {
      print("Fetch cloud user failed: $e");
    }

    if (!mounted) return;
    if (tempUser == null) {
      // 如果获取失败，可以给个提示或者留空
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      user = tempUser!;
      if (tempUser.avatar != null) {
        _avatarPath = tempUser.avatar!;
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).settingLabels("0")),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModifyUserPage(user: user),
                ),
              ).then((value) {
                _queryLoginedUserInfo();
              });
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : ListView(
              children: [
                SizedBox(height: 10.sp),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 没有修改头像，就用默认的
                    if (_avatarPath.isEmpty)
                      CircleAvatar(
                        maxRadius: 60.sp,
                        backgroundColor: Colors.transparent,
                        backgroundImage: const AssetImage(
                          defaultAvatarImageUrl,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 2.sp),
                          ),
                        ),
                      ),
                    if (_avatarPath.isNotEmpty)
                      CircleAvatar(
                        maxRadius: 60.sp,
                        backgroundImage: FileImage(File(_avatarPath)),
                      ),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem(
                      CusAL.of(context).userInfoLabels("0"),
                      user.userName,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem(
                      CusAL.of(context).userInfoLabels("2"),
                      showCusLableMapLabel(
                        context,
                        genderOptions.firstWhere(
                          (e) => e.value == user.gender,
                          orElse: () => genderOptions.first,
                        ),
                      ),
                    ),
                    _buildListItem(
                      CusAL.of(context).userInfoLabels("3"),
                      user.dateOfBirth ?? "",
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildListItem(
                      CusAL.of(context).userInfoLabels("4"),
                      '${cusDoubleTryToIntString(user.height ?? 0)} ${CusAL.of(context).unitLabels("4")}',
                    ),
                    _buildListItem(
                      CusAL.of(context).userInfoLabels("5"),
                      '${cusDoubleTryToIntString(user.currentWeight ?? 0)} ${CusAL.of(context).unitLabels("5")}',
                    ),
                  ],
                ),

                Row(
                  children: [
                    _buildListItem(
                      CusAL.of(context).userInfoLabels("6"),
                      user.description ?? "",
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildListItem(String title, String value) {
    return Expanded(
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }
}
