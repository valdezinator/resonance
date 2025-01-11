import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class EncryptedStorageService {
  static final EncryptedStorageService _instance = EncryptedStorageService._internal();
  factory EncryptedStorageService() => _instance;
  
  EncryptedStorageService._internal();

  final _storage = const FlutterSecureStorage();
  static const _keyName = 'music_encryption_key';
  Key? _key;
  IV? _iv;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Get or generate encryption key
      String? storedKey = await _storage.read(key: _keyName);
      if (storedKey == null) {
        final key = Key.fromSecureRandom(32);
        await _storage.write(key: _keyName, value: base64Encode(key.bytes));
        _key = key;
      } else {
        _key = Key(base64Decode(storedKey));
      }
      _iv = IV.fromLength(16);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing encryption service: $e');
      rethrow;
    }
  }

  Future<String> getFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName.enc';
  }

  Future<String> encryptAndSave(List<int> data, String fileName) async {
    if (!_isInitialized || _key == null || _iv == null) {
      throw Exception('EncryptedStorageService not initialized');
    }

    final encrypter = Encrypter(AES(_key!));
    final encrypted = encrypter.encryptBytes(data, iv: _iv!);
    
    final filePath = await getFilePath(fileName);
    final file = File(filePath);
    await file.writeAsBytes(encrypted.bytes);
    
    print('Saved encrypted file to: $filePath');
    return filePath;
  }

  Future<List<int>> decryptFile(String filePath) async {
    if (!_isInitialized || _key == null || _iv == null) {
      throw Exception('EncryptedStorageService not initialized');
    }

    print('Attempting to decrypt file at: $filePath');
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Encrypted file not found at: $filePath');
    }

    final bytes = await file.readAsBytes();
    final encrypter = Encrypter(AES(_key!));
    return encrypter.decryptBytes(Encrypted(bytes), iv: _iv!);
  }

  Future<bool> isDownloaded(String fileName) async {
    final filePath = await getFilePath(fileName);
    final file = File(filePath);
    final exists = await file.exists();
    print('Checking if file exists: $exists at ${file.path}');
    return exists;
  }
}
