import cv2
import time
import os

class CameraManager:
    def __init__(self):
        self.tmp_dir = "/tmp"

    def capture(self):
        timestamp = int(time.time())
        filename = f"{timestamp}.jpg"
        filepath = os.path.join(self.tmp_dir, filename)

        cap = cv2.VideoCapture(0)
        if cap.isOpened():
            ret, frame = cap.read()
            if ret:
                cv2.imwrite(filepath, frame)
                cap.release()
                return filepath, filename
            cap.release()
        
        # 失敗時(ダミー)
        print("⚠️ Camera not found. Creating dummy.")
        with open(filepath, "w") as f:
            f.write("Dummy")
        return filepath, filename

    def cleanup(self, filepath):
        if os.path.exists(filepath):
            os.remove(filepath)