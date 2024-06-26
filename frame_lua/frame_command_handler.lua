// frame_data_handler.dart

import 'dart:convert';
import '../services/obsidian_sync.dart';

class FrameDataHandler {
  static const int CHUNK_SIZE = 240;
  Map<String, List<int>> _dataBuffer = {};

  void handleBluetoothData(List<int> data) {
    String dataString = String.fromCharCodes(data);
    
    try {
      Map<String, dynamic> jsonData = json.decode(dataString);
      if (jsonData['type'] == 'obsidian_sync') {
        // If it's a complete JSON object, process it directly
        _processFrameData(jsonData);
      }
    } catch (e) {
      // If it's not a complete JSON object, it's probably a chunk
      _handleDataChunk(data);
    }
  }

  void _handleDataChunk(List<int> chunk) {
    if (chunk.length < 4) return; // Ignore if chunk is too small

    String id = String.fromCharCodes(chunk.sublist(0, 4));
    
    _dataBuffer[id] ??= [];
    _dataBuffer[id]!.addAll(chunk.sublist(4));

    // Check if we have a complete message
    if (_isMessageComplete(id)) {
      String completeMessage = String.fromCharCodes(_dataBuffer[id]!);
      Map<String, dynamic> jsonData = json.decode(completeMessage);
      _processFrameData(jsonData);
      _dataBuffer.remove(id);
    }
  }

  bool _isMessageComplete(String id) {
    if (!_dataBuffer.containsKey(id) || _dataBuffer[id] == null) return false;

    try {
      String message = String.fromCharCodes(_dataBuffer[id]!);
      json.decode(message);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _processFrameData(Map<String, dynamic> data) {
    if (data['type'] == 'obsidian_sync') {
      String action = data['action'];
      Map<String, dynamic> payload = data['payload'];
      int timestamp = data['timestamp'];
      
      ObsidianSync.saveProcessedData(action, payload, timestamp);
    }
  }
}