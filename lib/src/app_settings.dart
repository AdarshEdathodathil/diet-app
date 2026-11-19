import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  String clinicName = '';
  String dietitianName = 'Dt Haritha';
  String credentials = '';
  String _pinSalt = '';
  String _pinHash = '';
  bool loaded = false;

  bool get pinEnabled => _pinHash.isNotEmpty && _pinSalt.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values.byName(
      prefs.getString('theme_mode') ?? 'system',
    );
    clinicName = prefs.getString('clinic_name') ?? '';
    dietitianName = prefs.getString('dietitian_name') ?? 'Dt Haritha';
    credentials = prefs.getString('credentials') ?? '';
    _pinSalt = prefs.getString('pin_salt') ?? '';
    _pinHash = prefs.getString('pin_hash') ?? '';
    loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', value.name);
    notifyListeners();
  }

  Future<void> saveProfile({
    required String clinic,
    required String dietitian,
    required String qualification,
  }) async {
    clinicName = clinic.trim();
    dietitianName = dietitian.trim();
    credentials = qualification.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clinic_name', clinicName);
    await prefs.setString('dietitian_name', dietitianName);
    await prefs.setString('credentials', credentials);
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _pinSalt = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    _pinHash = _hash(pin, _pinSalt);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin_salt', _pinSalt);
    await prefs.setString('pin_hash', _pinHash);
    notifyListeners();
  }

  bool verifyPin(String pin) => pinEnabled && _hash(pin, _pinSalt) == _pinHash;

  Future<void> clearPin() async {
    _pinSalt = '';
    _pinHash = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pin_salt');
    await prefs.remove('pin_hash');
    notifyListeners();
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
