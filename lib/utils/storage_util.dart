import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageUtil {
  static const _key = 'saved_timetables';

  static Future<List<TimetableProject>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => TimetableProject.fromMap(jsonDecode(s)))
        .toList();
  }

  static Future<void> save(TimetableProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    // Replace if same id
    final idx = all.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      all[idx] = project;
    } else {
      all.add(project);
    }
    await prefs.setStringList(
        _key, all.map((p) => jsonEncode(p.toMap())).toList());
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.removeWhere((p) => p.id == id);
    await prefs.setStringList(
        _key, all.map((p) => jsonEncode(p.toMap())).toList());
  }
}
