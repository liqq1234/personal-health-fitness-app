import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/storage/db_training_helper.dart';
import '../../models/training_state.dart';

class TrainingContentSelector extends StatefulWidget {
  const TrainingContentSelector({super.key});

  @override
  State<TrainingContentSelector> createState() =>
      _TrainingContentSelectorState();
}

class _TrainingContentSelectorState extends State<TrainingContentSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DBTrainingHelper _dbHelper = DBTrainingHelper();

  List<TrainingPlan> _plans = [];
  List<TrainingGroup> _groups = [];
  String _searchKeyword = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  Future<void> _loadContent() async {
    final plans = await _dbHelper.searchPlanWithGroups(
      planName: _searchKeyword,
    );
    final groups = await _dbHelper.searchGroupWithActions(
      groupName: _searchKeyword,
    );
    setState(() {
      _plans = plans.map((pwg) => pwg.plan).toList();
      _groups = groups.map((gwa) => gwa.group).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.7.sh,
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '搜索计划或训练组...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() => _searchKeyword = val);
              _loadContent();
            },
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: '计划'),
              Tab(text: '训练组'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPlanList(), _buildGroupList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList() {
    if (_plans.isEmpty) return const Center(child: Text('暂无数据'));
    return ListView.builder(
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return ListTile(
          title: Text(plan.planName),
          subtitle: Text('${plan.planLevel} - ${plan.planCategory}'),
          onTap: () => Navigator.pop(context, {
            'type': 'PLAN',
            'id': plan.planId,
            'name': plan.planName,
          }),
        );
      },
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) return const Center(child: Text('暂无数据'));
    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return ListTile(
          title: Text(group.groupName),
          subtitle: Text('${group.groupLevel} - ${group.groupCategory}'),
          onTap: () => Navigator.pop(context, {
            'type': 'GROUP',
            'id': group.groupId,
            'name': group.groupName,
          }),
        );
      },
    );
  }
}
