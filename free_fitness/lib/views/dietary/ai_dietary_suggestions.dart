import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/storage/db_health_helper.dart';
import '../../../core/constants/constants.dart';

class AiDietarySuggestions extends StatefulWidget {
  const AiDietarySuggestions({super.key});

  @override
  State<AiDietarySuggestions> createState() => _AiDietarySuggestionsState();
}

class _AiDietarySuggestionsState extends State<AiDietarySuggestions>
    with AutomaticKeepAliveClientMixin {
  final _dbHelper = DBHealthHelper();
  final _storage = GetStorage();
  bool _isLoading = false;
  Map<String, dynamic>? _analysis;

  String get _cacheKey => 'diet_analysis_cache_${CacheUser.userId}';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = _storage.read(_cacheKey);
    if (cached != null) {
      setState(() {
        _analysis = Map<String, dynamic>.from(cached);
      });
    }
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    final response = await _dbHelper.getNutritionAnalysis();
    if (mounted) {
      setState(() {
        if (response != null && response['code'] == 200) {
          _analysis = response['data'];
          _storage.write(_cacheKey, _analysis);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.sp),
            Text('正在深度分析中...', style: TextStyle(color: colorScheme.primary)),
          ],
        ),
      );
    }

    if (_analysis == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80.sp,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            SizedBox(height: 24.sp),
            Text(
              '点击下方按钮，开始 AI 智能饮食分析',
              style: TextStyle(
                fontSize: 15.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 32.sp),
            ElevatedButton.icon(
              onPressed: _loadAnalysis,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成今日饮食建议'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 32.sp,
                  vertical: 12.sp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.sp),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final recommendations = _analysis!['recommendations'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      child: ListView(
        padding: EdgeInsets.all(16.sp),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '实时分析报告',
                style: TextStyle(fontSize: 14.sp, color: colorScheme.outline),
              ),
              TextButton.icon(
                onPressed: _loadAnalysis,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重新分析'),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          _buildHeader(colorScheme),
          SizedBox(height: 24.sp),
          _buildAiAdviceCard(colorScheme, recommendations),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.sp),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 28.sp),
              SizedBox(width: 8.sp),
              Text(
                'AI 营养分析',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Text(
            _analysis!['statusSummary'] ?? '分析中...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '日期: ${DateFormat('yyyy年MM月dd日').format(DateTime.now())}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAdviceCard(ColorScheme colorScheme, List recommendations) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.sp),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.sp),
                Text(
                  '专家建议',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.sp),
            if (recommendations.isEmpty)
              const Text('数据完美或还在分析中，请保持良好的饮食习惯！')
            else
              ...recommendations.map(
                (advice) => Padding(
                  padding: EdgeInsets.only(bottom: 12.sp),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Expanded(
                        child: MarkdownBody(
                          data: advice.toString(),
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(fontSize: 14.sp, height: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
