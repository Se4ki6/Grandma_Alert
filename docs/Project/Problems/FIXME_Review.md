# コードレビュー FIXME一覧

レビュー指摘事項をまとめたドキュメントです。

---

## 概要

| #   | ファイル         | 行  | カテゴリ | 概要                               |
| --- | ---------------- | --- | -------- | ---------------------------------- |
| 1   | main.py          | L8  | 設計     | クラス化の必要性                   |
| 2   | main.py          | L10 | DI       | インスタンスの引数渡し             |
| 3   | main.py          | L13 | DI       | DI違反                             |
| 4   | main.py          | L18 | DI       | ステータスインスタンスの依存性注入 |
| 5   | config.py        | L7  | 設計     | クラス化の必要性                   |
| 6   | state_manager.py | L5  | 型安全性 | ステータスのenum化                 |
| 7   | state_manager.py | L17 | 設計     | delete_listenerの追加              |

---

## 詳細

### 1. ElderlyWatcherAppクラスの存在意義

**ファイル**: `Raspberrypi/Script/src/main.py` (L8)

```python
# fixme:ここのクラス化意味ない？（薄いからなくす）
class ElderlyWatcherApp:
```

**問題点**:

- クラスが薄い（ロジックが少ない）ため、クラス化するメリットが薄い可能性がある

**検討事項**:

- 単純なスクリプトとして書き直す
- または今後の拡張を見据えてクラスを維持する

---

### 2. コンストラクタでのインスタンス生成

**ファイル**: `Raspberrypi/Script/src/main.py` (L10)

```python
# fixme:各インスタンスは引数として渡すべき
def __init__(self):
```

**問題点**:

- 各依存クラスのインスタンスをコンストラクタ内で直接生成している
- テスト時にモックを注入しにくい

**改善案**:

```python
def __init__(self, state=None, camera=None, storage=None, iot=None):
    self.state = state or StateManager(initial_state="monitoring")
    self.camera = camera or CameraManager()
    # ...
```

---

### 3. DI違反（依存性の直接注入）

**ファイル**: `Raspberrypi/Script/src/main.py` (L13)

```python
# fixme:DI違反（インスタンスを直接プロパティに注入している）
self.state = StateManager(initial_state="monitoring")
self.camera = CameraManager()
self.storage = StorageManager()
```

**問題点**:

- 依存オブジェクトをコンストラクタ内で直接生成している
- クラス間の結合度が高くなっている
- 単体テストでのモック差し替えが困難

**改善案**:

- コンストラクタインジェクションを採用
- ファクトリパターンの導入を検討

---

### 4. ステータスインスタンスの依存性注入

**ファイル**: `Raspberrypi/Script/src/main.py` (L18)

```python
# fixme:引数はステータスのインスタンスごと渡せば依存性注入できそう
# MQTTクライアント生成 (命令が来たら State を更新するよう依頼)
self.iot = IotClient(on_delta_callback=self.state.update)
```

**問題点**:

- `IotClient`に`state.update`メソッドをコールバックとして渡しているが、`StateManager`インスタンス全体を渡す方がより柔軟

**改善案**:

```python
self.iot = IotClient(state_manager=self.state)
```

---

### 5. Configクラスの存在意義

**ファイル**: `Raspberrypi/Script/src/util/config.py` (L7)

```python
# fixme:クラス化する意味ない？
class Config:
    ENDPOINT = os.getenv("IOT_ENDPOINT")
    # ...
```

**問題点**:

- 全てクラス変数で、インスタンス化する必要がない
- モジュールレベルの定数で十分かもしれない

**検討事項**:

- 名前空間としてクラスを使う（現状維持）
- `dataclass`や`NamedTuple`での実装
- 単純なモジュールレベル定数に変更

---

### 6. ステータスのenum化

**ファイル**: `Raspberrypi/Script/src/util/state_manager.py` (L5)

```python
# fixme: ステータスはenumにするべき？
def __init__(self, initial_state="monitoring"):
    self._status = initial_state
```

**問題点**:

- ステータスが文字列で管理されているため、タイポや不正な値が入る可能性がある
- IDEの補完が効きにくい

**改善案**:

```python
from enum import Enum

class Status(Enum):
    MONITORING = "monitoring"
    ALERT = "alert"
```

---

### 7. delete_listenerの追加

**ファイル**: `Raspberrypi/Script/src/util/state_manager.py` (L17)

```python
# fixme: observewerパターンとしてはdelete_listenerも必要か？
def add_listener(self, callback):
    """状態が変わった時に呼んでほしい関数を登録する"""
    self._listeners.append(callback)
```

**問題点**:

- Observerパターンとしては、リスナーの登録解除機能も必要
- メモリリークやリスナーの重複登録の原因になる可能性

**改善案**:

```python
def remove_listener(self, callback):
    """登録されたリスナーを解除する"""
    if callback in self._listeners:
        self._listeners.remove(callback)
```

---

## 優先度（推奨）

| 優先度 | FIXME # | 理由                               |
| ------ | ------- | ---------------------------------- |
| 高     | 2, 3, 4 | DI対応はテスタビリティに直結       |
| 中     | 6       | 型安全性の向上                     |
| 低     | 1, 5, 7 | 機能には影響しないリファクタリング |

---

_作成日: 2026年2月7日_
