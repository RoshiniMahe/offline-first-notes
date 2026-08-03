import '../entities/note.dart';
import '../repositories/note_repository.dart';

class SaveNote {
  final NoteRepository repository;

  SaveNote(this.repository);

  Future<void> call(Note note) async {
    return repository.saveNote(note);
  }
}
