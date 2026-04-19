import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/dietary_state.dart';
import '../../core/storage/db_dietary_helper.dart';
import '../../core/constants/constants.dart';
import 'package:image_picker/image_picker.dart';

class AiDietaryPage extends StatefulWidget {
  const AiDietaryPage({super.key});

  @override
  State<AiDietaryPage> createState() => _AiDietaryPageState();
}

class _AiDietaryPageState extends State<AiDietaryPage> {
  final TextEditingController _controller = TextEditingController();
  final DBDietaryHelper _dbHelper = DBDietaryHelper();
  bool _isParsing = false;
  AiParseResponse? _result;
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _handleParse() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isParsing = true);
    try {
      // If we have an image, we should theoretically call a vision API
      // For now, we simulate AI parsing the image if present, or just text
      final response = await _dbHelper.parseAiText(
        _controller.text + (_image != null ? " [Image Attached]" : ""),
      );
      setState(() {
        _result = response;
        _isParsing = false;
      });
    } catch (e) {
      setState(() => _isParsing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('解析失败，请检查网络或重试')));
    }
  }

  Future<void> _saveToDiary() async {
    if (_result == null || _result!.foods.isEmpty) return;

    // Convert ParsedFood to DailyFoodItem and save
    List<DailyFoodItem> items = _result!.foods.map((pf) {
      final now = DateTime.now();
      return DailyFoodItem(
        userId: CacheUser.userId,
        foodId: 0, // Placeholder
        servingInfoId: 0, // Placeholder
        foodIntakeSize: pf.amount,
        mealCategory: 'Lunch', // Default
        date:
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
        originalText: pf.foodName,
      );
    }).toList();

    try {
      await _dbHelper.insertDailyFoodItemList(items);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('成功记录到饮食日记')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('确认失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 智能饮食记录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '描述你吃了什么：',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '例如：中午吃了300g番茄炒鸡蛋，一碗米饭',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isParsing ? null : _handleParse,
                    icon: _isParsing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isParsing ? '解析中...' : '开始解析'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: () async {
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (photo != null) {
                      setState(() => _image = photo);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('照片已拍摄，AI 准备好识别内容了')),
                      );
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  tooltip: '拍照识别',
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_image!.path),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 30),
              const Divider(),
              const Text(
                '解析结果：',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._result!.foods.map(
                (pf) => Card(
                  child: ListTile(
                    title: Text(pf.foodName),
                    subtitle: Text(
                      '份量: ${pf.amount}${pf.unit} | 热量: ${pf.calories} kcal',
                    ),
                    trailing: Text('蛋白: ${pf.protein}g'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '总计: ${_result!.totalCalories} kcal',
                style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveToDiary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('确认并加入日记'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
