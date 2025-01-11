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

  Future<String> encryptAndSave(List<int> data, String fileName) async {
    if (!_isInitialized || _key == null || _iv == null) {
      throw Exception('EncryptedStorageService not initialized');
    }

    final encrypter = Encrypter(AES(_key!));
    final encrypted = encrypter.encryptBytes(data, iv: _iv!);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.enc');
    await file.writeAsBytes(encrypted.bytes);
    
    return file.path;
  }

  Future<List<int>> decryptFile(String filePath) async {
    if (!_isInitialized || _key == null || _iv == null) {
      throw Exception('EncryptedStorageService not initialized');
    }

    final file = File(filePath);
    final bytes = await file.readAsBytes();
    
    final encrypter = Encrypter(AES(_key!));
    final decrypted = encrypter.decryptBytes(Encrypted(bytes), iv: _iv!);
    
    return decrypted;
  }

  Future<bool> isDownloaded(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.enc');
    return file.exists();
  }
}
