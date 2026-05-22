# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

mindb is an AI-powered PostgreSQL client (Flutter, Dart). It connects directly to Postgres over TCP and uses LLM APIs (OpenAI, Anthropic, Kimi) for natural-language-to-SQL. No backend server — it's a standalone desktop/mobile app.

### Running commands

Standard commands per `README.md`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d linux
```

### Non-obvious setup caveats (Linux desktop target)

1. **XDG user directories** must exist. The app uses `getApplicationDocumentsDirectory()` via `path_provider`, which requires `xdg-user-dirs` to be installed and initialized (`xdg-user-dirs-update`). Without it, the app crashes with `MissingPlatformDirectoryException`.

2. **D-Bus + gnome-keyring** are required for `flutter_secure_storage`. Before running the app, start a D-Bus session and unlock the keyring:
   ```bash
   eval $(dbus-launch --sh-syntax)
   echo "unlock" | gnome-keyring-daemon --unlock --components=secrets
   ```

3. **`libstdc++-14-dev`** is needed for the CMake/clang++ Linux build (linker needs `-lstdc++`).

4. **`ninja-build`** and **`libgtk-3-dev`** are required for the Flutter Linux desktop build.

5. **`google_fonts` compatibility**: If Flutter stable is upgraded and the app fails to build with `FontWeight` const map errors, run `flutter pub upgrade google_fonts` to get the latest compatible 6.x release.

6. **Overflow warnings** about `RenderFlex` are non-functional — they occur when the window is very small (e.g., default VM display). Resize the window to suppress them.

### PostgreSQL for E2E testing

```bash
sudo docker run --name mindb-pg -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
```

Credentials: `localhost:5432`, database `postgres`, user `postgres`, password `postgres`.

### LLM API key

The AI query features require a valid API key configured in Settings. Without one, the session screen shows "LLM API key not configured". Direct SQL (`sql: SELECT 1`) works without an API key.
