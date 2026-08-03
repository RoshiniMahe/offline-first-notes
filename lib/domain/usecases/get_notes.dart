import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes {
  final NoteRepository repository;

  GetNotes(this.repository);

  Stream<List<Note>> call() {
    return repository.watchNotes();
  }
}
