import time
from src.config import Config
from src.camera import CameraManager
from src.storage import StorageManager
from src.mqtt_client import IotClient
from src.state_manager import StateManager # ★追加

class ElderlyWatcherApp:
    def __init__(self):
        # 1. 部品の生成
        self.state = StateManager(initial_state="monitoring")
        self.camera = CameraManager()
        self.storage = StorageManager()
        
        # MQTTクライアント生成 (命令が来たら State を更新するよう依頼)
        self.iot = IotClient(on_delta_callback=self.state.update)

        # 2. 部品の接続 (Wiring)
        # 「ステータスが変わったら、AWSに報告(Report)してね」と登録
        self.state.add_listener(self.iot.report_status)

    def run(self):
        # 接続開始
        self.iot.connect()
        
        # 現在の状態をAWSに初期報告
        # (updateを呼ぶことで listener 経由で report が走る)
        self.state.update("monitoring")

        print("🚀 System Started.")
        try:
            while True:
                # 現在のステータスを取得
                current = self.state.current

                # --- 緊急モード ---
                if current == "alert":
                    path, filename = self.camera.capture()
                    self.storage.upload(path, filename, Config.THING_NAME)
                    self.camera.cleanup(path)
                    time.sleep(Config.IMAGE_INTERVAL)
                
                # --- 見守りモード ---
                else:
                    # ここに物理ボタン監視を入れるなら
                    # if button.is_pressed(): self.state.update("alert")
                    time.sleep(1)

        except KeyboardInterrupt:
            print("Stopping...")

if __name__ == "__main__":
    ElderlyWatcherApp().run()