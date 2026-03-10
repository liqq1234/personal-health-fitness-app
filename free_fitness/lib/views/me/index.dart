import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/utils/tool_widgets.dart';
import '../../core/constants/constants.dart';
import '../../core/storage/db_user_helper.dart';
import '../../layout/themes/cus_font_size.dart';
import '../../models/cus_app_localizations.dart';
import '../../models/user_state.dart';
import 'backup_and_restore/index.dart';
import 'intake_goals/intake_target.dart';
import 'more_settings/index.dart';
import 'training_setting/index.dart';
import 'user_info/index.dart';
import 'user_info/modify_user/index.dart';
import 'weight_change_record/index.dart';
import '../auth/login_page.dart';

class UserAndSettings extends StatefulWidget {
  const UserAndSettings({super.key});

  @override
  State<UserAndSettings> createState() => _UserAndSettingsState();
}

class _UserAndSettingsState extends State<UserAndSettings> {
  final DBUserHelper _userHelper = DBUserHelper();

  // 用户头像路径
  String _avatarPath = "";

  // 这里有修改，暂时不用get
  int currentUserId = 1;

  // ？？？登录用户信息，怎么在app中记录用户信息？缓存一个用户id每次都查？记住状态实时更新？……
  late User userInfo;

  bool isLoading = false;

  // 切换用户时，选择的用户
  User? selectedUser;

  @override
  void initState() {
    super.initState();

    currentUserId = CacheUser.userId;
    _queryLoginedUserInfo();
  }

  // 查询登录用户的信息
  Future<void> _queryLoginedUserInfo() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    // 查询登录用户的信息一定会有的
    var tempUser = (await _userHelper.queryUser(userId: currentUserId))!;

