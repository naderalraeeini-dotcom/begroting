# Begroting

A Flutter Android personal finance tracker. The first implementation stores the full ledger as JSON in Android app preferences, retaining records across months and ordinary app updates.

## Features in this initial build
- Income, fixed expenses, variable expenses, debts, savings and future purchases.
- Month-by-month history based on each record's date.
- Mark fixed/variable expenses and purchases as paid; paid items appear faded.
- Defer purchases to a chosen date while retaining the original record and showing a deferred label.
- Arabic, Dutch and English interface, with localized slogan.
- JSON backup sharing and restore.
- Optional four-digit app lock.
- Monthly statement sharing.

## Build APK
The GitHub Actions workflow **Build Begroting APK** generates Android platform files, resolves Flutter dependencies, builds a release APK and uploads it as the artifact `begroting-release-apk`.

Open the repository's **Actions** tab, select **Build Begroting APK**, open the latest run, and download the artifact at the bottom of the run page.

## Data safety
- Records are stored locally in app preferences and are not automatically uploaded to a server.
- Make a JSON backup before reinstalling, clearing app data, or moving to another phone.
- Normal app updates with the same Android application ID preserve app data. Uninstalling the app or clearing its storage can remove local data.
- The four-digit lock is a convenience lock, not encryption. Keep backup files private.
- Biometric authentication is intentionally omitted.
