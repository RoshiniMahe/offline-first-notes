import '../entities/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotes();
  Future<void> saveNote(Note note);
  Future<void> deleteNote(String id);
  Future<void> syncNotes();
  Future<void> resolveConflict(Note resolvedNote);
  
  Stream<List<Note>> watchNotes();
}
