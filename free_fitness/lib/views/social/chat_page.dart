import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../apis/social_api_service.dart';
import '../../core/constants/constants.dart';
import '../../models/social.dart';
import '../../models/user_state.dart';

class ChatPage extends StatefulWidget {
  final User friend;
  const ChatPage({super.key, required this.friend});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // 使用 ValueNotifier 监听消息列表，减少 setState 调用点
  final ValueNotifier<List<ChatMessage>> _messagesNotifier =
      ValueNotifier<List<ChatMessage>>([]);

  Timer? _pollingTimer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadHistory();
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _messagesNotifier.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadHistory(silent: true);
      }
    });
  }

  Future<void> _loadHistory({bool silent = false}) async {
    try {
      final history = await SocialApiService.getChatHistory(
        CacheUser.userId,
        widget.friend.userId!,
        showLoading: false,
      );
      if (mounted) {
        _messagesNotifier.value = history;
        if (!silent) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      print("加载历史失败: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? imagePath}) async {
    if (_controller.text.isEmpty && imagePath == null) return;

    final msgContent = imagePath ?? _controller.text;
    final msg = ChatMessage(
      senderId: CacheUser.userId,
      receiverId: widget.friend.userId!,
      messageType: imagePath != null ? "IMAGE" : "TEXT",
      content: msgContent,
      gmtCreate: DateTime.now().toIso8601String(),
    );

    if (mounted) _controller.clear();
    try {
      await SocialApiService.sendMessage(msg);
      if (mounted) _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("发送失败: $e")));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _sendMessage(imagePath: image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friend.userName)),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _messagesNotifier,
              builder: (context, messages, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(10.sp),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == CacheUser.userId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.sp),
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        constraints: BoxConstraints(maxWidth: 0.7.sw),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[800],
          borderRadius: BorderRadius.circular(15.sp),
        ),
        child: msg.messageType == "IMAGE"
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10.sp),
                child: Image.network(
                  msg.content,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              )
            : Text(msg.content, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(10.sp),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "发送消息...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
              onPressed: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}
