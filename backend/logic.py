import database
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

        # 3. ML Prediction (Future Health)
        readings = database.get_latest_readings(limit=10)
        if len(readings) == 10:
            formatted_data = [(r[2], r[3], r[4], r[5]) for r in readings] # soil, temp, hum, light
            predicted_soil = self.model.predict(formatted_data)
            
            if predicted_soil is not None:
                print(f"Predicted Soil Moisture: {predicted_soil:.2f}")
                # Logic based on prediction
                if predicted_soil < MOISTURE_LOW and command == "none":
                    speak_message("I will need water soon.")

        # 4. Periodic Retraining (Mock condition: every 100 readings)
        # In production, check DB count or time
        
        return command

# Global Instance
logic_engine = PlantLogic()

def process_sensor_data(data):
    return logic_engine.process_data(data)
