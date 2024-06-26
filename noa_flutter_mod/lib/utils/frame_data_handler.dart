// lib/utils/frame_data_handler.dart

import 'dart:convert';
import 'dart:typed_data';
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

    Uint8List identifier = Uint8List.fromList(chunk.sublist(0, 4));
    String id = identifier.toString();

    _dataBuffer[id] ??= []; // Initialize the list if it doesn't exist
    _dataBuffer[id]!.addAll(chunk.sublist(4)); // Now we can use ! as we're sure it's not null

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

    List<int> buffer = _dataBuffer[id]!;
    if (buffer.isEmpty) return false;

    String message = String.fromCharCodes(buffer);
    try {
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