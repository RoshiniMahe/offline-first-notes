import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/usecases/sync_notes.dart';

part 'sync_event.dart';
part 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncNotes syncNotes;
  final Connectivity connectivity;
  StreamSubscription? _connectivitySubscription;

  SyncBloc({
    required this.syncNotes,
    required this.connectivity,
  }) : super(SyncInitial()) {
    on<SyncStarted>(_onSyncStarted);
    on<ConnectionChanged>(_onConnectionChanged);

    _connectivitySubscription = connectivity.onConnectivityChanged.listen((result) {
      add(ConnectionChanged(!result.contains(ConnectivityResult.none)));
    });
  }

  void _onSyncStarted(SyncStarted event, Emitter<SyncState> emit) async {
    final currentState = state;
    bool isOnline = true;
    if (currentState is SyncStatusState) {
      isOnline = currentState.isOnline;
    }
    
    if (!isOnline) return;

    emit(SyncStatusState(isOnline: isOnline, isSyncing: true));
    try {
      await syncNotes();
      emit(SyncStatusState(isOnline: isOnline, isSyncing: false));
    } catch (e) {
      emit(SyncStatusState(isOnline: isOnline, isSyncing: false));
      // Optionally handle error
    }
  }

  void _onConnectionChanged(ConnectionChanged event, Emitter<SyncState> emit) {
    emit(SyncStatusState(isOnline: event.isOnline, isSyncing: false));
    if (event.isOnline) {
      add(SyncStarted());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
