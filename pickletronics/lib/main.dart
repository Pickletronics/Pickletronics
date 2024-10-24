import 'package:flutter/material.dart';
import 'StartGame/startGameView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(200,200,200,200)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pickletronics'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: TabBarView(
          children: [
            StartGameView(),
            const Center(child: Text('Recommendations')),
            const Center(child: Text('Sessions')),
          ],
        ),
     bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.sports_tennis), text: 'Start Game'),
            Tab(icon: Icon(Icons.read_more), text: 'Recommendations'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Sessions'),
          ],
          labelColor: Colors.black, // Active label color
          unselectedLabelColor: Colors.grey, // Inactive label color
          indicatorColor: Colors.black, // Tab indicator color
        ),
    )
    );
  }
}

void startGame() {
  // TODO: Bluetooth pairing logic goes here
  print('Start Game button pressed');
}