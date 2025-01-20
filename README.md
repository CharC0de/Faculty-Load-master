# Faculty Load

## LOCAL SETUP

### Requirements
```
android studio: 2022.2.1
flutter: 3.19.6
java: 18
```
- Download & Install Flutter ```https://docs.flutter.dev/get-started/install```
- Flutter installation for windows ```https://www.youtube.com/watch?v=VFDbZk2xhO4```

### Important Directories
- ```lib/view``` Responsible for the UI or display of the app.
- ```lib/view/pages``` Contain's files of every pages inside the app.
- ```lib/view/routes``` Link the pages of the app.
- ```lib/view/models``` Structures of the data specially the entities.
- ```lib/view/data``` Compose of functions for manipulating the data inside the database.

### Run Locally
- Open project directory via terminal
- Run command inside project directory ```flutter pub get```
- To run the app locally with a mobile device plugged into a computer run command ```flutter run```

### Generate APK File
- Open project directory via terminal
- Run command inside project directory ```flutter build apk```
- Get the apk file here ```<project directory>/build/app/outputs/flutter-apk/app-release.apk```
