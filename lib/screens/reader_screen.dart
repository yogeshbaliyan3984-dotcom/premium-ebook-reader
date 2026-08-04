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
      SnackBar(content: Text('Bookmarked page ${_current
