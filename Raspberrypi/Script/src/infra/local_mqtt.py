import paho.mqtt.client as mqtt
import json
import threading

class LocalZigbeeClient:
    def __init__(self, host="localhost", port=1883):
        self.client = mqtt.Client()
        self.host = host
        self.port = port
        self._pressed = threading.Event()
        
        # 設定
        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message

    def connect(self):
        try:
            self.client.connect(self.host, self.port, 60)
            self.client.loop_start()
            print("🔌 Zigbee MQTT Connected")
        except Exception as e:
            print(f"⚠️ Zigbee MQTT Failed: {e}")

    def _on_connect(self, client, userdata, flags, rc):
        client.subscribe("zigbee2mqtt/emergency_button")

    def _on_message(self, client, userdata, msg):
        try:
            payload = json.loads(msg.payload.decode())
            action = payload.get("action")
            if action == "single":
                self._pressed.set()
        except Exception:
            pass

    def is_pressed(self):
        if self._pressed.is_set():
            self._pressed.clear()
            return True
        return False

    def disconnect(self):
        try:
            self.client.loop_stop()
            self.client.disconnect()
            print("🔌 Zigbee MQTT Disconnected")
        except Exception:
            pass