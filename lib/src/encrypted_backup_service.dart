import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import 'assessment_repository.dart';

class EncryptedBackupService {
  const EncryptedBackupService();

  Future<File> create(AssessmentRepository repository, String password) async {
    final data = await repository.backupData();
    final contents = await encrypt(data, password);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/dt_haritha_${_date(DateTime.now())}.dthbackup',
    );
    await file.writeAsString(contents, flush: true);
    return file;
  }

  Future<String> encrypt(Map<String, dynamic> data, String password) async {
    if (password.length < 8) {
      throw const FormatException(
        'Backup password must have at least 8 characters.',
      );
    }
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(password, salt);
    final algorithm = AesGcm.with256bits();
    final box = await algorithm.encrypt(
      utf8.encode(jsonEncode(data)),
      secretKey: key,
      nonce: nonce,
    );
    final envelope = {
      'format': 'dt_haritha_backup',
      'version': 1,
      'kdf': 'pbkdf2-sha256-120000',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return jsonEncode(envelope);
  }

  Future<void> restore(
    AssessmentRepository repository,
    File file,
    String password,
  ) async {
    final data = await decrypt(await file.readAsString(), password);
    await repository.restoreBackupData(data);
  }

  Future<Map<String, dynamic>> decrypt(String contents, String password) async {
    try {
      final envelope = (jsonDecode(contents) as Map).cast<String, dynamic>();
      if (envelope['format'] != 'dt_haritha_backup' ||
          envelope['version'] != 1) {
        throw const FormatException('Unsupported backup format.');
      }
      final salt = base64Decode(envelope['salt'] as String);
      final key = await _deriveKey(password, salt);
      final box = SecretBox(
        base64Decode(envelope['ciphertext'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        mac: Mac(base64Decode(envelope['mac'] as String)),
      );
      final clear = await AesGcm.with256bits().decrypt(box, secretKey: key);
      return (jsonDecode(utf8.decode(clear)) as Map).cast<String, dynamic>();
    } on SecretBoxAuthenticationError {
      throw const FormatException('Incorrect password or damaged backup.');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  List<int> _randomBytes(int length) =>
      List.generate(length, (_) => Random.secure().nextInt(256));

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
