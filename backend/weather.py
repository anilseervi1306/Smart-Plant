import os
import requests
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("OPENWEATHER_API_KEY")
CITY = os.getenv("CITY_NAME")
COUNTRY_CODE = os.getenv("COUNTRY_CODE", "")

# OpenWeatherMap API URLs
BASE_URL = "http://api.openweathermap.org/data/2.5/"

def get_forecast():
    """
    Fetches the 5-day / 3-hour forecast data from OpenWeatherMap.
    Returns the JSON payload or None if the request fails.
    """
    if not API_KEY or not CITY:
        print("Weather API configuration missing.")
        return None

    query = f"{CITY},{COUNTRY_CODE}" if COUNTRY_CODE else CITY
    url = f"{BASE_URL}forecast?q={query}&appid={API_KEY}&units=metric"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error fetching weather forecast: {e}")
        return None

def is_rain_expected(hours_ahead=6):
    """
    Checks if rain is expected within the given number of hours.
    OpenWeather returns data in 3-hour blocks.
    """
    forecast_data = get_forecast()
    if not forecast_data:
        return False
    
    # Each list item is a 3-hour step
    steps_to_check = max(1, hours_ahead // 3)
    
    try:
        for i in range(min(steps_to_check, len(forecast_data['list']))):
            step = forecast_data['list'][i]
            # Weather ID 2xx, 3xx, 5xx indicate Thunderstorm, Drizzle, Rain
            # https://openweathermap.org/weather-conditions
            weather_id = step['weather'][0]['id']
            if 200 <= weather_id < 600:
                print(f"Rain expected! Weather ID: {weather_id} at {step['dt_txt']}")
                return True
        return False
    except KeyError as e:
         print(f"Error parsing weather data: {e}")
         return False

def is_heatwave_expected(temp_threshold=38.0):
    """
    Checks if the maximum temperature in the next 24 hours exceeds the threshold.
    """
    forecast_data = get_forecast()
    if not forecast_data:
        return False
    
    # Check the next 8 steps (8 * 3 hours = 24 hours)
    try:
        for i in range(min(8, len(forecast_data['list']))):
            step = forecast_data['list'][i]
            temp_max = step['main']['temp_max']
            if temp_max >= temp_threshold:
                 print(f"Heatwave expected! Max Temp: {temp_max} at {step['dt_txt']}")
                 return True
        return False
    except KeyError as e:
         print(f"Error parsing weather data: {e}")
         return False

if __name__ == "__main__":
    # Test script directly
    print(f"Checking weather for {CITY}...")
    print(f"Is rain expected in 6 hours? {is_rain_expected()}")
    print(f"Is a heatwave (>38C) expected tomorrow? {is_heatwave_expected()}")
