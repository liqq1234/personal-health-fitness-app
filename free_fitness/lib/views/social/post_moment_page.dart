import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../apis/social_api_service.dart';
import '../../core/constants/constants.dart';
import '../../models/social.dart';

class PostMomentPage extends StatefulWidget {
  const PostMomentPage({super.key});

  @override
  State<PostMomentPage> createState() => _PostMomentPageState();
}

class _PostMomentPageState extends State<PostMomentPage> {
  final TextEditingController _controller = TextEditingController();
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_controller.text.trim().isEmpty && _images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("说点什么吧...")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 这里的图片上传逻辑在真实生产环境需要先上传到 OSS/服务器并获取 URL
      // 为了演示，我们这里假设图片内容为 local path（实际后端需要真实的 URL）
      String? imagePaths;
      if (_images.isNotEmpty) {
        imagePaths = _images.map((f) => f.path).join(',');
      }

      final moment = SocialMoment(
        userId: CacheUser.userId,
        content: _controller.text.trim(),
        images: imagePaths,
        gmtCreate: DateTime.now().toIso8601String(),
      );

      await SocialApiService.postMoment(moment);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("发布成功！"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("发布失败: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("记录此刻"),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "发布",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: "这一刻的想法...",
                border: InputBorder.none,
              ),
            ),
            SizedBox(height: 20.sp),
            _buildImageGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.sp,
        mainAxisSpacing: 8.sp,
      ),
      itemCount: _images.length + 1,
      itemBuilder: (context, index) {
        if (index == _images.length) {
          return InkWell(
            onTap: _pickImage,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.add_photo_alternate, color: Colors.grey),
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.sp),
                child: Image.file(_images[index], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => setState(() => _images.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
