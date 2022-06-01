import 'package:encrypt/encrypt.dart';

import 'encryption_service_contract.dart';

class EncryptionService implements IEncryptionService {
  final Encrypter _encrypter;

  EncryptionService(this._encrypter);

  final IV _iv = IV.fromLength(16);

  @override
  String decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);

    return _encrypter.decrypt(encrypted, iv: _iv);
  }

  @override
  String encrypt(String text) {
    return _encrypter.encrypt(text, iv: _iv).base64;
  }
}
