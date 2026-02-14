import time
from util.mqtt_client import IotClient
from util.state_manager import StateManager, Status
from util.storage import StorageManager
from util.camera import CameraManager
from util.service import SurveillanceService
from infra.local_mqtt import LocalZigbeeClient


class ElderlyWatcherApp:
    def __init__(self, state_manager, iot_client, surveillance_service, zigbee_client):
        self.state = state_manager
        self.iot = iot_client
        self.surveillance_service = surveillance_service
        self.zigbee = zigbee_client

        self.state.add_listener(self.iot.report_status)
        self.state.add_listener(self.surveillance_service._handle_state_change)

    def run(self):
        self.iot.connect()
        self.zigbee.connect()
        
        time.sleep(1)
        self.iot.report_status(self.state.current)

        print("=" * 50)
        print("🚀 System Started. Waiting for events...")
        print("=" * 50)
        
        try:
            while True:
                if self.zigbee.is_pressed(): 
                    print("=" * 50)
                    print("🔘 Emergency button pressed!")
                    print("=" * 50)
                    self.state.update(Status.ALERT)
                time.sleep(1)

        except KeyboardInterrupt:
            print("=" * 50)
            print("🛑 Shutting down...")
            self.surveillance_service.stop_monitoring()
            self.zigbee.disconnect()
            print("👋 Goodbye.")
            print("=" * 50)

if __name__ == "__main__":
    print("="*50)
    print("🏠 ElderlyWatcher App Initializing...")
    print("="*50)
    
    state_manager = StateManager(initial_state=Status.MONITORING)
    iot_client = IotClient(on_delta_callback=state_manager.update)
    camera_manager = CameraManager()
    storage_manager = StorageManager()
    surveillance_service = SurveillanceService(camera_manager, storage_manager)
    zigbee = LocalZigbeeClient()
    
    app = ElderlyWatcherApp(state_manager, iot_client, surveillance_service, zigbee)
    app.run()