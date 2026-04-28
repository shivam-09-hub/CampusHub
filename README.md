# 📅 Smart Timetable Builder
### A beginner-friendly Flutter Android app for academic staff

---

## 🎯 What This App Does

Smart Timetable Builder lets any non-technical academic staff member create a
**conflict-free class timetable** in 5 simple steps — no technical knowledge required.

---

## 📱 App Screens

| Screen | Description |
|---|---|
| **Home Screen** | 3 big buttons: Create New, View Saved, Use Demo Data |
| **Step 1 – Basic Details** | Class name, working days, time slots per day |
| **Step 2 – Subjects** | Add subjects with faculty name and hours/week |
| **Step 3 – Classrooms** | Add rooms with ID and capacity |
| **Step 4 – Faculty Availability** | Set which days/slots each teacher is free |
| **Step 5 – Review & Generate** | Review all details, then tap Generate |
| **Result Screen** | View timetable as Day Cards or full Grid table |
| **Saved Timetables** | Browse, open, or delete previously saved timetables |

---

## ✅ Features

- ✅ Works fully **offline** — no internet needed
- ✅ **Conflict-free** scheduling (no faculty or room double-booking)
- ✅ **Step-by-step wizard** with progress bar (Step X of 5)
- ✅ **Day Card View** — easy to read, one day at a time
- ✅ **Grid View** — full timetable table layout
- ✅ **Export to Excel (.xlsx)** — days as rows, slots as columns
- ✅ **Save timetables locally** — reopen anytime
- ✅ **Sample Demo Data** — see it in action instantly
- ✅ **Regenerate** button — shuffle and try again
- ✅ **Edit** button — go back and change details
- ✅ **Reset form** button — start over cleanly
- ✅ Soft **color coding** for each subject
- ✅ Plain **beginner-friendly language** throughout
- ✅ Validation messages for missing fields

---

## 🛠️ How to Build the APK

### Step 1: Install Flutter

Download and install Flutter from the official site:
👉 https://flutter.dev/docs/get-started/install

Make sure to also install:
- Android Studio (for Android SDK)
- Java Development Kit (JDK 11 or higher)

Verify Flutter is working:
```bash
flutter doctor
```
All items should show ✅ (at minimum Flutter and Android toolchain).

---

### Step 2: Set Up the Project

Copy this entire `smart_timetable_builder` folder to your computer.

Open a terminal (or Command Prompt on Windows) inside the folder:
```bash
cd smart_timetable_builder
```

Install all dependencies:
```bash
flutter pub get
```

---

### Step 3: Build the APK

#### Debug APK (for testing):
```bash
flutter build apk --debug
```

#### Release APK (for distribution):
```bash
flutter build apk --release
```

Your APK will be saved at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

### Step 4: Install on Android Device

Connect your Android phone via USB (enable USB Debugging in Developer Options), then run:
```bash
flutter install
```

Or simply copy the `.apk` file to your phone and open it to install.

---

## 📂 Project Structure

```
smart_timetable_builder/
│
├── pubspec.yaml                        ← Package dependencies
├── analysis_options.yaml              ← Dart lint rules
│
├── lib/
│   ├── main.dart                       ← App entry point + theme
│   │
│   ├── models/
│   │   └── models.dart                 ← SubjectModel, RoomModel,
│   │                                     FacultyAvailability,
│   │                                     TimetableEntry, TimetableProject
│   │
│   ├── screens/
│   │   ├── home_screen.dart            ← Home with 3 action buttons
│   │   ├── wizard_screen.dart          ← All 5 wizard steps
│   │   ├── result_screen.dart          ← Card view + Grid view + Export
│   │   └── saved_timetables_screen.dart ← Browse saved timetables
│   │
│   └── utils/
│       ├── timetable_generator.dart    ← Scheduling algorithm
│       ├── excel_exporter.dart         ← .xlsx file creation
│       ├── storage_util.dart           ← Save/load via SharedPreferences
│       ├── demo_data.dart              ← Pre-filled sample data
│       ├── app_constants.dart          ← Colors, day/slot labels
│       └── widgets.dart               ← Reusable UI components
│
└── android/
    ├── build.gradle                    ← Root Android build config
    ├── settings.gradle
    ├── gradle.properties
    ├── gradle/wrapper/
    │   └── gradle-wrapper.properties
    └── app/
        ├── build.gradle                ← App-level build config
        └── src/main/
            ├── AndroidManifest.xml
            ├── kotlin/com/smart/timetable/
            │   └── MainActivity.kt
            └── res/
                ├── drawable/launch_background.xml
                ├── values/styles.xml
                └── xml/file_paths.xml
```

---

## ⚙️ Dependencies Used

| Package | Purpose |
|---|---|
| `excel` | Create .xlsx Excel files |
| `path_provider` | Get device file storage path |
| `share_plus` | Share exported Excel files |
| `permission_handler` | Request storage permissions |
| `shared_preferences` | Save timetables offline locally |
| `intl` | Date/number formatting |

---

## 🧠 How the Timetable Algorithm Works

The scheduling logic in `timetable_generator.dart`:

1. **Expands** each subject into individual sessions (e.g. 5 hrs/week = 5 sessions)
2. **Shuffles** sessions for natural variety
3. For each session, finds a **valid (day, slot)** pair that:
   - Respects the faculty's available days and time slots
   - Does not double-book the faculty in the same slot
   - Finds a free room for that slot
   - Prefers days where the subject has fewer sessions (even distribution)
4. **Detects and resolves conflicts** automatically
5. Reports summary messages: sessions placed, conflicts resolved

---

## 📤 Excel Export Format

The exported `.xlsx` file looks like this:

| Day / Slot | Slot 1 | Slot 2 | Slot 3 | ... |
|---|---|---|---|---|
| Monday | Mathematics / Dr. Sharma / [Room 101] | Physics / Prof. Mehta / [Lab A] | --- | ... |
| Tuesday | Chemistry / Dr. Patel / [Room 102] | --- | English / Ms. Joshi / [Room 101] | ... |
| ... | ... | ... | ... | ... |

Files are saved to the app's documents directory and can be shared via any app (WhatsApp, Gmail, etc.)

---

## 🎨 Color Theme

- **Primary:** `#4A6CF7` (Indigo Blue)
- **Success:** `#22C55E` (Green)
- **Warning:** `#FF6B4A` (Coral)
- Subjects get unique pastel color pairs automatically

---

## 📋 Minimum Requirements

- Android 5.0 (API 21) or higher
- ~10 MB storage space
- No internet connection needed

---

## 👩‍🏫 Designed For

Non-technical academic staff such as:
- School timetable coordinators
- College department heads
- Administrative staff managing class schedules

The entire UI uses plain language, large buttons, chip selectors,
and guided steps — no technical knowledge required.

---

*Built with Flutter & Dart — Smart Timetable Builder v1.0*
