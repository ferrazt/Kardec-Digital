import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  static const String _historyKey = 'reading_history';
  static const int _historyLimit = 10;
  static String _pageKey(String pdfPath) => 'page_$pdfPath';

  static Future<void> addToHistory(String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];

    history.remove(pdfPath);
    history.insert(0, pdfPath);

    if (history.length > _historyLimit) {
      history = history.sublist(0, _historyLimit);
    }

    await prefs.setStringList(_historyKey, history);
  }

  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  static Future<void> saveReadingPosition(String pdfPath, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pageKey(pdfPath), page);
  }

  static Future<int> getReadingPosition(String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pageKey(pdfPath)) ?? 0;
  }
}