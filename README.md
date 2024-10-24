# Pickletronics
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
- As long as emulator is running, type 'r' in terminal to perform hot reload and view changes

