# Mindful

Mindful is a Flutter-based mobile application that provides users with a virtual therapist chatbot. The app utilizes OpenAI and OpenRouter for chat completions, offering a compassionate and insightful conversational experience with Dr. Rachel Kim, a virtual therapist.

## Features

- Real-time chat interface with a virtual therapist
- Personalized responses based on user input
- Integration with OpenAI and OpenRouter for advanced language processing
- Cross-platform support for iOS and Android

## Requirements 
- Git for Windows [https://gitforwindows.org/]
- Flutter SDK [https://docs.flutter.dev/get-started/]
- Android Studio [https://developer.android.com/studio]
- Xcode [https://developer.apple.com/xcode/]
- Visual Studio Code (recommended) [https://code.visualstudio.com/download]


## Setting up Flutter step by step

1. Download the Flutter SDK from the official Flutter website. [https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.22.3-stable.zip]
2. Extract the downloaded zip file to a desired location (e.g., `C:\flutter` on Windows or `~/flutter` on Mac).
3. Add the Flutter `bin` directory to your PATH:
   - On Windows: Edit the system environment variables and add `C:\flutter\bin` to the PATH.
   - On Mac: Add `export PATH="$PATH:[PATH_TO_FLUTTER_GIT_DIRECTORY]/flutter/bin"` to your `~/.bash_profile` or `~/.zshrc` file.
4. Run `flutter doctor` in the terminal to check for any missing dependencies.

## Downloading and setting up SDK tools and Android Studio

1. Download and install Android Studio from the official website.
2. During installation, make sure to select "Android SDK", "Android SDK Platform", and "Android Virtual Device".
3. Launch Android Studio and go to Tools > SDK Manager.
4. In the SDK Platforms tab, select the latest Android SDK version.
5. In the SDK Tools tab, select "Android SDK Build-Tools", "Android Emulator", and "Android SDK Platform-Tools".
6. Click "Apply" to install the selected components.

## Downloading and setting up Xcode (Mac only)

1. Install Xcode from the Mac App Store.
2. Open Xcode and agree to the license agreement.
3. Install additional required components if prompted.
4. Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` in the terminal to configure the Xcode command-line tools.
5. Run `sudo xcodebuild -license` to agree to the Xcode and iOS license agreements.

## Flutter commands for cleaning, installing dependencies, and running the project

1. Clean the project:
    flutter clean

2. Get dependencies:
    flutter pub get

3. Run the project:
  - For iOS Simulator:
        flutter run -d ios
 
  - For Android Emulator:
        flutter run -d android
 
  - For connected device or browser:
        flutter run
 
4. Build the release version:
   - For Android:
      flutter build apk
 
   - For iOS:
      flutter build ios


 
Remember to set up your `.env` file with the necessary API keys before running the project: OPENAI_API_KEY=your_openai_api_key_here
