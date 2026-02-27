import database
import weather
from model import PlantModel
from tts import speak_message
import random
from datetime import datetime

# Thresholds
MOISTURE_LOW = 20.0
MOISTURE_HIGH = 80.0
TEMP_HIGH = 35.0
LIGHT_LOW = 10.0

class PlantLogic:
    def __init__(self):
        self.model = PlantModel()
        self.last_watered = None

    def process_data(self, data):
        """
        data: Object with soil_moisture, temperature, humidity, light_intensity
        Returns: Command string for ESP32/Relay
        """
        current_soil = data.soil_moisture
        command = "none"

        # 1. Immediate Rule-based Check
        if current_soil < MOISTURE_LOW:
            # Check for rain before watering
            print("Soil is dry. Checking forecast...")
            if weather.is_rain_expected(hours_ahead=6):
                speak_message("I am thirsty, but I see rain is coming, so I will wait.")
                command = "none" # Prevent watering
            else:
                command = "water_on"
                speak_message("I am thirsty. Please water me.")
                self.last_watered = datetime.now()
        elif current_soil > MOISTURE_HIGH:
            speak_message("I have too much water.")
        
        # 2. Environmental Checks
        if data.temperature > TEMP_HIGH:
            speak_message("It is getting too hot here.")
        
        if data.light_intensity < LIGHT_LOW:
             # Only complain if it's daytime (mock logic)
             pass

        # 3. Weather Proactive Checks
        # Preemptive watering if a heatwave is coming tomorrow and soil isn't already high
        if current_soil < 40.0 and weather.is_heatwave_expected(temp_threshold=35.0):
             if command == "none":
                 print("Heatwave expected tomorrow! Preemptive watering...")
                 speak_message("A heatwave is coming tomorrow. I am drinking extra water now.")
                 command = "water_on"
                 self.last_watered = datetime.now()

        # 4. ML Prediction (Future Health)
        readings = database.get_latest_readings(limit=10)
        if len(readings) == 10:
            formatted_data = [(r[2], r[3], r[4], r[5]) for r in readings] # soil, temp, hum, light
            predicted_soil = self.model.predict(formatted_data)
            
            if predicted_soil is not None:
                print(f"Predicted Soil Moisture: {predicted_soil:.2f}")
                # Logic based on prediction
                if predicted_soil < MOISTURE_LOW and command == "none":
                    if weather.is_rain_expected(hours_ahead=12):
                         print("ML predicted dry soil, but rain is expected in 12h. Ignored.")
                    else:
                         speak_message("I will need water soon.")

        # 5. Periodic Retraining (Mock condition: every 100 readings)
        # In production, check DB count or time
        
        return command

# Global Instance
logic_engine = PlantLogic()

def process_sensor_data(data):
    return logic_engine.process_data(data)
