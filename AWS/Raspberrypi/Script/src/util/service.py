import threading
import time
from util.config import config
import requests

class SurveillanceService:
    def __init__(self, camera_manager, storage_manager):
        self.camera = camera_manager
        self.storage = storage_manager
        self._thread = None
        self._stop_event = threading.Event()
        
    def _handle_state_change(self, new_status):
        if new_status == "alert":
            self.start_monitoring()
        else:
            self.stop_monitoring()

    def start_monitoring(self):
        if self._thread and self._thread.is_alive():
            return

        print("📸 Alert: Capture loop starting...")
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._thread.start()

    def stop_monitoring(self):
        if not self._thread or not self._thread.is_alive():
            return

        print("👁️ Monitoring: Capture loop stopping...")
        self._stop_event.set()
        self._thread.join(timeout=2)
        self._thread = None
        print("👁️ Capture loop stopped.")

    def _capture_loop(self):
        while not self._stop_event.is_set():
            try:
                url = "https://zrv7g2ggwfbdxwm6ppeii4smdu0gjwoz.lambda-url.ap-northeast-1.on.aws/"
                resp = requests.post(url, json={"trigger": "manual"}, timeout=10)
                print(f"📷 Lambda: {resp.status_code}")
            except requests.exceptions.Timeout:
                print(f"⚠️ Lambda timeout")
            except requests.exceptions.ConnectionError:
                print(f"⚠️ Lambda connection error")
            except Exception as e:
                print(f"⚠️ Capture Error: {type(e).__name__}: {e}")
            
            time.sleep(config.image_interval)