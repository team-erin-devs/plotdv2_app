# Team Erin Flutter App!!!!!!

---

## 1. Install FVM

**Windows (PowerShell):**
`choco install fvm`

**macOS / Linux:**
`brew tap leoafarias/fvm`
`brew install fvm`

---

## 2. Install Flutter with FVM

From the **project root directory** (where the `.fvm` folder is located), run:

`fvm install`

---

## 3. Fetch Dependencies and Run the Project

Still in the **project root directory**, run:

`fvm flutter pub get`

To start the app, you can run it on **Chrome**:

`fvm flutter run -d chrome`

### Running on other devices

- To see all connected devices and available emulators/simulators, run:  
  `fvm flutter devices`

- On Windows and Linux, you can run on **Android emulators** (via Android Studio).  
- On macOS, you can run on **iOS simulators** (via Xcode) or Android emulators (via Android Studio).  
- To run on a specific device, use the `-d <device_id>` flag, e.g.:  
  `fvm flutter run -d emulator-5554`

---

## Summary

1. Install **FVM** for your OS.  
2. Install the **Flutter version** using `fvm install`.  
3. Fetch dependencies with `fvm flutter pub get`.  
4. Run the project on Chrome using `fvm flutter run -d chrome`.  
5. Optionally, list devices with `fvm flutter devices` and run on other devices/emulators using `-d <device_id>`.
