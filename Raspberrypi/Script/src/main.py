import time
import threading
from util.config import Config
from util.mqtt_client import IotClient
from util.state_manager import StateManager
from util.storage import StorageManager
from util.camera import CameraManager
from util.service import SurveillanceService


class ElderlyWatcherApp:
    def __init__(self, state_manager, iot_client, surveillance_service):
        # 1. 部品の生成
        self.state = state_manager
        self.iot = iot_client
        self.surveillance_service = surveillance_service
        self._alert_thread = None
        self._stop_alert = threading.Event()

        # 2. 部品の接続 (Wiring)
        # 「ステータスが変わったら、AWSに報告してね」と登録
        self.state.add_listener(self.iot.report_status)
        # 「ステータスが変わったら、対応する処理を実行してね」と登録
        self.state.add_listener(self.surveillance_service._handle_state_change)

    def run(self):
        # 接続開始
        self.iot.connect()
        
        # 現在の状態をAWSに初期報告
        self.state.update(StateManager.Status.MONITORING)

        print("🚀 System Started.")
        try:
            # メインスレッドは待機するだけ（状態変更はIoTから来る）
            while True:
                # ここに物理ボタン監視を入れるなら：
                # if button.is_pressed(): 
                #     self.state.update(StateManager.Status.ALERT)
                time.sleep(1)

        except KeyboardInterrupt:
            print("Stopping...")
            self.surveillance_service.stop_monitoring()

if __name__ == "__main__":
    state_manager = StateManager(initial_state=StateManager.Status.MONITORING)
    iot_client = IotClient(on_delta_callback=state_manager.update)
    camera_manager = CameraManager()
    storage_manager = StorageManager()
    surveillance_service = SurveillanceService(camera_manager, storage_manager)
    app = ElderlyWatcherApp(state_manager, iot_client, surveillance_service)
    app.run()