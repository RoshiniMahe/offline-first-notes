import 'package:hive/hive.dart';
import '../models/note_model.dart';

abstract class LocalDataSource {
  Future<void> init();
  Stream<List<NoteModel>> watchNotes();
  Future<List<NoteModel>> getNotes();
  Future<void> saveNote(NoteModel note);
  Future<void> saveNotes(List<NoteModel> notes);
  Future<void> deleteNote(String id);
  Future<void> clear();
}

class LocalDataSourceImpl implements LocalDataSource {
  static const String boxName = 'notes_box';
  late Box<NoteModel> _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<NoteModel>(boxName);
  }

  @override
  Stream<List<NoteModel>> watchNotes() async* {
    yield _box.values.toList().cast<NoteModel>();
    yield* _box.watch().map((_) => _box.values.toList().cast<NoteModel>());
  }

  @override
  Future<List<NoteModel>> getNotes() async {
    return _box.values.toList().cast<NoteModel>();
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    await _box.put(note.id, note);
  }

  @override
  Future<void> saveNotes(List<NoteModel> notes) async {
    final Map<String, NoteModel> map = {for (var e in notes) e.id: e};
    await _box.putAll(map);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}
