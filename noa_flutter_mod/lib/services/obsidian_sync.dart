// lib/services/obsidian_sync.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ObsidianSync {
  static const String obsidianVaultPath = '/obsidian/professor synapse/_📭 Inbox';

  static Future<void> saveProcessedData(String action, Map<String, dynamic> payload, int timestamp) async {
    final directory = await getApplicationDocumentsDirectory();
    final obsidianPath = '${directory.path}$obsidianVaultPath';
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

    // Ensure the Obsidian vault directory exists
    await Directory(obsidianPath).create(recursive: true);

    String noteContent = '# Frame Capture - $formattedDate\n\n';

    switch (action) {
      case 'capture_text':
        if (payload['image'] != null) {
          await _saveFile(obsidianPath, 'frame_image_$formattedDate.jpg', payload['image']);
          noteContent += '![Captured Image](frame_image_$formattedDate.jpg)\n\n';
        }
        noteContent += '## Captured Text\n${payload['text']}\n\n';
        break;
      case 'transcribe_audio':
        if (payload['audio'] != null) {
          await _saveFile(obsidianPath, 'frame_audio_$formattedDate.wav', payload['audio']);
          noteContent += '[Audio Recording](frame_audio_$formattedDate.wav)\n\n';
        }
        noteContent += '## Audio Transcription\n${payload['transcription']}\n\n';
        break;
      case 'explain_image':
        if (payload['image'] != null) {
          await _saveFile(obsidianPath, 'frame_image_$formattedDate.jpg', payload['image']);
          noteContent += '![Explained Image](frame_image_$formattedDate.jpg)\n\n';
        }
        noteContent += '## Image Explanation\n${payload['explanation']}\n\n';
        break;
      case 'general_query':
        noteContent += '## Query Response\n${payload['response']}\n\n';
        if (payload['image'] != null) {
          await _saveFile(obsidianPath, 'frame_image_$formattedDate.jpg', payload['image']);
          noteContent += '![Related Image](frame_image_$formattedDate.jpg)\n\n';
        }
        break;
      default:
        // Fallback for unknown action types or legacy data
        await _handleLegacyData(obsidianPath, formattedDate, payload);
        return;
    }

    // Create markdown file
    await _createMarkdownFile(obsidianPath, formattedDate, noteContent);
  }

  static Future<void> _saveFile(String path, String filename, String base64Data) async {
    final file = File('$path/$filename');
    await file.writeAsBytes(base64Decode(base64Data));
  }

  static Future<void> _createMarkdownFile(String path, String formattedDate, String content) async {
    final markdownFile = File('$path/frame_capture_$formattedDate.md');
    await markdownFile.writeAsString(content);
  }

  // Method to handle legacy data format for backwards compatibility
  static Future<void> _handleLegacyData(String path, String formattedDate, Map<String, dynamic> payload) async {
    if (payload['image'] != null) {
      await _saveFile(path, 'frame_image_$formattedDate.jpg', payload['image']);
    }
    if (payload['audio'] != null) {
      await _saveFile(path, 'frame_audio_$formattedDate.wav', payload['audio']);
    }
    if (payload['imu'] != null) {
      await _createMarkdownFile(path, formattedDate, '''
# Frame Data Capture - $formattedDate

## IMU Data
Roll: ${payload['imu']['roll']}
Pitch: ${payload['imu']['pitch']}
Heading: ${payload['imu']['heading']}

![Frame Capture](frame_image_$formattedDate.jpg)

[Audio Recording](frame_audio_$formattedDate.wav)
''');
    }
  }
}