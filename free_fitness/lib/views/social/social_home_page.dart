import 'package:flutter/material.dart';
import '../../models/social.dart';
import '../../core/storage/db_social_helper.dart';
import '../../core/constants/constants.dart';

class SocialHomePage extends StatefulWidget {
  const SocialHomePage({super.key});

  @override
  State<SocialHomePage> createState() => _SocialHomePageState();
}

class _SocialHomePageState extends State<SocialHomePage> {
  List<SocialMoment> _moments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    try {
      final moments = await DBSocialHelper.getTimeline(CacheUser.userId);
      setState(() {
        _moments = moments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showToast("加载动态失败");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康圈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // TODO: Search and add friends
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTimeline,
              child: ListView.builder(
                itemCount: _moments.length,
                itemBuilder: (context, index) {
                  final moment = _moments[index];
                  return _buildMomentCard(moment);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open post moment page
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildMomentCard(SocialMoment moment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(moment.userId.toString())),
            title: Text('用户 ${moment.userId}'),
            subtitle: Text(moment.gmtCreate),
          ),
          if (moment.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(moment.content, style: const TextStyle(fontSize: 16)),
            ),
          if (moment.images != null && moment.images!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  moment.images!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on ScaffoldMessengerState {
  void showToast(String msg) {
    showSnackBar(SnackBar(content: Text(msg)));
  }
}
