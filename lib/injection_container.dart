import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'data/datasources/local_data_source.dart';
import 'data/datasources/remote_data_source.dart';
import 'data/repositories/note_repository_impl.dart';
import 'domain/repositories/note_repository.dart';
import 'domain/usecases/delete_note.dart';
import 'domain/usecases/get_notes.dart';
import 'domain/usecases/resolve_conflict.dart';
import 'domain/usecases/save_note.dart';
import 'domain/usecases/sync_notes.dart';
import 'presentation/blocs/note_bloc.dart';
import 'presentation/blocs/sync_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => NoteBloc(
        getNotes: sl(),
        saveNote: sl(),
        deleteNote: sl(),
        resolveConflict: sl(),
      ));
  sl.registerFactory(() => SyncBloc(
        syncNotes: sl(),
        connectivity: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => SaveNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));
  sl.registerLazySingleton(() => SyncNotes(sl()));
  sl.registerLazySingleton(() => ResolveConflict(sl()));

  // Repository
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      connectivity: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl());
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSourceImpl(sl()));

  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());
}
