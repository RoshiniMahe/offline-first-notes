import '../entities/note.dart';
import '../repositories/note_repository.dart';

class ResolveConflict {
  final NoteRepository repository;

  ResolveConflict(this.repository);

  Future<void> call(Note resolvedNote) async {
    return repository.resolveConflict(resolvedNote);
  }
}
