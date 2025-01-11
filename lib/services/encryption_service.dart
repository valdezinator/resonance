import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final String _key = 'your-32-char-secret-key-here!!!!!'; // Change this!
  
  static final key = Key(utf8.encode(_key));
  static final iv = IV.fromLength(16);
  static final encrypter = Encrypter(AES(key));

  static Uint8List encryptBytes(List<int> bytes) {
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    return encrypted.bytes;
  }

  static List<int> decryptBytes(List<int> encryptedBytes) {
    final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));
    return encrypter.decryptBytes(encrypted, iv: iv);
  }

  static String encryptJson(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    return encrypted.base64;
  }

  static Map<String, dynamic> decryptJson(String encryptedString) {
    final encrypted = Encrypted.fromBase64(encryptedString);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return json.decode(decrypted);
  }
}
