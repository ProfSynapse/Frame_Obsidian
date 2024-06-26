// lib/services/obsidian_sync.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ObsidianSync {
  static const String obsidianVaultPath = '/obsidian/professor synapse/_📭 Inbox';

  static Future<void> handleFrameData(String jsonData) async {
    final data = json.decode(jsonData);
    if (data['type'] != 'obsidian_sync') return;

    final payload = data['payload'];
    final timestamp = DateTime.fromMillisecondsSinceEpoch(payload['timestamp'] * 1000);
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(timestamp);

    final directory = await getApplicationDocumentsDirectory();
    final obsidianPath = '${directory.path}$obsidianVaultPath';

    // Ensure the Obsidian vault directory exists
    await Directory(obsidianPath).create(recursive: true);

    // Save image
    await _saveFile(obsidianPath, 'frame_image_$formattedDate.jpg', payload['image']);

    // Save audio
    await _saveFile(obsidianPath, 'frame_audio_$formattedDate.wav', payload['audio']);

    // Create markdown file
    await _createMarkdownFile(obsidianPath, formattedDate, payload['imu']);
  }

  static Future<void> _saveFile(String path, String filename, String base64Data) async {
    final file = File('$path/$filename');
    await file.writeAsBytes(base64Decode(base64Data));
  }

  static Future<void> _createMarkdownFile(String path, String formattedDate, Map<String, dynamic> imuData) async {
    final markdownFile = File('$path/frame_data_$formattedDate.md');
    await markdownFile.writeAsString('''
# Frame Data Capture - $formattedDate

## IMU Data
Roll: ${imuData['roll']}
Pitch: ${imuData['pitch']}
Heading: ${imuData['heading']}

![Frame Capture](frame_image_$formattedDate.jpg)

[Audio Recording](frame_audio_$formattedDate.wav)
''');
  }
}