part of 'sync_bloc.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object> get props => [];
}

class SyncStarted extends SyncEvent {}

class ConnectionChanged extends SyncEvent {
  final bool isOnline;
  const ConnectionChanged(this.isOnline);

  @override
  List<Object> get props => [isOnline];
}
