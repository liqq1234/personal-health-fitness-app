import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/storage/db_health_helper.dart';
import '../../models/health_models.dart';
import 'sleep_entry.dart';
import '../training/sleep_insights.dart';

class SleepReportPage extends StatefulWidget {
  const SleepReportPage({super.key});

  @override
  State<SleepReportPage> createState() => _SleepReportPageState();
}

class _SleepReportPageState extends State<SleepReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DBHealthHelper();
  List<SleepRecord> _records = [];
  bool _isLoading = true;
  int _selectedDays = 7; // 默认 7 天

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(Duration(days: _selectedDays));

    final records = await _dbHelper.querySleepList(
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(now),
      limit: 100,
    );

    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  double get _avgSleep {
    if (_records.isEmpty) return 0;
    double total = _records.fold(0, (sum, e) => sum + e.durationHours);
    return total / _records.length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('睡眠报表 / Sleep Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '睡眠报表'),
            Tab(text: '睡眠分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordsListView(colorScheme),
          const SleepInsightsPage(showAppBar: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const SleepEntryPage()),
        ).then((_) => _loadData()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecordsListView(ColorScheme colorScheme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('最近 7 天'),
                selected: _selectedDays == 7,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDays = 7);
                    _loadData();
                  }
                },
              ),
              SizedBox(width: 16.sp),
              ChoiceChip(
                label: const Text('最近 30 天'),
                selected: _selectedDays == 30,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedDays = 30);
                    _loadData();
                  }
                },
              ),
            ],
          ),
        ),
        _buildSummaryCard(colorScheme),
        Expanded(
          child: _records.isEmpty
              ? Center(
                  child: Text(
                    '暂无睡眠记录',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.sp),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    return _buildRecordItem(r, colorScheme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.sp),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '平均睡眠时长',
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            '${_avgSleep.toStringAsFixed(1)} 小时',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('记录天数', '${_records.length} 天', colorScheme),
              _buildSummaryItem(
                '达标率',
                '${(_records.where((e) => e.durationHours >= 8).length / (_records.isEmpty ? 1 : _records.length) * 100).toInt()}%',
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onPrimary.withOpacity(0.8),
            fontSize: 12.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(SleepRecord r, ColorScheme colorScheme) {
    final startTime = DateTime.parse(r.startTime);
    final endTime = DateTime.parse(r.endTime);

    return Card(
      margin: EdgeInsets.only(bottom: 12.sp),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.sp),
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
        leading: Container(
          padding: EdgeInsets.all(8.sp),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.bedtime, color: colorScheme.onSecondaryContainer),
        ),
        title: Text(
          DateFormat('MM月dd日').format(startTime),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
        ),
        subtitle: Text(
          '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13.sp,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${r.durationHours.toStringAsFixed(1)}h',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            if (r.durationHours < 8)
              Text(
                '不足',
                style: TextStyle(color: Colors.orange, fontSize: 10.sp),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
