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
      if (jsonData.containsKey('type') && jsonData['type'] == 'obsidian_sync') {
        // If it's a complete JSON object, process it directly
        ObsidianSync.handleFrameData(dataString);
      }
    } catch (e) {
      // If it's not a complete JSON object, it's probably a chunk
      _handleDataChunk(data);
    }
  }

  void _handleDataChunk(List<int> chunk) {
    // Assuming the first 4 bytes are a unique identifier for the chunked message
    if (chunk.length < 4) return; // Ignore if chunk is too small

    Uint8List identifier = Uint8List.fromList(chunk.sublist(0, 4));
    String id = identifier.toString();

    if (!_dataBuffer.containsKey(id)) {
      _dataBuffer[id] = [];
    }

    _dataBuffer[id].addAll(chunk.sublist(4));

    // Check if we have a complete message
    if (_isMessageComplete(id)) {
      String completeMessage = String.fromCharCodes(_dataBuffer[id]);
      ObsidianSync.handleFrameData(completeMessage);
      _dataBuffer.remove(id);
    }
  }

  bool _isMessageComplete(String id) {
    if (!_dataBuffer.containsKey(id)) return false;

    String message = String.fromCharCodes(_dataBuffer[id]);
    try {
      json.decode(message);
      return true;
    } catch (e) {
      return false;
    }
  }
}