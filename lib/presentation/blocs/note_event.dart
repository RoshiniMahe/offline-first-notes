part of 'note_bloc.dart';

abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object> get props => [];
}

class LoadNotes extends NoteEvent {}

class NotesUpdated extends NoteEvent {
  final List<Note> notes;
  const NotesUpdated(this.notes);

  @override
  List<Object> get props => [notes];
}

class AddNote extends NoteEvent {
  final Note note;
  const AddNote(this.note);

  @override
  List<Object> get props => [note];
}

class UpdateNote extends NoteEvent {
  final Note note;
  const UpdateNote(this.note);

  @override
  List<Object> get props => [note];
}

class RemoveNote extends NoteEvent {
  final String id;
  const RemoveNote(this.id);

  @override
  List<Object> get props => [id];
}

class ResolveNoteConflict extends NoteEvent {
  final Note resolvedNote;
  const ResolveNoteConflict(this.resolvedNote);

  @override
  List<Object> get props => [resolvedNote];
}
