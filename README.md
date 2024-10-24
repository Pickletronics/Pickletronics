# Pickletronics
Set up Dev Environment:
1. Install Flutter & Dart extensions on VSCode
2. Download android studio (https://developer.android.com/studio)
3. Create a new device (Android 15.0 was the default after I installed) and press the play button to launch. Make note of device name
4. In your terminal, type flutter emulators --launch <device name> then flutter run

Dev tips:
- All mobile development code should be in 'lib' folder, since we are emulating on Android we need it to be cross-compatible
- Any iOS-specific components go in the 'ios' folder, but again should be limited as we won't be able to emulate this
- Use flutters built-in widgets to ensure cross compatibility

