# Integration Steps
1) Place contents into your repo root.
2) Backend:
   python -m venv .venv && source .venv/bin/activate
   pip install -r backend/requirements.txt
   uvicorn backend.main:app --reload
3) Flutter:
   Add dependencies to pubspec.yaml (http, google_maps_flutter, firebase_core, firebase_messaging, etc.)
   flutter pub get && flutter run
4) (Optional) Fonts are in assets/fonts and referenced by branding/demo screens.
