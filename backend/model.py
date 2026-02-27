import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense
import os
import pandas as pd

MODEL_PATH = "plant_model.h5"

class PlantModel:
    def __init__(self):
        self.model = None
        self.load_model()

    def build_model(self, input_shape):
        model = Sequential()
        model.add(LSTM(50, activation='relu', input_shape=input_shape))
        model.add(Dense(1))
        model.compile(optimizer='adam', loss='mse')
        self.model = model

    def load_model(self):
        if os.path.exists(MODEL_PATH):
            self.model = tf.keras.models.load_model(MODEL_PATH)
            print("Model loaded.")
        else:
            print("No model found. Building new model.")
            # Default shape (time_steps, features)
            self.build_model((10, 4)) 

    def train(self, data):
        """
        Train the model on new data.
        data: List of tuples (soil, temp, hum, light)
        """
        if len(data) < 20:
            print("Not enough data to train.")
            return

        # Prepare data for LSTM
        # (Simplified for example: using last 10 readings to predict next 1)
        X, y = [], []
        time_steps = 10
        
        df = pd.DataFrame(data, columns=['soil', 'temp', 'hum', 'light'])
        values = df.values
        
        for i in range(len(values) - time_steps):
            X.append(values[i:i+time_steps])
            y.append(values[i+time_steps, 0]) # Predict next Soil Moisture
            
        X, y = np.array(X), np.array(y)
        
        if self.model is None:
             self.build_model((time_steps, 4))

        self.model.fit(X, y, epochs=10, batch_size=32, verbose=0)
        self.model.save(MODEL_PATH)
        print("Model trained and saved.")

    def predict(self, recent_data):
        """
        Predict next soil moisture.
        recent_data: List of last 10 readings (tuples)
        """
        if self.model is None or len(recent_data) < 10:
            return None
            
        input_data = np.array([recent_data]) # Shape (1, 10, 4)
        prediction = self.model.predict(input_data)
        return prediction[0][0]
