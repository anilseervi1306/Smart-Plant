import firebase_admin
from firebase_admin import credentials, firestore, db
import os
import threading
import database

# Path to service account key (User needs to provide this)
CRED_PATH = "serviceAccountKey.json"

class CloudSync:
    def __init__(self):
        self.is_connected = False
        if os.path.exists(CRED_PATH):
            try:
                cred = credentials.Certificate(CRED_PATH)
                firebase_admin.initialize_app(cred, {
                    'databaseURL': 'https://YOUR_PROJECT_ID.firebaseio.com'
                })
                self.db = firestore.client()
                self.is_connected = True
                print("Firebase connected.")
            except Exception as e:
                print(f"Firebase init error: {e}")
        else:
            print("Firebase credentials not found. Offline mode only.")

    def upload_reading(self, data):
        """
        Upload sensor reading to Firestore/Realtime DB.
        Run in background thread to avoid blocking.
        """
        if not self.is_connected:
            return

        def _upload():
            try:
                # Firestore upload
                doc_ref = self.db.collection('readings').document()
                doc_ref.set(data.dict())
                print("Data synced to cloud.")
            except Exception as e:
                print(f"Sync failed: {e}")

        threading.Thread(target=_upload).start()

# Global Instance
cloud_manager = CloudSync()

def sync_data(data):
    cloud_manager.upload_reading(data)
