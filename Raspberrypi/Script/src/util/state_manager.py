import threading
from enum import Enum, auto


class Status(Enum):
    MONITORING = auto()
    ALERT = auto()


class StateManager:
    def __init__(self, initial_state: Status = Status.MONITORING):
        self._status = initial_state
        self._lock = threading.Lock()
        self._listeners = []

    @property
    def current(self):
        with self._lock:
            return self._status

    def add_listener(self, callback):
        with self._lock:
            self._listeners.append(callback)
        
    def remove_listener(self, callback):
        with self._lock:
            if callback in self._listeners:
                self._listeners.remove(callback)

    def update(self, new_status):
        if isinstance(new_status, str):
            try:
                new_status = Status[new_status.upper()]
            except KeyError:
                print(f"⚠️ Invalid status: {new_status}")
                return
        
        with self._lock:
            if self._status == new_status:
                return
            
            old = self._status
            self._status = new_status
        
        print("-" * 40)
        print(f"🔄 State: {old.name} -> {new_status.name}")
        print("-" * 40)
        self._notify(new_status)

    def _notify(self, new_status):
        status_str = new_status.name.lower() if isinstance(new_status, Status) else new_status
        for callback in self._listeners:
            try:
                callback(status_str)
            except Exception as e:
                print(f"⚠️ Listener Error ({callback.__qualname__}): {e}")