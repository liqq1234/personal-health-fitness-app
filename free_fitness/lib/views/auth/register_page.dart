import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/dio_client/cus_http_client.dart';
import '../../core/utils/toast_utils.dart';
import '../../core/constants/constants.dart';
import '../../layout/home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController(); // 显示名称
  final _userCodeController = TextEditingController(); // 登录账号
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_usernameController.text.isEmpty ||
        _userCodeController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ToastUtils.showError("请填写完整注册信息");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await HttpUtils.post(
        path: "/auth/register",
        data: {
          "userName": _usernameController.text,
          "userCode": _userCodeController.text,
          "password": _passwordController.text,
        },
      );

      if (response != null &&
          response['code'] == 200 &&
          response['data'] != null) {
        var data = response['data'];
        String token = data['token'];
        int userId = data['userId'];
        String username = data['username'] ?? _usernameController.text;

        // 保存到存储
        await CacheUser.updateToken(token);
        await CacheUser.updateUserId(userId);
        await CacheUser.updateUserName(username);

        ToastUtils.showSuccess("注册成功");

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        ToastUtils.showError("注册失败: 响应异常");
      }
    } catch (e) {
      ToastUtils.showError("注册失败: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("用户注册"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.sp),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 80.sp),
                Text(
                  "创建新账号",
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 10.sp),
                Text(
                  "开启您的健康健身之旅",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
                SizedBox(height: 40.sp),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "显示昵称",
                    prefixIcon: const Icon(Icons.face),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                  ),
                ),
                SizedBox(height: 20.sp),
                TextField(
                  controller: _userCodeController,
                  decoration: InputDecoration(
                    labelText: "登录账号 (User Code)",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                  ),
                ),
                SizedBox(height: 20.sp),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "密码",
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                  ),
                ),
                SizedBox(height: 40.sp),
                SizedBox(
                  width: double.infinity,
                  height: 50.sp,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("立即注册", style: TextStyle(fontSize: 18.sp)),
                  ),
                ),
                SizedBox(height: 20.sp),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("已有账号？前去登录"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
