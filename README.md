# Scanner

Scans a picture of the weekly plan and uploads the meal data.

This app is build with [Flutter](https://flutter.dev) and only tested with Android.

In order to work the app needs also a connection to 
the [Scanner API](https://github.com/timetablebot/scanner_api). 
Setup this part first!

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

Install the app on your device by installing the Android SDK and the Flutter SDK.

Then connect your device to your PC and run
```bash
flutter run --release
```

## Usage

1. 'Connect' to your Scanner API (Globe right upper corner / Connect button in the middle of the screen)

2. Take or select a photo of the menu (Photo button lower right corner)

3. Select to which day scanned text parts belong 
(Select the day, the type of the meal, h
ow much copies of the scanned part should be saved for editing or merge with the text before).
Swipe to get to the next part of scanned text and press at the end the finish button.

4. Edit the meals to correct issues of the scan 
(Tap on one meal to open the edit page or long tap on one meal to merge, delete or copy)

5. Upload the meals (Upload button in the lower right corner)

There will be an error while uploading if there are more than one meal 
with the same date and type (vegetarian or not).