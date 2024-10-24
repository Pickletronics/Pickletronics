import 'package:flutter/material.dart';

class StartGameView extends StatelessWidget {
  const StartGameView({Key? key}) : super(key: key);

  @override
Widget build(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: ElevatedButton(
            onPressed: startGame,
            child: const Text('Pair Device'),
          ),
        ),
        const SizedBox(height: 20), // Adds space between the button and the text
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0), // Adds horizontal padding for better readability
          child: Text(
            '1. Bring device close enough for Bluetooth detection.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center, // Aligns text in the center
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            '2. Click the \'Pair Device\' button above.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            '3. If data is available, wait for data collection to complete. You will be navigated to a summary of this section.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            '4. If no data is available, you will be alerted to begin a new session on the device before pairing.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

  void startGame() {
    // TODO: Bluetooth pairing logic goes here
    print('Start Game button pressed');
  }
}
