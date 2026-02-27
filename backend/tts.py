import pyttsx3

class PlantTTS:
    def __init__(self):
        self.engine = pyttsx3.init()
        # Set properties (optional)
        self.engine.setProperty('rate', 150)
        self.engine.setProperty('volume', 0.9)

    def speak(self, text):
        """
        Convert text to speech.
        """
        print(f"TTS: {text}")
        self.engine.say(text)
        self.engine.runAndWait()

# Global instance
tts = PlantTTS()

def speak_message(message):
    tts.speak(message)
