import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'injection_container.dart' as di;
import 'presentation/blocs/note_bloc.dart';
import 'presentation/blocs/sync_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'data/models/note_model.dart';
import 'data/datasources/local_data_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(SyncStatusModelAdapter());
  Hive.registerAdapter(NoteModelAdapter());

  // One-time clear of corrupted local data from previous broken syncs.
  // Uses deleteBoxFromDisk BEFORE opening the box — this also removes
  // any stale .lock files that would cause a FileSystemException.
  // Remove this block after all devices have been restarted once.
  final flagBox = await Hive.openBox('app_flags');
  if (flagBox.get('sync_data_reset_v1', defaultValue: false) == false) {
    await Hive.deleteBoxFromDisk('notes_box');
    await flagBox.put('sync_data_reset_v1', true);
  }
  await flagBox.close();

  await di.init();
  await di.sl<LocalDataSource>().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NoteBloc>(create: (_) => di.sl<NoteBloc>()),
        BlocProvider<SyncBloc>(create: (_) => di.sl<SyncBloc>()),
      ],
      child: MaterialApp(
        title: 'Offline First Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey.shade100,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
