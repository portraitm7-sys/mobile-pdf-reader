import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_item.dart';

class LibraryService {
  static const _libraryKey = 'pdf_library_v1';
  static const _darkModeKey = 'dark_mode_v1';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<PdfItem>> loadLibrary() async {
    final raw = await _prefs.getString(_libraryKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      final items = decoded
          .map(
            (e) => PdfItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .where(
            (item) => File(item.path).existsSync(),
          )
          .toList();

      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLibrary(
    List<PdfItem> items,
  ) async {
    final raw = jsonEncode(
      items.map((e) => e.toJson()).toList(),
    );

    await _prefs.setString(
      _libraryKey,
      raw,
    );
  }

  Future<bool> loadDarkMode() async {
    return await _prefs.getBool(
          _darkModeKey,
        ) ??
        false;
  }

  Future<void> saveDarkMode(
    bool value,
  ) async {
    await _prefs.setBool(
      _darkModeKey,
      value,
    );
  }

  Future<PdfItem?> pickAndImportPdf() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choose a PDF',
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (picked == null) {
      return null;
    }

    final root =
        await getApplicationDocumentsDirectory();

    final pdfDir = Directory(
      p.join(
        root.path,
        'pdfs',
      ),
    );

    if (!pdfDir.existsSync()) {
      await pdfDir.create(
        recursive: true,
      );
    }

    final now = DateTime.now();

    final originalName =
        picked.name.trim().isEmpty
            ? 'document.pdf'
            : picked.name;

    final safeName =
        _sanitizeFileName(originalName);

    final localName =
        '${now.microsecondsSinceEpoch}_$safeName';

    final destination = File(
      p.join(
        pdfDir.path,
        localName,
      ),
    );

    try {
  final bytes = await picked.readAsBytes();

  await destination.writeAsBytes(
    bytes,
    flush: true,
  );
} catch (_) {
  if (destination.existsSync()) {
    await destination.delete();
  }

  rethrow;
    }
    final size =
        await destination.length();

    return PdfItem(
      id: now.microsecondsSinceEpoch
          .toString(),
      name: originalName,
      path: destination.path,
      addedAt: now,
      lastOpenedAt: now,
      sizeBytes: size,
    );
  }

  Future<void> deleteLocalFile(
    PdfItem item,
  ) async {
    final file = File(item.path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  String _sanitizeFileName(
    String value,
  ) {
    final cleaned = value.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    return cleaned
            .toLowerCase()
            .endsWith('.pdf')
        ? cleaned
        : '$cleaned.pdf';
  }
}
