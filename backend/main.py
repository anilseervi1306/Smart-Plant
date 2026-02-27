from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import datetime
import database
import logic
import cloud
import uvicorn

app = FastAPI(title="Smart Plant Backend")

# Initialize DB on startup
@app.on_event("startup")
async def startup_event():
    database.init_db()

class SensorData(BaseModel):
    soil_moisture: float
    temperature: float
    humidity: float
    light_intensity: float

@app.post("/api/sensors")
async def receive_sensor_data(data: SensorData):
    """
    Receive sensor data from ESP32.
    """
    # 1. Store in DB
    database.insert_sensor_reading(
        data.soil_moisture, 
        data.temperature, 
        data.humidity, 
        data.light_intensity
    )
    
    # 2. Trigger Logic
    command = logic.process_sensor_data(data)

    # 3. specific Cloud Sync
    cloud.sync_data(data)
    
    return {"status": "success", "command": command}

@app.get("/api/status")
async def get_status():
    """
    Get latest plant status for Mobile App.
    """
    readings = database.get_latest_readings(limit=1)
    if not readings:
        return {"status": "no_data"}
    
    # Example response
    return {
        "latest_reading": readings[0],
        "plant_health": "Good" # Placeholder
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)
