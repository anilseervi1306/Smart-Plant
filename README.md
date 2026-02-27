# Smart Plant That Talks

An Edge-AI enabled predictive plant care system using IoT (ESP32), Edge Computing (Raspberry Pi), and Mobile App (Flutter).

## Project Structure
- `firmware/`: ESP32 Code (PlatformIO)
- `backend/`: Raspberry Pi Python Backend (FastAPI, LSTM, SQLite)
- `mobile_app/`: Flutter Mobile Application

## Setup Instructions

### 1. ESP32 Firmware
1. Open `firmware/` in VS Code with PlatformIO extension.
2. Update `src/main.cpp` with your WiFi credentials and Raspberry Pi IP address.
3. Upload to ESP32.

### 2. Raspberry Pi Backend
1. Navigate to `backend/`.
2. Install dependencies:
   ```bash
   pip3 install -r requirements.txt
   ```
3. (Optional) Add `serviceAccountKey.json` for Firebase to `backend/`.
4. Run the server:
   ```bash
   python3 main.py
   ```
   The server runs on port 5000.

### 3. Mobile App
1. Navigate to `mobile_app/`.
2. Add `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) to the respective folders (Standard Firebase setup).
3. Run the app:
   ```bash
   flutter run
   ```

## Features
- **Offline Mode**: 
  - Sensors -> ESP32 -> Pi (SQLite storage).
  - Pi predicts plant needs using LSTM.
  - Pi speaks status (TTS) and controls pump.
- **Online Mode**:
  - Pi syncs data to Firebase.
  - Mobile App shows real-time status and history.

## Wiring (Suggested)
- **ESP32**:
  - Soil Moisture (Analog) -> GPIO 34
  - DHT22 -> GPIO 4
  - BH1750 (I2C) -> GPIO 21 (SDA), 22 (SCL)
  - Relay -> GPIO 5
