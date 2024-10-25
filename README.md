# Pickletronics
Completed Work:
- Project Setup: initialized Flutter project, set up Android Emulator for testing, bluetooth framework setup
- Basic App Structure: navigation between different tabs, persistent app state
- UI Setup: basic UI setup for navigation between tabs and header display
- Bluetooth framework: bluetooth package installed and set up on 'Start Game' page. Clicking 'Pair Device' button starts scan for bluetooth devices.
- CI/CD pipeline set up for an iOS build every time a change is made to main branch, using CodeMagic
  
Project Architecture:
- Frontend: Flutter framework with Dart programming language
- Backend: sqfLite (Flutter plugin for relational database management)
- Bluetooth Communication: flutter_blue_plus plugin to manage bluetooth connection and data transfer

Known Bugs:
- For the sake of testing, the bluetooth connection only works on a physical device and not an emulator. We don't yet have access to a physical device (and are still trying to set up the dev environment on a MacOS), so we have not yet been able to thoroughly test the bluetooth scanning logic. For now, when running on an emulator, the bluetooth begins scanning and the 'Pair Device' button remains disabled until a Hot Restart.

Set up Dev Environment:
1. Install Flutter in the same root directory as cloned repo
2. Install Flutter & Dart extensions on VSCode
3. Download android studio (https://developer.android.com/studio)
4. Create a new device (Android 15.0 was the default after I installed)
5. Press the play button to launch, or make note of device name and type 'flutter emulators --launch <device name>' in terminal
6. In your terminal, type 'flutter run'. The app should now be running

Dev tips:
- All mobile development code should be in 'lib' folder, since we are emulating on Android we need it to be cross-compatible
- Any iOS-specific components go in the 'ios' folder, but again should be limited as we won't be able to emulate this
- Use flutters built-in widgets to ensure cross compatibility
- As long as emulator is running, type 'r' in terminal to perform hot reload and view changes. This maintains the application state
- To restart the application, type 'R' in the terminal to perform a hot restart

