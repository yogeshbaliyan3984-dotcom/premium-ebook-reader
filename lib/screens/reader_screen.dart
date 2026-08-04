import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../services/storage_service.dart';
import '../models/bookmark.dart';
import '../models/note.dart';
import '../widgets/reading_mode_overlay.dart';

class ReaderScreen extends StatefulWidget {
  final String bookId;
  final String filePath;
  final String title;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.filePath,
    required this.title,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  PDFViewController? _pdfController;

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _isFullscreen = false;
  bool _isVerticalScroll = false;
  ReadingMode _readingMode = ReadingMode.light;

  double? _originalBrightness;
  Timer? _progressSaveDebounce;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
    _enableWakelock();
    _captureOriginalBrightness();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _restoreBrightness();
    _progressSaveDebounce?.cancel();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    await WakelockPlus.enable();
  }

  Future<void> _captureOriginalBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      } else {
        await ScreenBrightness().resetScreenBrightness();
      }
    } catch (_) {}
  }

  void _restoreProgress() {
    final saved = StorageService.getProgress(widget.bookId);
    if (saved != null) {
      _currentPage = saved.lastPage;
    }
  }

  void _saveProgress() {
    _progressSaveDebounce?.cancel();
    _progressSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      StorageService.saveProgress(
        bookId: widget.bookId,
        lastPage: _currentPage,
        totalPages: _totalPages,
      );
    });
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    SystemChrome.setEnabledSystemUIMode(
      _isFullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _addQuickBookmark() {
    final bookmark = Bookmark(
      bookId: widget.bookId,
      pageNumber: _currentPage,
      label: 'Page ${_currentPage + 1}',
      createdAt: DateTime.now(),
    );
    StorageService.addBookmark(bookmark);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bookmarked page ${_currentPage + 1}')),
    );
  }

  void _showAddNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add note - Page ${_currentPage + 1}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write your note...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                StorageService.addNote(Note(
                  bookId: widget.bookId,
                  pageNumber: _currentPage,
                  text: controller.text.trim(),
                  createdAt: DateTime.now(),
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _cycleReadingMode() {
    setState(() {
      _readingMode = ReadingMode.values[
          (_readingMode.index + 1) % ReadingMode.values.length];
    });
  }

  Color get _backgroundColor {
    switch (_readingMode) {
      case ReadingMode.dark:
        return Colors.black;
      case ReadingMode.sepia:
        return const Color(0xFFF4ECD8);
      case ReadingMode.light:
        return Colors.white;
    }
  }

  IconData get _readingModeIcon {
    switch (_readingMode) {
      case ReadingMode.dark:
        return Icons.dark_mode;
      case ReadingMode.sepia:
        return Icons.wb_twighlight;
      case ReadingMode.light:
        return Icons.light_mode;
    }
  }

  void _jumpToPage(int page) {
    _pdfController?.setPage(page);
  }

  void _openPageSlider() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        int tempPage = _currentPage;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Page ${tempPage + 1} of $_totalPages'),
                Slider(
                  value: tempPage.toDouble(),
                  min: 0,
                  max: (_totalPages - 1).clamp(0, double.infinity).toDouble(),
                  divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                  label: '${tempPage + 1}',
                  onChanged: (v) => setSheetState(() => tempPage = v.round()),
                  onChangeEnd: (v) => _jumpToPage(v.round()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(_readingModeIcon),
                  tooltip: 'Reading mode',
                  onPressed: _cycleReadingMode,
                ),
                IconButton(
                  icon: Icon(
                    _isVerticalScroll ? Icons.swap_horiz : Icons.swap_vert,
                  ),
                  tooltip: _isVerticalScroll
                      ? 'Switch to page-flip'
                      : 'Switch to scroll mode',
                  onPressed: () =>
                      setState(() => _isVerticalScroll = !_isVerticalScroll),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Bookmark this page',
                  onPressed: _isReady ? _addQuickBookmark : null,
                ),
                IconButton(
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'Add note',
                  onPressed: _isReady ? _showAddNoteDialog : null,
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Fullscreen',
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
      body: Stack(
        children: [
          ReadingModeOverlay(
            mode: _readingMode,
            child: PDFView(
              filePath: widget.filePath,
              swipeHorizontal: !_isVerticalScroll,
              pageFling: true,
              pageSnap: true,
              autoSpacing: true,
              enableSwipe: true,
              fitPolicy: FitPolicy.BOTH,
              nightMode: false,
              defaultPage: _currentPage,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
              },
              onViewCreated: (controller) {
                _pdfController = controller;
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page ?? _currentPage;
                  _totalPages = total ?? _totalPages;
                });
                _saveProgress();
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load PDF: $error')),
                );
              },
              onPageError: (page, error) {
                debugPrint('Error on page $page: $error');
              },
            ),
          ),
          if (!_isReady)
            const Center(child: CircularProgressIndicator()),
          if (_isFullscreen)
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.grey),
                onPressed: _toggleFullscreen,
              ),
            ),
        ],
      ),
      bottomNavigationBar: (_isReady && !_isFullscreen)
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text('${_currentPage + 1} / $_totalPages'),
                    Expanded(
                      child: Slider(
                        value: _currentPage.toDouble().clamp(
                            0, (_totalPages - 1).toDouble().clamp(0, 999999)),
                        min: 0,
                        max: (_totalPages - 1)
                            .clamp(0, double.infinity)
                            .toDouble(),
                        onChanged: (v) => _jumpToPage(v.round()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.view_agenda_outlined),
                      tooltip: 'Page thumbnails / jump',
                      onPressed: _openPageSlider,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
