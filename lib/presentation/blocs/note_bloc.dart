import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/save_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/resolve_conflict.dart';

part 'note_event.dart';
part 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final GetNotes getNotes;
  final SaveNote saveNote;
  final DeleteNote deleteNote;
  final ResolveConflict resolveConflict;

  NoteBloc({
    required this.getNotes,
    required this.saveNote,
    required this.deleteNote,
    required this.resolveConflict,
  }) : super(NoteInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<NotesUpdated>(_onNotesUpdated);
    on<AddNote>(_onAddNote);
    on<UpdateNote>(_onUpdateNote);
    on<RemoveNote>(_onRemoveNote);
    on<ResolveNoteConflict>(_onResolveNoteConflict);
  }

  void _onLoadNotes(LoadNotes event, Emitter<NoteState> emit) async {
    emit(NoteLoading());
    await emit.forEach<List<Note>>(
      getNotes(),
      onData: (notes) => NoteLoaded(notes),
      onError: (error, stackTrace) => NoteError(error.toString()),
    );
  }

  void _onNotesUpdated(NotesUpdated event, Emitter<NoteState> emit) {
    emit(NoteLoaded(event.notes));
  }

  void _onAddNote(AddNote event, Emitter<NoteState> emit) async {
    try {
      await saveNote(event.note);
    } catch (e) {
      // Handle error appropriately, maybe emit error state briefly
      print("Failed to add note: $e");
    }
  }

  void _onUpdateNote(UpdateNote event, Emitter<NoteState> emit) async {
    try {
      await saveNote(event.note);
    } catch (e) {
      print("Failed to update note: $e");
    }
  }

  void _onRemoveNote(RemoveNote event, Emitter<NoteState> emit) async {
    try {
      await deleteNote(event.id);
    } catch (e) {
      print("Failed to delete note: $e");
    }
  }

  void _onResolveNoteConflict(ResolveNoteConflict event, Emitter<NoteState> emit) async {
    try {
      await resolveConflict(event.resolvedNote);
    } catch (e) {
      print("Failed to resolve conflict: $e");
    }
  }
}
