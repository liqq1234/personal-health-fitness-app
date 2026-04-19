import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/user_state.dart';
import '../../../services/user_api_service.dart';
import '../../auth/login_page.dart';

class AccountManagement extends StatefulWidget {
  final User user;
  const AccountManagement({super.key, required this.user});

  @override
  State<AccountManagement> createState() => _AccountManagementState();
}

class _AccountManagementState extends State<AccountManagement> {
  final _userApiService = UserApiService();

  Future<void> _changePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("修改密码"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "原密码"),
            ),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "新密码"),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "确认新密码"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(CusAL.of(context).cancelLabel),
          ),
          TextButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("两次输入的新密码不一致")));
                return;
              }
              try {
                if (widget.user.userId == null) return;
                bool success = await _userApiService.changePassword(
                  widget.user.userId!,
                  oldController.text,
                  newController.text,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("密码修改成功")));
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("错误: ${e.toString()}")));
              }
            },
            child: Text(CusAL.of(context).confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("危险操作"),
        content: const Text("确定要注销账号吗？此操作不可逆，将清除所有相关数据。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(CusAL.of(context).cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("确定注销", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && widget.user.userId != null) {
      try {
        bool success = await _userApiService.deleteUser(widget.user.userId!);
        if (success && mounted) {
          await CacheUser.clearToken();
          await CacheUser.clearUserId();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("错误: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("账号管理")),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("修改密码"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_off_outlined, color: Colors.red),
            title: const Text("注销账号", style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}
