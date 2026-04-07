import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/toast_utils.dart';
import '../core/utils/tools.dart';
import '../models/cus_app_localizations.dart';
// import '../views/diary/index_table_calendar.dart';
import '../views/me/index.dart';
import '../views/training/health_dashboard.dart';
import '../views/training/index.dart';
import '../views/dietary/diet_entry.dart';
import '../views/diary/sleep_report.dart';
import '../services/pedometer_service.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Default to Today
  static final GlobalKey<HealthDashboardState> _healthKey = GlobalKey();

  static List<Widget> _widgetOptions = <Widget>[
    const DietEntryPage(),
    const Training(),
    HealthDashboard(key: _healthKey),
    const SleepReportPage(),
    const UserAndSettings(),
  ];

  @override
  void initState() {
    super.initState();
    initPermission();
    PedometerService().initPedometer();
  }

  Future<void> initPermission() async {
    var state = await requestStoragePermission();

    if (!state) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(CusAL.of(context).permissionRequest),
            content: Text(CusAL.of(context).featuresRestrictionNote),
            actions: <Widget>[
              TextButton(
                child: Text(CusAL.of(context).cancelLabel),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              ElevatedButton(
                child: Text(CusAL.of(context).confirmLabel),
                onPressed: () async {
                  var state = await requestStoragePermission();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(state);
                },
              ),
            ],
          );
        },
      ).then((value) {
        if (value == false) {
          if (!mounted) return;
          ToastUtils.showToast(CusAL.of(context).noStorageHint);
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 如果切回到“今日”仪表盘，则触发刷新
    if (index == 2) {
      _healthKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(CusAL.of(context).closeLabel),
              content: Text(CusAL.of(context).appExitInfo),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text(CusAL.of(context).cancelLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text(CusAL.of(context).confirmLabel),
                ),
              ],
            );
          },
        ); // 只有当对话框返回true 才 pop(返回上一层)
        if (shouldPop ?? false) {
          if (!context.mounted) return;
          // 如果还有可以关闭的导航，则继续pop
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            // 如果已经到头来，则关闭应用程序
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
        // backgroundColor: Colors.red,
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: BottomNavigationBar(
          // 当item数量小于等于3时会默认fixed模式下使用主题色，大于3时则会默认shifting模式下使用白色。
          // 为了使用主题色，这里手动设置为fixed
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: '饮食',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.fitness_center),
              label: CusAL.of(context).training,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: '今日',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bedtime),
              label: '睡眠',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: CusAL.of(context).me,
            ),
          ],
          currentIndex: _selectedIndex,
          // 底部导航栏的颜色
          // backgroundColor: dartThemeMaterialColor3,
          // backgroundColor: Theme.of(context).primaryColor,
          // // 被选中的item的图标颜色和文本颜色
          // selectedIconTheme: const IconThemeData(color: Colors.white),
          // selectedItemColor: Colors.white,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
