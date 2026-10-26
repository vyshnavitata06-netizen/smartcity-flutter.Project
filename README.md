# SmartCity 360 — Functional Flutter Demo

A clean Flutter project focused on working interactions rather than a static mock-up.

## Features
- Dashboard counts recalculate from complaint and alert data.
- Create complaints with title, category, and description.
- Search complaints by title/category/ID and filter by status.
- Change complaint status to Submitted, In Progress, or Resolved.
- Delete complaints with confirmation.
- Edit and save profile name, email, and ward/area.
- Create and delete city alerts.
- City service cards open details and can start a complaint with a preselected category.
- Emergency information page/dialog.
- Light/dark theme toggle.
- Complaint, alert, and profile data persist locally in browser storage through `shared_preferences`.

## Run in Microsoft Edge (Windows)
1. Extract the ZIP into a simple path such as `D:\SmartCity360`.
2. Open the extracted `smartcity_360_pro` folder.
3. Double-click `RUN_SMARTCITY.bat`.
4. If Windows asks for permission, allow the terminal. Keep the terminal open while using the app.

If the batch file does not work, open CMD in this folder and run one command at a time:

```cmd
flutter create --platforms=web .
flutter pub get
flutter run -d edge
```

## Notes
- Requires Flutter installed and `flutter` available in PATH. The launcher prints an error if Flutter cannot be found.
- First run needs internet access to download the `shared_preferences` package.
- This is a local demo: data is saved in this browser's local storage, not shared with other devices/users. Clearing browser data can erase it.
- Emergency numbers are displayed as informational demo content; verify local official numbers for real use.
