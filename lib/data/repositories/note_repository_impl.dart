import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
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
    
    // Always save locally first as pendingSync (or keep conflict if it was conflict)
    if (modelToSave.syncStatusModel != SyncStatusModel.conflict) {
       modelToSave = NoteModel.fromEntity(note.copyWith(syncStatus: SyncStatus.pendingSync, updatedAt: DateTime.now()));
    }

    await localDataSource.saveNote(modelToSave);

    if (isOnline && modelToSave.syncStatusModel != SyncStatusModel.conflict) {
      // Await the sync so we don't race with syncNotes() on refresh.
      // The UI already shows the note as "Pending" from the local save above.
      // When this completes, the Hive watch stream will update the UI to "Synced".
      try {
        // Check if this note already exists on the server
        final remoteNotes = await remoteDataSource.getNotes();
        final existsOnServer = remoteNotes.any((r) => r.id == modelToSave.id);
        await _pushNoteToServer(modelToSave, existsOnServer: existsOnServer);
      } catch (_) {
        // Sync failed silently — note stays as "pending" locally.
        // It will be picked up by the next syncNotes() call.
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
    // Overwrite local with resolved note, marked as pendingSync
    final resolvedModel = NoteModel.fromEntity(resolvedNote.copyWith(
      syncStatus: SyncStatus.pendingSync, 
      updatedAt: DateTime.now()
    ));
    await localDataSource.saveNote(resolvedModel);
    
    // Attempt sync
    await syncNotes();
  }

  @override
  Future<void> syncNotes() async {
    // Prevent concurrent syncs — if one is already running, skip.
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

            // Check if remote has this note (by ID)
            final remoteNoteIndex = remoteNotes.indexWhere((r) => r.id == localNote.id);
            if (remoteNoteIndex != -1) {
              final remoteNote = remoteNotes[remoteNoteIndex];
              if (remoteNote.version >= localNote.version) {
                // CONFLICT! Server has same or newer version, and local has pending changes.
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

      // 4. Pull: fetch remote notes AGAIN (server state changed after our pushes)
      //    This ensures we see the notes we just created (which may have new IDs).
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

      // 5. Clean up: remove local notes that were deleted on the server.
      //    Only remove notes that are "synced" — we must not delete notes
      //    that are pending sync or in conflict (the user may have created
      //    or edited them offline and they haven't been pushed yet).
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

  /// Pushes a single note to the server.
  /// 
  /// [existsOnServer] controls whether we PUT (update) or POST (create).
  /// This avoids the old "try PUT, catch 404, then POST" pattern which
  /// caused duplicate server entries every time.
  Future<void> _pushNoteToServer(NoteModel note, {required bool existsOnServer}) async {
    NoteModel syncedNote;

    if (existsOnServer) {
      // Note exists on server → PUT to update it
      syncedNote = await remoteDataSource.updateNote(note);
    } else {
      // Note is new → POST to create it
      syncedNote = await remoteDataSource.createNote(note);
    }

    // json-server v1.0 ignores the client's ID on POST and generates its own.
    // If the server returned a different ID, delete the old local record
    // to avoid a ghost "Pending" note sitting alongside the new "Synced" one.
    if (syncedNote.id != note.id) {
      await localDataSource.deleteNote(note.id);
    }

    // Save the server's version locally as synced
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
