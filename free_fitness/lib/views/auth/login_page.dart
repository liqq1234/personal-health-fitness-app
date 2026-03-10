import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/constants.dart';
import '../../core/dio_client/cus_http_client.dart';
import '../../core/utils/toast_utils.dart';
import '../../layout/home.dart';
import '../../models/cus_app_localizations.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ToastUtils.showError("请输入用户名和密码");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await HttpUtils.post(
        path: "/auth/login",
        data: {
          "userCode": _usernameController.text,
          "password": _passwordController.text,
        },
      );

      // 后端返回 Result<TokenResponse> (带有 code, message, data 包装)
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

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ToastUtils.showError("登录失败: 响应异常");
      }
    } catch (e) {
      ToastUtils.showError("登录失败: $e");
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
                Hero(
                  tag: 'logo',
                  child: Image.asset(appLogoImageUrl, height: 100.sp),
                ),
                SizedBox(height: 20.sp),
                Text(
                  CusAL.of(context).appTitle,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 40.sp),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "用户名",
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
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.sp),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("登录", style: TextStyle(fontSize: 18.sp)),
                  ),
                ),
                SizedBox(height: 20.sp),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text("没有账号？去注册"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
