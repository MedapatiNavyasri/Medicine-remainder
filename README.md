# MediReminder — Medicine Reminder Web Application

A clean, responsive, and functional Medicine Reminder Web Application built using **Dart as the programming language and Flutter as the UI framework**.

---

## 1. Project Overview

**MediReminder** helps individuals manage their prescribed medications, establish daily dosage schedules, track upcoming and due doses, and maintain an immutable historical log of taken and skipped medications.

Designed with a clean, medical-themed interface that works smoothly across desktop, tablet, and mobile browsers.

---

## 2. Technology Requirements & Strict Compliance

- **Programming Language**: Pure Dart (Dart 3.x)
- **UI Framework**: Flutter Web (Material Design 3)
- **Local Persistence**: `shared_preferences` (backed by browser `localStorage`)
- **Icons**: Flutter Material Icons
- **Date & Time Pickers**: Flutter's native `showDatePicker` and `showTimePicker`
- **Zero External Backend / No Manual HTML/CSS/JS**: All screens, navigation, validation, and business logic are implemented in pure Dart within the Flutter framework.

---

## 3. Project Directory Structure

```
medicine_reminder/
├── lib/
│   ├── main.dart                      # App entry point, Material 3 theme & responsive layout shell
│   ├── models/
│   │   ├── medicine.dart              # Medicine, MedicineSchedule, MedicineFrequency, MedicineType
│   │   └── dose_history.dart          # DoseHistory, DoseStatus, occurrence key generator
│   ├── screens/
│   │   ├── dashboard_screen.dart      # Summary counters, Next Dose banner & Today's Schedule
│   │   ├── add_medicine_screen.dart   # Responsive form for adding and editing medications
│   │   ├── medicine_list_screen.dart  # Filterable and searchable catalog of all medicines
│   │   ├── medicine_details_screen.dart # Detailed schedule, instructions, notes & dose log
│   │   ├── history_screen.dart        # Complete audit log with filters and adherence metrics
│   │   └── settings_screen.dart       # App info, browser notice, stats & storage management
│   ├── services/
│   │   ├── storage_service.dart       # SharedPreferences persistence layer (CRUD & seeding)
│   │   └── reminder_service.dart      # Business logic: status resolution (due/missed/upcoming)
│   ├── widgets/
│   │   ├── medicine_card.dart         # MedicineCard & ScheduledDoseCard components
│   │   ├── empty_state.dart           # Reusable empty states with actions
│   │   └── status_badge.dart          # Color-coded badges for dose and medicine states
│   └── utils/
│       ├── date_utils.dart            # Date and time formatting, range checking, time parsing
│       └── validators.dart            # Form field and date range validation rules
├── test/
│   └── widget_test.dart               # Unit and widget tests for models, services & app
├── web/
│   ├── index.html                     # Web entry point
│   └── manifest.json                  # Web manifest
├── pubspec.yaml                       # Dependencies and asset declarations
└── README.md                          # Documentation and instructions
```

---

## 4. Key Application Features

### A. Home Dashboard
- Welcome banner displaying today's date.
- Real-time metric cards:
  - **Total Medicines**
  - **Scheduled Today**
  - **Taken Today**
  - **Upcoming Today**
  - **Missed / Pending Today**
- **Next Dose Highlight Banner**: Spotlights the earliest upcoming or due dose for quick action.
- **Today's Medicine Schedule**: Cards for every dose scheduled today with one-click actions:
  - **Take Dose**: Records the dose as taken with timestamp.
  - **Skip**: Records the dose as skipped.
- Responsive layout adapting from mobile cards to multi-column desktop views.

### B. Add & Edit Medicine
- Comprehensive form fields:
  - Medicine Name (min 2 characters)
  - Dosage (e.g., `1 tablet`, `500 mg`, `10 ml`)
  - Medicine Form / Type (`Tablet`, `Capsule`, `Syrup`, `Injection`, `Drops`, `Inhaler`, `Topical`, `Other`)
  - Food Intake Instructions (`Before food`, `After food`, `With food`, `Empty stomach`, `Before bed`, `Anytime`)
  - Frequency Presets (`Once daily`, `Twice daily`, `Three times daily`, `Custom`)
  - Reminder Times: interactive time picker to add or delete times
  - Date Range: calendar date pickers for Start Date and End Date
  - Optional notes and clinical instructions
  - Active / Inactive switch
- Validation: Validates all required fields and ensures End Date is on or after Start Date.

### C. Medicine Catalog & Management
- Search bar to filter medicines in real-time by name, dosage, or form.
- Filter chips: **All**, **Active**, and **Completed / Inactive**.
- Quick actions menu on every card:
  - View Details
  - Edit Medicine
  - Toggle Active / Completed
  - Delete (with explicit confirmation dialog)

