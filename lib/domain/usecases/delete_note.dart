import '../repositories/note_repository.dart';

class DeleteNote {
  final NoteRepository repository;

  DeleteNote(this.repository);

  Future<void> call(String id) async {
    return repository.deleteNote(id);
  }
}
