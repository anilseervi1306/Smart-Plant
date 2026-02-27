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

## architecture.md

### 🌍 System Architecture
Your system is an **Edge-AI enabled predictive plant care system** distributed across four main layers:

1. **IoT Edge Node (ESP32)**: The sensory and execution layer that physically interacts with the plant.
2. **Edge Server (Raspberry Pi)**: The "brain" of the system, handling local offline processing, machine learning predictions, and hardware automation.
3. **Cloud Database (Firebase)**: The bridge for online synchronization and remote access.
4. **Mobile Client (Flutter App)**: The end-user interface for real-time remote monitoring.

### ⚙️ How It Works (The Workflow)
1. **Sensing**: The ESP32 wakes up every 5 seconds, reads data from all attached sensors (DHT22, Soil Moisture, BH1750), packages it into a JSON payload, and sends an HTTP POST request to the local Raspberry Pi Server over your local WiFi.
2. **Analysis**: The Python backend on the Pi (`logic.py`) receives the JSON. First, it asserts the hard rules. If the soil is critically dry, it immediately queues a `water_on` command and triggers the Text-To-Speech (TTS) engine.
3. **Prediction**: The Pi then queries the local SQLite Database for the last 10 environmental records and passes them to the machine learning model to predict what the moisture will be in the future.
4. **Response**: The Pi responds back to the ESP32's HTTP request with a JSON object dictating the required pump action (e.g., `{"command": "water_on"}`).
5. **Execution**: The ESP32 parses this response and flips the relay GPIO pin HIGH or LOW to physically turn the water pump on or off.
6. **Cloud Sync**: Finally, the Raspberry Pi pushes the new data (including the AI prediction) to Firebase Firestore, allowing the Flutter app's stream to instantly update anywhere in the world.

### 🧠 Algorithms & Logic Used

**1. Rule-Based Engine (Immediate Action)**
This handles immediate, critical life-support actions for the plant.
*   **Thresholds**: It triggers if Soil Moisture < 20% (Thirsty) or > 80% (Overwatered). It flags if Temperature > 35°C (Too hot) or Light < 10 lux (Too dark).
*   **Action**: Directly sets the response command to `water_on` or `water_off` for the ESP32 relay to execute immediately.

**2. Machine Learning Predictive Engine (LSTM)**
This is the "Smart" AI part that handles intelligent forecasting.
*   **Algorithm**: **LSTM (Long Short-Term Memory)** neural network. LSTMs are a type of Recurrent Neural Network (RNN) highly suited for time-series forecasting because they remember previous data points in a sequence.
*   **Process**: Every cycle, it feeds the last **10 historical readings** (Soil Moisture, Temperature, Humidity, and Light) into the trained LSTM model.
*   **Prediction**: The model outputs a continuous value representing the *projected future soil moisture*.
*   **Action**: If the predicted future moisture drops below the critical 20% threshold—even if it's currently fine—it preemptively triggers the *"I will need water soon"* voice prompt.

### ✨ Features & Modules Implemented

*   **100% Offline Capable**: The core system doesn't rely on the internet to keep the plant alive. The ESP32 and Raspberry Pi communicate over local WiFi. The Pi makes decisions (like turning on the pump) and logs data locally via SQLite.
*   **Predictive AI Behavior**: Instead of just reacting *after* the plant is completely dry, the AI anticipates watering needs before they become critical.
*   **Voice Feedback (TTS)**: The plant "talks". When the backend processes sensory changes, it outputs audio commands via the Pi (e.g., *"I am thirsty. Please water me"*, *"I have too much water"*, or *"It is getting too hot here"*).
*   **Real-Time Remote App**: The Flutter application provides a real-time dashboard reflecting the plant's mood ("I am Feeling Great!", "I am Thirsty!"), current statistics (Moisture, Temp, Light, Humidity), and a chronological line chart of soil moisture history synced via Firebase. 
