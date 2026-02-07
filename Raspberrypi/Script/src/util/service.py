import threading
import time
from util.config import Config

class SurveillanceService:
    def __init__(self, camera_manager, storage_manager):
        # 依存オブジェクトをDIで受け取る
        self.camera = camera_manager
        self.storage = storage_manager
        
        # スレッド制御用
        self._thread = None
        self._stop_event = threading.Event()
        
    def _handle_state_change(self, new_status):
        """状態変更時に呼ばれるハンドラー（State Managerから自動で呼ばれる）"""
        if new_status == "alert":
            self.start_monitoring()
        else:
            self.stop_monitoring()

    def start_monitoring(self):
        """監視(撮影ループ)を開始する"""
        if self._thread and self._thread.is_alive():
            print("⚠️ Already monitoring.")
            return

        print("📸 Alert Mode: Start capturing images")
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._capture_loop, daemon=True)
        self._thread.start()

    def stop_monitoring(self):
        """監視を停止する"""
        if not self._thread or not self._thread.is_alive():
            return

        print("👁️ Monitoring Mode: Stop capturing")
        self._stop_event.set()
        self._thread.join(timeout=2)
        self._thread = None

    def _capture_loop(self):
        """(内部メソッド) 撮影とアップロードの繰り返し"""
        while not self._stop_event.is_set():
            try:
                # カメラとストレージの連携ロジック
                path, filename = self.camera.capture()
                
                # 成功したらアップロード
                if path:
                    self.storage.upload(path, filename, Config.THING_NAME)
                    self.camera.cleanup(path)
                
            except Exception as e:
                print(f"⚠️ Capture Error: {e}")
            
            time.sleep(Config.IMAGE_INTERVAL)