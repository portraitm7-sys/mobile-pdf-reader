import 'package:flutter/material.dart';

import '../models/pdf_item.dart';
import 'library_service.dart';

class PdfLibraryController extends ChangeNotifier {
  PdfLibraryController(this._service);

  final LibraryService _service;

  final List<PdfItem> _items = [];

  bool loading = true;
  bool darkMode = false;

  List<PdfItem> get recents {
    final list = [..._items];

    list.sort(
      (a, b) => b.lastOpenedAt.compareTo(
        a.lastOpenedAt,
      ),
    );

    return list;
  }

  List<PdfItem> get favorites {
    final list = _items
        .where((item) => item.isFavorite)
        .toList();

    list.sort(
      (a, b) => b.lastOpenedAt.compareTo(
        a.lastOpenedAt,
      ),
    );

    return list;
  }

  Future<void> init() async {
    loading = true;

    notifyListeners();

    _items
      ..clear()
      ..addAll(
        await _service.loadLibrary(),
      );

    darkMode =
        await _service.loadDarkMode();

    loading = false;

    notifyListeners();
  }

  PdfItem? byId(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  Future<PdfItem?> importPdf() async {
    final item =
        await _service.pickAndImportPdf();

    if (item == null) {
      return null;
    }

    _items.removeWhere(
      (existing) =>
          existing.path == item.path,
    );

    _items.insert(
      0,
      item,
    );

    await _save();

    notifyListeners();

    return item;
  }

  Future<void> markOpened(
    PdfItem item,
  ) async {
    final index = _items.indexWhere(
      (value) => value.id == item.id,
    );

    if (index == -1) {
      return;
    }

    _items[index] = _items[index].copyWith(
      lastOpenedAt: DateTime.now(),
    );

    await _save();

    notifyListeners();
  }

  Future<void> saveLastPage(
    String id,
    int page,
  ) async {
    if (page < 1) {
      return;
    }

    final index = _items.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return;
    }

    if (_items[index].lastPage == page) {
      return;
    }

    _items[index] = _items[index].copyWith(
      lastPage: page,
    );

    await _save();

    notifyListeners();
  }

  Future<void> toggleFavorite(
    String id,
  ) async {
    final index = _items.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return;
    }

    _items[index] = _items[index].copyWith(
      isFavorite:
          !_items[index].isFavorite,
    );

    await _save();

    notifyListeners();
  }

  Future<void> deletePdf(
    String id,
  ) async {
    final index = _items.indexWhere(
      (item) => item.id == id,
    );

    if (index == -1) {
      return;
    }

    final item = _items[index];

    await _service.deleteLocalFile(item);

    _items.removeAt(index);

    await _save();

    notifyListeners();
  }

  Future<void> setDarkMode(
    bool value,
  ) async {
    if (darkMode == value) {
      return;
    }

    darkMode = value;

    notifyListeners();

    await _service.saveDarkMode(value);
  }

  Future<void> _save() async {
    await _service.saveLibrary(_items);
  }
}