### D. Medicine Details
- Comprehensive overview of a specific medicine: form icon, dosage, instructions, schedule range, remaining treatment days.
- Reminder times chips.
- History log specific to that medicine.

### E. History & Adherence Tracking
- Dedicated audit log of all previous dose actions.
- Real-time Adherence Statistics:
  - Total Logs
  - Taken Count
  - Skipped Count
  - Adherence Rate Percentage (`(Taken / Total) * 100`)
- Filters:
  - Filter by specific medicine
  - Filter by status (`All`, `Taken`, `Skipped`)
  - Filter by specific calendar date
- Ability to delete a specific dose log.

### F. Settings & Storage Management
- Application details and versioning.
- Transparent notice explaining web platform reminder behavior.
- Storage statistics displaying total stored medicines and history records.
- **Load Sample Demo Medicines**: Populates realistic sample medications for instant testing.
- **Clear All Local Data**: Wipes local storage after double-confirmation.

---

## 5. Date and Reminder Logic

1. **Date Range Applicability**: A medicine only generates doses on days that fall within its configured `startDate` and `endDate` (inclusive). Inactive medicines generate no active reminders.
2. **Occurrence Key Resolution**: Every dose occurrence has a unique key:
   $$\text{occurrenceKey} = \text{medicineId}\_\text{YYYY-MM-DD}\_\text{HH:mm}$$
   Taking dose 1 of a twice-daily schedule marks only that specific occurrence, leaving the second dose unaffected.
3. **Status States**:
   - **Taken**: User explicitly marked dose as taken.
   - **Skipped**: User explicitly marked dose as skipped.
   - **Due**: Current time is at or past scheduled time (within a 60-minute window) and not yet recorded.
   - **Missed**: Scheduled time was more than 60 minutes ago without user action.
   - **Upcoming**: Scheduled time is in the future.
4. **Honest Web Platform Notice**: Standard web applications cannot wake up a device or deliver guaranteed alarms when the browser tab is closed or the device is powered off. MediReminder evaluates and displays due and missed doses accurately whenever the app is loaded or refreshed.

---

## 6. Setup and Running Instructions

### Prerequisites
- Flutter SDK (version 3.19 or higher) installed and added to `PATH`.
- Google Chrome, Microsoft Edge, or any modern web browser.

### Step 1: Install Dependencies
In the project directory, run:
```bash
flutter pub get
```

### Step 2: Run in Development Mode
To launch the application in Chrome:
```bash
flutter run -d chrome
```

Or run on Microsoft Edge:
```bash
flutter run -d edge
```

Or run on a specific web server port:
```bash
flutter run -d web-server --web-port=8080 --web-hostname=127.0.0.1
```

### Step 3: Run Tests
Execute the unit and widget tests:
```bash
flutter test
```

### Step 4: Run Static Analysis
Ensure zero lint or type errors:
```bash
flutter analyze
```

### Step 5: Build Production Web Bundle
To build the minified release bundle:
```bash
flutter build web --release
```
The output will be generated inside the `build/web` directory, ready to be hosted on any static web server (such as Firebase Hosting, GitHub Pages, Vercel, or Netlify).

To preview the built production web app locally using Python or any simple HTTP server:
```bash
# Using Python
cd build/web
python -m http.server 8000
```
Then visit `http://localhost:8000` in your web browser.

---
## 🌍 SDG Relevance

This project contributes to the following United Nations Sustainable Development Goals (SDGs):

### SDG 3 – Good Health and Well-being
MediReminder supports better health management by helping individuals organize their medication schedules, track their daily medicine intake, and maintain medication records. It encourages consistent medication habits and promotes better awareness of personal healthcare routines.

### SDG 10 – Reduced Inequalities
The application aims to make digital medication management easier to access through a simple and user-friendly interface, helping individuals with different levels of technical knowledge manage their medication schedules.

### SDG 9 – Industry, Innovation and Infrastructure
MediReminder demonstrates how digital innovation can be used to address everyday healthcare challenges through a technology-based medication management solution.

## ❤️ Social Impact

MediReminder aims to make daily medication management easier, especially for elderly individuals, patients with long-term medication requirements, and people with busy schedules.

**Key Social Benefits:**

- **Medication Awareness:** Helps users stay organized with their prescribed medicines.
- **Reduced Forgetfulness:** Provides a structured way to manage medication schedules.
- **Better Tracking:** Allows users to maintain records of their medication intake.
- **Support for Elderly Individuals:** Offers a simple interface to manage daily medicines.
- **Convenience:** Reduces dependence on handwritten medication schedules.
- **Healthcare Awareness:** Encourages individuals to take responsibility for following their prescribed medication routines.

### Long-Term Social Vision

To promote accessible and technology-driven medication management, helping individuals develop consistent medicine-taking habits and supporting healthier communities.