    if (!mounted) return;
    setState(() {
      userInfo = tempUser;
      if (tempUser.avatar != null) {
        _avatarPath = tempUser.avatar!;
      } else {
        // 不清空，切换用户可能还是之前用户的头像
        _avatarPath = "";
      }
      isLoading = false;
    });
  }

  // 弹窗切换用户
  Future<void> _switchUser() async {
    var userList = await _userHelper.queryUserList();

    if (!mounted) return;
    if (userList != null && userList.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(CusAL.of(context).tipLabel),
            content: Text(CusAL.of(context).noOtherUser),
            actions: [
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
                child: Text(CusAL.of(context).confirmLabel),
              ),
            ],
          );
        },
      );
    } else if (userList != null && userList.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(CusAL.of(context).switchUser),
            content: DropdownButtonFormField<User>(
              value: userList.firstWhere((e) => e.userId == currentUserId),
              decoration: const InputDecoration(
                // 设置透明底色
                filled: true,
                fillColor: Colors.transparent,
              ),
              items: userList.map((User user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text(user.userName),
                );
              }).toList(),
              onChanged: (User? value) async {
                setState(() {
                  selectedUser = value;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, false);
                },
                child: Text(CusAL.of(context).cancelLabel),
              ),
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
                child: Text(CusAL.of(context).confirmLabel),
              ),
            ],
          );
        },
      ).then((value) async {
        // 如果有返回值且为true，
        if (value != null && value == true) {
          // 修改缓存的用户编号
          CacheUser.updateUserId(selectedUser!.userId!);
          CacheUser.updateUserName(selectedUser!.userName);
          CacheUser.updateUserCode(selectedUser!.userCode ?? "");

          // 重新缓存当前用户编号和查询用户信息
          setState(() {
            currentUserId = CacheUser.userId;
            _queryLoginedUserInfo();
          });
        }
      });
    }
  }

  // 修改头像
  // 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() {
        _avatarPath = pickedFile.path;
      });

      var temp = userInfo;
      temp.avatar = _avatarPath;
      await _userHelper.updateUser(temp);
    }
  }

  // 退出登录
  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(CusAL.of(context).tipLabel),
        content: const Text("确定要退出登录吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(CusAL.of(context).cancelLabel),
          ),
          TextButton(
            onPressed: () async {
              // 清除缓存
              await CacheUser.clearToken();
              await CacheUser.clearUserId();
              if (!mounted) return;
              // 跳转到登录页并清空路由栈
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(
              CusAL.of(context).confirmLabel,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CusAL.of(context).moduleTitles('3')),
        actions: [
          // 切换用户(切换后缓存的用户编号也得修改)
          IconButton(onPressed: _switchUser, icon: const Icon(Icons.toggle_on)),
          // 新增用户(默认就一个用户，保存多个用户的数据就需要可以新增其他用户)
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModifyUserPage()),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: isLoading
          ? buildLoader(isLoading)
          : SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// 用户基本信息展示区域(固定高度)
                  ..._buildBaseUserInfoArea(userInfo),
                  SizedBox(height: 16.sp),

                  /// 设置项展示区域
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp),
                    child: Column(
                      children: [
                        _buildInfoAndWeightChangeRow(),
                        SizedBox(height: 12.sp),
                        _buildIntakeGoalAndRestTimeRow(),
                        SizedBox(height: 12.sp),
                        _buildBakAndRestoreAndMoreSettingRow(),
                        SizedBox(height: 30.sp),
                        // 退出登录按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text(
                              "退出登录",
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.sp),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.sp),
                              ),
                            ),
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

  // 用户基本信息展示区域
  List<RenderObjectWidget> _buildBaseUserInfoArea(User userInfo) {
    return [
      SizedBox(height: 10.sp),

      /// 头像相关
      Stack(
        alignment: Alignment.center,
        children: [
          /// 头像图片
          // 没有修改头像，就用默认的
          if (_avatarPath.isEmpty)
            CircleAvatar(
              maxRadius: 45.sp,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage(defaultAvatarImageUrl),
              // 圆形头像的边框线
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2.sp,
                  ),
                ),
              ),
            ),
          if (_avatarPath.isNotEmpty)
            GestureDetector(
              onTap: () {
                // 这个直接弹窗显示图片可以缩放
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent, // 设置背景透明
                      child: PhotoView(
                        imageProvider: FileImage(File(_avatarPath)),
                        // 设置图片背景为透明
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        // 可以旋转
                        // enableRotation: true,
                        // 缩放的最大最小限制
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      ),
                    );
                  },
                );
              },
              child: CircleAvatar(
                maxRadius: 45.sp,
                backgroundImage: FileImage(File(_avatarPath)),
              ),
            ),

          /// 性别图标
          Positioned(
            top: 65.sp,
            right: 0.5.sw - 60.sp,
            child: userInfo.gender == "male"
                ? Icon(
                    Icons.male,
                    size: CusIconSizes.iconBig,
                    color: Colors.red,
                  )
                : userInfo.gender == "female"
                ? Icon(
                    Icons.female,
                    size: CusIconSizes.iconBig,
                    color: Colors.green,
                  )
                : Icon(
                    Icons.bolt,
                    size: CusIconSizes.iconNormal,
                    color: Theme.of(context).disabledColor,
                  ),
          ),

          /// 修改头像按钮
          Positioned(
            top: 0.sp,
            right: 0.sp,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(CusAL.of(context).changeAvatarLabels('1')),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.camera);
                          },
                          child: Text(
                            CusAL.of(context).changeAvatarLabels('2'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.gallery);
                          },
                          child: Text(
                            CusAL.of(context).changeAvatarLabels('3'),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                CusAL.of(context).changeAvatarLabels('0'),
                style: TextStyle(fontSize: CusFontSizes.flagTiny),
              ),
            ),
          ),
        ],
      ),

      /// 个人简介
      SizedBox(
        height: 60.sp,
        child: Center(
          child: Text(
            userInfo.userName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp),
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
  }

  Row _buildInfoAndWeightChangeRow() {
    return Row(
      children: [
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.account_circle_outlined,
            title: CusAL.of(context).settingLabels('0'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserInfo()),
              ).then((value) {
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.table_chart_rounded,
            title: CusAL.of(context).settingLabels('1'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeightChangeRecord(userInfo: userInfo),
                ),
              ).then((value) {
                if (value != null && value == true) {
                  _queryLoginedUserInfo();
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Row _buildIntakeGoalAndRestTimeRow() {
    return Row(
      children: [
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.flag_circle_outlined,
            title: CusAL.of(context).settingLabels('2'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IntakeTargetPage(userInfo: userInfo),
                ),
              ).then((value) {
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.directions_run_rounded,
            title: CusAL.of(context).settingLabels('3'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingSetting(userInfo: userInfo),
                ),
              ).then((value) {
                _queryLoginedUserInfo();
              });
            },
          ),
        ),
      ],
    );
  }

  Row _buildBakAndRestoreAndMoreSettingRow() {
    return Row(
      children: [
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.backup_outlined,
            title: CusAL.of(context).settingLabels('4'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupAndRestore(),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: NewCusSettingCard(
            leadingIcon: Icons.settings_rounded,
            title: CusAL.of(context).settingLabels('5'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MoreSettings()),
              );
            },
          ),
        ),
        // Expanded(
        //   child: NewCusSettingCard(
        //     leadingIcon: Icons.privacy_tip_sharp,
        //     title: '常见问题(tbd)',
        //     onTap: () {
        //       // 处理相应的点击事件
        //     },
        //   ),
        // ),
      ],
    );
  }
}

// 每个设置card抽出来复用
class NewCusSettingCard extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final VoidCallback onTap;

  const NewCusSettingCard({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.sp),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.sp, horizontal: 8.sp),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16.sp),
            border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(leadingIcon, size: 32.sp, color: colorScheme.primary),
              SizedBox(height: 12.sp),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
