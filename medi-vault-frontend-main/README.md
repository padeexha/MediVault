# Medi Vault Frontend

Flutter frontend for the Medi Vault backend.

## What It Supports

- Patient and doctor registration with email verification messaging
- Login, logout, and persisted session restore
- Patient dashboard with record counts by category
- Upload, list, search, view, edit, delete, and download medical records
- Grant and revoke doctor access by doctor email
- Doctor dashboard for records shared by patients
- Patient audit log

## Running

Install Flutter, then run:

```sh
flutter pub get
flutter run
```

By default the app uses the hosted backend:

```txt
https://medi-vault-backend-28w8.onrender.com/api
```

To point the frontend at a local backend, pass `API_BASE_URL`:

```sh
flutter run --dart-define=API_BASE_URL=http://localhost:5000/api
```

For Android emulator builds, use `10.0.2.2` instead of `localhost`:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```
