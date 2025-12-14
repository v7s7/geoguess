import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MistakesProvider extends ChangeNotifier {
  List<String> _mistakenCca2s = [];

  List<String> get mistakenCca2s => _mistakenCca2s;
  bool get hasMistakes => _mistakenCca2s.isNotEmpty;

  MistakesProvider() {
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('mistakes_list');
    if (data != null) {
      _mistakenCca2s = List<String>.from(json.decode(data));
      notifyListeners();
    }
  }

  Future<void> addMistake(String cca2) async {
    if (!_mistakenCca2s.contains(cca2)) {
      _mistakenCca2s.add(cca2);
      await _saveMistakes();
      notifyListeners();
    }
  }

  Future<void> removeMistake(String cca2) async {
    if (_mistakenCca2s.contains(cca2)) {
      _mistakenCca2s.remove(cca2);
      await _saveMistakes();
      notifyListeners();
    }
  }

  Future<void> _saveMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mistakes_list', json.encode(_mistakenCca2s));
  }
}