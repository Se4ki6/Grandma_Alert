import threading

class StateManager:
    def __init__(self, initial_state="monitoring"):
        self._status = initial_state
        self._lock = threading.Lock()
        self._listeners = [] # 変更を通知する相手リスト

    @property
    def current(self):
        """現在のステータスを読み取る"""
        with self._lock:
            return self._status

    def add_listener(self, callback):
        """状態が変わった時に呼んでほしい関数を登録する"""
        self._listeners.append(callback)

    def update(self, new_status):
        """ステータスを更新する (変更があった場合のみ通知)"""
        with self._lock:
            if self._status == new_status:
                return # 変更なしなら何もしない
            
            print(f"🔄 State Transition: {self._status} -> {new_status}")
            self._status = new_status
        
        # ロックを解放してから通知 (デッドロック防止)
        self._notify(new_status)

    def _notify(self, new_status):
        """登録されたリスナー全員に知らせる"""
        for callback in self._listeners:
            try:
                callback(new_status)
            except Exception as e:
                print(f"⚠️ State Listener Error: {e}")