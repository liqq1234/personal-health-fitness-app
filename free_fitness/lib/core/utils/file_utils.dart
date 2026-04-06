import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  /// 获取应用文档根目录
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 获取指定子目录的完整路径，不存在则创建
  static Future<Directory> _getDir(String subDir) async {
    final root = await _localPath;
    final path = p.join(root, subDir);
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// 将外部文件复制到应用本地目录，并返回相对路径
  static Future<String> saveFileLocally(File sourceFile, String subDir) async {
    final directory = await _getDir(subDir);
    final fileName = p.basename(sourceFile.path);
    final targetPath = p.join(directory.path, fileName);

    // 复制文件
    await sourceFile.copy(targetPath);

    // 返回相对路径，例如 "avatars/my_pic.jpg"
    return p.join(subDir, fileName);
  }

  /// 根据相对路径还原完整路径
  static Future<String> getAbsolutePath(String relativePath) async {
    // 如果已经是完整路径（以 / 开头或包含 :），直接返回
    if (relativePath.startsWith('/') || relativePath.contains(':')) {
      return relativePath;
    }
    final root = await _localPath;
    return p.join(root, relativePath);
  }
}
