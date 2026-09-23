import 'package:flutter/material.dart';

import '../models/pdf_item.dart';
import '../services/pdf_library_controller.dart';
import '../widgets/pdf_tile.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final PdfLibraryController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showFavorites = false;

  Future<void> _pickPdf() async {
    final item = await widget.controller.importPdf();

    if (!mounted || item == null) return;

    await _openPdf(item);
  }

  Future<void> _openPdf(PdfItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          item: item,
          libraryController: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        final items = showFavorites
            ? controller.favorites
            : controller.recents;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'PDF Reader',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  controller.setDarkMode(
                    !controller.darkMode,
                  );
                },
                icon: Icon(
                  controller.darkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
              ),
            ],
          ),
          body: controller.loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Recent'),
                              selected: !showFavorites,
                              onSelected: (_) {
                                setState(() {
                                  showFavorites = false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Favorites'),
                              selected: showFavorites,
                              onSelected: (_) {
                                setState(() {
                                  showFavorites = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text(
                                'No PDF files yet',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];

                                return PdfTile(
                                  item: item,
                                  onTap: () => _openPdf(item),
                                  onFavorite: () {
                                    controller.toggleFavorite(
                                      item.id,
                                    );
                                  },
                                  onDelete: () {
                                    controller.deletePdf(
                                      item.id,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton:
              FloatingActionButton.extended(
            onPressed: _pickPdf,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open PDF'),
          ),
        );
      },
    );
  }
}
