#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include <Wire.h>
#include <BH1750.h>
#include <ArduinoJson.h>

// --- Configuration ---
const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
const char* serverUrl = "http://192.168.1.100:5000/api/sensors"; // Update with Pi IP

// --- Pins ---
#define DHTPIN 4
#define DHTTYPE DHT22
#define SOIL_PIN 34
#define RELAY_PIN 5

// --- Objects ---
DHT dht(DHTPIN, DHTTYPE);
BH1750 lightMeter;

void setup() {
  Serial.begin(115200);
  
  // Initialize Sensors
  dht.begin();
  Wire.begin();
  lightMeter.begin();
  
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // Pump OFF initially

  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    // Read Sensors
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();
    float soilMoisture = map(analogRead(SOIL_PIN), 4095, 0, 0, 100); // Inverse map for Capacitive
    float lux = lightMeter.readLightLevel();

    // Create JSON Payload
    StaticJsonDocument<200> doc;
    doc["temperature"] = temperature;
    doc["humidity"] = humidity;
    doc["soil_moisture"] = soilMoisture;
    doc["light_intensity"] = lux;
    
    String requestBody;
    serializeJson(doc, requestBody);

    // Send POST Request
    int httpResponseCode = http.POST(requestBody);
    
    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.println(httpResponseCode);
      Serial.println(response);

      // Parse Command from Response (if any)
      StaticJsonDocument<200> respDoc;
      deserializeJson(respDoc, response);
      const char* command = respDoc["command"];
      
      if (strcmp(command, "water_on") == 0) {
        digitalWrite(RELAY_PIN, HIGH);
      } else if (strcmp(command, "water_off") == 0) {
        digitalWrite(RELAY_PIN, LOW);
      }
      
    } else {
      Serial.print("Error on sending POST: ");
      Serial.println(httpResponseCode);
    }
    http.end();
  } else {
    Serial.println("WiFi Disconnected");
  }
  
  delay(5000); // Send data every 5 seconds
}
