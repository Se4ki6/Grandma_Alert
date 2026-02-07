import json
from awscrt import io, mqtt
from awsiot import mqtt_connection_builder
from src.config import Config

class IotClient:
    def __init__(self, on_delta_callback):
        self.connection = None
        self.on_delta_callback = on_delta_callback # 外部から注入された関数

    def connect(self):
        event_loop_group = io.EventLoopGroup(1)
        host_resolver = io.DefaultHostResolver(event_loop_group)
        client_bootstrap = io.ClientBootstrap(event_loop_group, host_resolver)

        self.connection = mqtt_connection_builder.mtls_from_path(
            endpoint=Config.ENDPOINT,
            cert_filepath=Config.CERT_PATH,
            pri_key_filepath=Config.KEY_PATH,
            ca_filepath=Config.ROOT_PATH,
            client_id=Config.CLIENT_ID,
            client_bootstrap=client_bootstrap,
            clean_session=False,
            keep_alive_secs=30
        )
        print(f"Connecting to {Config.ENDPOINT}...")
        self.connection.connect().result()
        print("✅ Connected!")
        
        # Deltaの購読開始
        self._subscribe_delta()

    def _subscribe_delta(self):
        topic = f"$aws/things/{Config.THING_NAME}/shadow/update/delta"
        self.connection.subscribe(
            topic=topic,
            qos=mqtt.QoS.AT_LEAST_ONCE,
            callback=self._on_message
        )

    def _on_message(self, topic, payload, **kwargs):
        """メッセージを受け取ったら、登録されたコールバック関数を呼ぶ"""
        try:
            data = json.loads(payload)
            if "state" in data and "status" in data["state"]:
                status = data["state"]["status"]
                # 司令塔(Main)に伝える
                self.on_delta_callback(status)
        except Exception as e:
            print(f"Parse Error: {e}")

    def report_status(self, status):
        """AWSに現在のステータスを報告"""
        payload = json.dumps({"state": {"reported": {"status": status}}})
        topic = f"$aws/things/{Config.THING_NAME}/shadow/update"
        self.connection.publish(
            topic=topic,
            payload=payload,
            qos=mqtt.QoS.AT_LEAST_ONCE
        )
        print(f"🗣 Reported: {status}")