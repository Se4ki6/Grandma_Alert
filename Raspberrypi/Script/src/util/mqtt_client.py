import json
from awscrt import io, mqtt
from awsiot import mqtt_connection_builder
from util.config import config
from util.state_manager import Status

class IotClient:
    def __init__(self, on_delta_callback):
        self.connection = None
        self.on_delta_callback = on_delta_callback

    def connect(self):
        event_loop_group = io.EventLoopGroup(1)
        host_resolver = io.DefaultHostResolver(event_loop_group)
        client_bootstrap = io.ClientBootstrap(event_loop_group, host_resolver)

        self.connection = mqtt_connection_builder.mtls_from_path(
            endpoint=config.endpoint,
            cert_filepath=config.cert_path,
            pri_key_filepath=config.key_path,
            ca_filepath=config.root_path,
            client_id=config.client_id,
            client_bootstrap=client_bootstrap,
            clean_session=False,
            keep_alive_secs=30
        )
        self.connection.connect().result()
        print("✅ AWS IoT Connected")
        
        self._subscribe_delta()
        self._subscribe_shadow_responses()

    def _subscribe_delta(self):
        topic = f"$aws/things/{config.thing_name}/shadow/update/delta"
        self.connection.subscribe(
            topic=topic,
            qos=mqtt.QoS.AT_LEAST_ONCE,
            callback=self._on_message
        )
        print(f"📡 Subscribed: delta")
    
    def _subscribe_shadow_responses(self):
        accepted_topic = f"$aws/things/{config.thing_name}/shadow/update/accepted"
        rejected_topic = f"$aws/things/{config.thing_name}/shadow/update/rejected"
        
        self.connection.subscribe(
            topic=accepted_topic,
            qos=mqtt.QoS.AT_LEAST_ONCE,
            callback=lambda topic, payload, **kwargs: None
        )
        self.connection.subscribe(
            topic=rejected_topic,
            qos=mqtt.QoS.AT_LEAST_ONCE,
            callback=lambda topic, payload, **kwargs: print(f"❌ Shadow Rejected: {payload.decode()}")
        )
    
    def _on_message(self, topic, payload, **kwargs):
        try:
            data = json.loads(payload)
            if "state" in data and "status" in data["state"]:
                status = data["state"]["status"]
                print(f"📩 Delta received: status={status}")
                self.on_delta_callback(status)
            else:
                print(f"⚠️ Delta missing 'status'")
        except Exception as e:
            print(f"⚠️ Delta Parse Error: {e}")

    def report_status(self, status):
        if isinstance(status, Status):
            status = status.name.lower()
        
        payload = json.dumps({"state": {"reported": {"status": status}}})
        topic = f"$aws/things/{config.thing_name}/shadow/update"
        
        try:
            result = self.connection.publish(
                topic=topic,
                payload=payload,
                qos=mqtt.QoS.AT_LEAST_ONCE
            )
            # SDKバージョンによって戻り値が異なる
            # resultメソッドがあれば呼ぶ
            if hasattr(result, 'result'):
                result.result()
            elif isinstance(result, tuple) and len(result) > 1 and hasattr(result[1], 'result'):
                result[1].result()
            print(f"� Reported: {status}")
        except Exception as e:
            print(f"❌ Report Error: {e}")