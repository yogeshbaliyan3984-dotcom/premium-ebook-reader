import 'package:hive_flutter/hive_flutter.dart';
import '../models/bookmark.dart';
import '../models/note.dart';
import '../models/reading_progress.dart';

class StorageService {
  static const String _bookmarksBox = 'bookmarks_box';
  static const String _notesBox = 'notes_box';
  static const String _progressBox = 'progress_box';

  static late Box<Bookmark> bookmarks;
  static late Box<Note> notes;
  static late Box<ReadingProgress> progress;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(BookmarkAdapter());
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(ReadingProgressAdapter());

    bookmarks = await Hive.openBox<Bookmark>(_bookmarksBox);
    notes = await Hive.openBox<Note>(_notesBox);
    progress = await Hive.openBox<ReadingProgress>(_progressBox);
  }

  static Future<void> addBookmark(Bookmark b) async {
    await bookmarks.add(b);
  }

  static List<Bookmark> getBookmarksForBook(String bookId) {
    return bookmarks.values.where((b) => b.bookId == bookId).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  static Future<void> deleteBookmark(Bookmark b) async {
    await b.delete();
  }

  static Future<void> addNote(Note n) async {
    await notes.add(n);
  }

  static List<Note> getNotesForBook(String bookId) {
    return notes.values.where((n) => n.bookId == bookId).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  static Future<void> deleteNote(Note n) async {
    await n.delete();
  }

  static Future<void> saveProgress({
    required String bookId,
    required int lastPage,
    required int totalPages,
  }) async {
    final existingKey = progress.keys.firstWhere(
      (key) => progress.get(key)?.bookId == bookId,
      orElse: () => null,
    );

    final entry = ReadingProgress(
      bookId: bookId,
      lastPage: lastPage,
      totalPages: totalPages,
      lastReadAt: DateTime.now(),
    );

    if (existingKey != null) {
      await progress.put(existingKey, entry);
    } else {
      await progress.add(entry);
    }
  }

  static ReadingProgress? getProgress(String bookId) {
    try {
      return progress.values.firstWhere((p) => p.bookId == bookId);
    } catch (_) {
      return null;
    }
  }
}
