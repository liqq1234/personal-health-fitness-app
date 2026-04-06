# Free Fitness 启动文档

本项目是一个基于 Flutter 开发的个人健康管理与运动追踪应用程序。

## 环境要求

- **Flutter SDK**: ^3.24.x (建议使用最新稳定版)
- **Dart SDK**: ^3.5.x
- **操作系统**: Windows 10/11 (支持 Windows 桌面端)
- **开发工具**: Visual Studio 2019/2022 (需安装 "使用 C++ 的桌面开发" 工作负载)

## 快速启动步骤

### 1. 初始化依赖

在项目根目录下运行以下命令安装必要的 package：

```bash
flutter pub get
```

> [!TIP]
> 如果遇到终端拦截（详见“常见问题”），可以使用以下命令绕过：
> `D:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe pub get`

### 2. 运行应用程序

确保已连接 Windows 设备或模拟器，运行：

```bash
# 运行 Windows 桌面端
flutter run -d windows
```

## 常见问题与解决

### 1. 终端提示“终止批处理操作吗(Y/N)?”

这是由于 Windows 终端对 `flutter.bat` 的信号处理冲突导致的。如果此提示频繁出现且无法正常执行命令，可以尝试：

- **直接运行 Snapshot**:
  使用 Dart 引擎直接运行编译工具镜像，绕过批处理文件：
  ```powershell
  $env:FLUTTER_ROOT = "D:\tools\flutter"
  & "D:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe" --packages="D:\tools\flutter\packages\flutter_tools\.dart_tool\package_config.json" "D:\tools\flutter\bin\cache\flutter_tools.snapshot" run -d windows
  ```

### 2. PathExistsException (errno = 183)

如果在编译过程中出现 `Cannot create link` 错误，通常是由于旧的编译缓存冲突。

**解决方法**:
```bash
flutter clean
flutter pub get
```

### 3. 未找到 Android SDK

本项目当前配置了 Windows 和 Android 支持。如果只在 Windows 上开发，可以忽略 Android SDK 相关的错误，或通过 `flutter devices` 确认 Windows 设备已连接。

---

*文档更新日期：2026-04-03*
