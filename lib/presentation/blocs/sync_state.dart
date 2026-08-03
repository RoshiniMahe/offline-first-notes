part of 'sync_bloc.dart';

abstract class SyncState extends Equatable {
  const SyncState();
  
  @override
  List<Object> get props => [];
}

class SyncInitial extends SyncState {}

class SyncStatusState extends SyncState {
  final bool isOnline;
  final bool isSyncing;

  const SyncStatusState({required this.isOnline, required this.isSyncing});

  @override
  List<Object> get props => [isOnline, isSyncing];
}
