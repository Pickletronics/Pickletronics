import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'StartGame/start_game_view.dart';
import 'session_view.dart';

final Logger _logger = Logger();

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(200, 200, 200, 200),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pickletronics'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _appBarTitle {
    if (_tabController.index == 0) return 'Welcome Back';
    if (_tabController.index == 1) return 'Improve your Game';
    if (_tabController.index == 2) return 'Previous Sessions';
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_appBarTitle),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          StartGameView(),
          SessionsView(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.sports_tennis), text: 'Start Game'),
          Tab(icon: Icon(Icons.read_more), text: 'Recommendations'),
          Tab(icon: Icon(Icons.analytics_outlined), text: 'Sessions'),
        ],
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
      ),
    );
  }
}
