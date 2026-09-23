import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/pdf_item.dart';
import '../services/pdf_library_controller.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.item,
    required this.libraryController,
  });

  final PdfItem item;
  final PdfLibraryController libraryController;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final PdfViewerController _viewerController = PdfViewerController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final PdfTextSearcher _textSearcher;
  Timer? _pageSaveDebounce;

  int _currentPage = 1;
  int _pageCount = 0;
  bool _searching = false;

  @override
  void initState() {
    super.initState();

    _currentPage =
        widget.item.lastPage < 1 ? 1 : widget.item.lastPage;

    _textSearcher = PdfTextSearcher(_viewerController)
      ..addListener(_onSearchChanged);

    unawaited(
      widget.libraryController.markOpened(widget.item),
    );
  }

  @override
  void dispose() {
    _pageSaveDebounce?.cancel();

    unawaited(
      widget.libraryController.saveLastPage(
        widget.item.id,
        _currentPage,
      ),
    );

    _textSearcher.dispose();
    _searchController.dispose();
    _searchFocus.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onPageChanged(int? page) {
    if (page == null || page < 1) return;

    setState(() {
      _currentPage = page;
    });

    _pageSaveDebounce?.cancel();

    _pageSaveDebounce =
        Timer(const Duration(milliseconds: 500), () {
      unawaited(
        widget.libraryController.saveLastPage(
          widget.item.id,
          page,
        ),
      );
    });
  }

  void _runSearch(String value) {
    final query = value.trim();

    if (query.isEmpty) {
      _textSearcher.resetTextSearch();
      return;
    }

    _textSearcher.startTextSearch(
      query,
      caseInsensitive: true,
      goToFirstMatch: true,
      searchImmediately: true,
    );
  }

  Future<void> _showJumpToPage() async {
    if (_pageCount < 1) return;

    final controller = TextEditingController(
      text: _currentPage.toString(),
    );

    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to page'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - $_pageCount',
            suffixText: '/ $_pageCount',
          ),
          onSubmitted: (value) {
            Navigator.pop(
              context,
              int.tryParse(value),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                int.tryParse(controller.text),
              );
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (page == null ||
        page < 1 ||
        page > _pageCount) {
      return;
    }

    await _viewerController.goToPage(
      pageNumber: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item =
        widget.libraryController.byId(widget.item.id) ??
            widget.item;

    final currentMatch = _textSearcher.currentIndex;
    final matches = _textSearcher.matches.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: _searching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                textInputAction:
                    TextInputAction.search,
                decoration:
                    const InputDecoration(
                  hintText: 'Search in PDF…',
                  border: InputBorder.none,
                ),
                onSubmitted: _runSearch,
              )
            : Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (_searching) ...[
            if (_textSearcher.isSearching)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            if (!_textSearcher.isSearching &&
                _searchController.text
                    .trim()
                    .isNotEmpty)
              Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 6,
                  ),
                  child: Text(
                    matches == 0
                        ? '0 / 0'
                        : '${(currentMatch ?? 0) + 1} / $matches',
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Previous match',
              onPressed: matches == 0
                  ? null
                  : () => _textSearcher
                      .goToPrevMatch(),
              icon: const Icon(
                Icons.keyboard_arrow_up_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Next match',
              onPressed: matches == 0
                  ? null
                  : () => _textSearcher
                      .goToNextMatch(),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Close search',
              onPressed: () {
                _textSearcher
                    .resetTextSearch();
                _searchController.clear();

                setState(() {
                  _searching = false;
                });
              },
              icon: const Icon(
                Icons.close_rounded,
              ),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Search',
              onPressed: () {
                setState(() {
                  _searching = true;
                });

                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  _searchFocus.requestFocus();
                });
              },
              icon: const Icon(
                Icons.search_rounded,
              ),
            ),
            IconButton(
              tooltip: item.isFavorite
                  ? 'Remove favorite'
                  : 'Add favorite',
              onPressed: () {
                widget.libraryController
                    .toggleFavorite(item.id);
              },
              icon: Icon(
                item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Go to page',
              onPressed: _showJumpToPage,
              icon: const Icon(
                Icons.pin_drop_outlined,
              ),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          PdfViewer.file(
            item.path,
            controller: _viewerController,
            initialPageNumber: _currentPage,
            params: PdfViewerParams(
              margin: 8,
              backgroundColor:
                  Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
              onPageChanged:
                  _onPageChanged,
              onViewerReady:
                  (document, controller) {
                if (!mounted) return;

                setState(() {
                  _pageCount =
                      controller.pageCount;

                  _currentPage =
                      controller.pageNumber ??
                          _currentPage;
                });
              },
              pagePaintCallbacks: [
                _textSearcher
                    .pageTextMatchPaintCallback,
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: InkWell(
                onTap: _showJumpToPage,
                borderRadius:
                    BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseSurface
                        .withValues(
                          alpha: 0.90,
                        ),
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: Text(
                    _pageCount == 0
                        ? 'Loading…'
                        : '$_currentPage / $_pageCount',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onInverseSurface,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
