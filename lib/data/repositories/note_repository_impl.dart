import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:offline_first/domain/entities/note.dart';
import 'package:offline_first/domain/repositories/note_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  /// Prevents concurrent sync operations from racing against each other.
  bool _isSyncing = false;

  NoteRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  @override
  Stream<List<Note>> watchNotes() {
    return localDataSource.watchNotes().map((models) => models
        .where((model) => !model.isDeleted)
        .map((model) => model as Note)
        .toList());
  }

  @override
  Future<List<Note>> getNotes() async {
    final models = await localDataSource.getNotes();
    return models
        .where((model) => !model.isDeleted)
        .map((model) => model as Note)
        .toList();
  }

  @override
  Future<void> saveNote(Note note) async {
    final connectivityResult = await connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    NoteModel modelToSave = NoteModel.fromEntity(note);
    
    if (modelToSave.syncStatusModel != SyncStatusModel.conflict) {
       modelToSave = NoteModel.fromEntity(note.copyWith(syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now()));
    }

    await localDataSource.saveNote(modelToSave);

    if (isOnline && modelToSave.syncStatusModel != SyncStatusModel.conflict) {
      try {
        final remoteNotes = await remoteDataSource.getNotes();
        final existsOnServer = remoteNotes.any((r) => r.id == modelToSave.id);
        await _pushNoteToServer(modelToSave, existsOnServer: existsOnServer);
      } catch (_) {
      }
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    final connectivityResult = await connectivity.checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    final notes = await localDataSource.getNotes();
    final noteToDelete = notes.firstWhere((n) => n.id == id);
    
    // Soft delete locally
    final modelToSave = NoteModel.fromEntity(noteToDelete.copyWith(
      isDeleted: true,
      syncStatus: SyncStatus.pendingSync,
      updatedAt: DateTime.now(),
    ));

    await localDataSource.saveNote(modelToSave);

    if (isOnline) {
      try {
        await _syncDeletedNote(modelToSave);
      } catch (_) {
        // Will retry on next sync
      }
    }
  }

  @override
  Future<void> resolveConflict(Note resolvedNote) async {
    final targetStatus = resolvedNote.syncStatus == SyncStatus.synced 
        ? SyncStatus.synced 
        : SyncStatus.pendingSync;

    final resolvedModel = NoteModel.fromEntity(resolvedNote.copyWith(
      syncStatus: targetStatus, 
      updatedAt: DateTime.now()
    ));
    await localDataSource.saveNote(resolvedModel);
    
    await syncNotes();
  }

  @override
  Future<void> syncNotes() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return;

      // 1. Fetch remote notes
      final remoteNotes = await remoteDataSource.getNotes();
      
      // 2. Get local notes
      final localNotes = await localDataSource.getNotes();
      
      // 3. Push: process each local note that is pending sync
      for (var localNote in localNotes) {
        if (localNote.syncStatusModel == SyncStatusModel.pendingSync) {
          try {
            if (localNote.isDeleted) {
               await _syncDeletedNote(localNote);
               continue;
            }

            final remoteNoteIndex = remoteNotes.indexWhere((r) => r.id == localNote.id);
            if (remoteNoteIndex != -1) {
              final remoteNote = remoteNotes[remoteNoteIndex];
              if (remoteNote.version >= localNote.version) {
                await localDataSource.saveNote(NoteModel.fromEntity(
                  localNote.copyWith(syncStatus: SyncStatus.conflict)
                ));
                continue;
              } else {
                // Local is newer → update server (PUT)
                await _pushNoteToServer(localNote, existsOnServer: true);
              }
            } else {
               // Remote doesn't have it → create on server (POST)
               await _pushNoteToServer(localNote, existsOnServer: false);
            }
          } catch (e) {
            // Sync failed for this note, will retry on next sync
          }
        }
      }

      final currentRemoteNotes = await remoteDataSource.getNotes();
      final updatedLocalNotes = await localDataSource.getNotes();
      
      for (var remoteNote in currentRemoteNotes) {
        final localNoteIndex = updatedLocalNotes.indexWhere((l) => l.id == remoteNote.id);
        if (localNoteIndex != -1) {
          final localNote = updatedLocalNotes[localNoteIndex];
          // Update local if remote is newer AND local is not pending/conflict
          if ((remoteNote.version > localNote.version || remoteNote.updatedAt.isAfter(localNote.updatedAt)) && 
              localNote.syncStatusModel == SyncStatusModel.synced) {
             await localDataSource.saveNote(remoteNote);
          }
        } else {
          // Doesn't exist locally, save it
          await localDataSource.saveNote(remoteNote);
        }
      }

      final remoteIds = currentRemoteNotes.map((r) => r.id).toSet();
      for (var localNote in updatedLocalNotes) {
        if (!remoteIds.contains(localNote.id) &&
            localNote.syncStatusModel == SyncStatusModel.synced) {
          await localDataSource.deleteNote(localNote.id);
        }
      }

    } catch (e) {
      // Handle overall sync error
      print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushNoteToServer(NoteModel note, {required bool existsOnServer}) async {
    NoteModel syncedNote;

    if (existsOnServer) {
      // Note exists on server → PUT to update it
      syncedNote = await remoteDataSource.updateNote(note);
    } else {
      // Note is new → POST to create it
      syncedNote = await remoteDataSource.createNote(note);
    }

    if (syncedNote.id != note.id) {
      await localDataSource.deleteNote(note.id);
    }

    await localDataSource.saveNote(NoteModel.fromEntity(
      syncedNote.copyWith(syncStatus: SyncStatus.synced)
    ));
  }

  Future<void> _syncDeletedNote(NoteModel note) async {
    try {
      await remoteDataSource.deleteNote(note.id);
      await localDataSource.deleteNote(note.id); // Hard delete locally now
    } catch (e) {
      // If 404, it's already deleted on server, so hard delete locally
      if (e.toString().contains('404')) {
        await localDataSource.deleteNote(note.id);
      } else {
        rethrow;
      }
    }
  }
}
