# API 문서

## 개요

이 문서는 Reia Python API의 상세한 레퍼런스를 제공합니다.

## 목차

1. [확장 초기화](#확장-초기화)
2. [비동기 런타임](#비동기-런타임)
3. [게임 컴포넌트](#게임-컴포넌트)
4. [게임 시스템](#게임-시스템)
5. [유틸리티](#유틸리티)

---

## 확장 초기화

### `initialize_extension()`

Reia 확장을 초기화합니다.

**매개변수**: 없음

**반환값**: `None`

**예제**:
```python
from reia import initialize_extension

initialize_extension()
```

### `deinitialize_extension()`

Reia 확장을 정리하고 종료합니다.

**매개변수**: 없음

**반환값**: `None`

**예제**:
```python
from reia import deinitialize_extension

deinitialize_extension()
```

---

## 비동기 런타임

### `AsyncRuntime`

Godot과 Python asyncio를 연결하는 비동기 런타임 싱글톤입니다.

#### 속성

- `SINGLETON: str` - 싱글톤 이름 ("AsyncIO")

#### 메서드

##### `AsyncRuntime.new() -> AsyncRuntime`

새로운 AsyncRuntime 인스턴스를 생성합니다.

**반환값**: `AsyncRuntime` 인스턴스

**예제**:
```python
runtime = AsyncRuntime.new()
```

##### `AsyncRuntime.singleton() -> Optional[AsyncRuntime]`

AsyncRuntime 싱글톤 인스턴스를 가져옵니다.

**반환값**: `AsyncRuntime` 인스턴스 또는 `None`

**예제**:
```python
runtime = AsyncRuntime.singleton()
if runtime is not None:
    # 런타임 사용
    pass
```

##### `AsyncRuntime.runtime() -> asyncio.AbstractEventLoop`

활성 이벤트 루프를 가져옵니다.

**반환값**: `asyncio.AbstractEventLoop`

**예외**: 싱글톤을 찾을 수 없으면 `RuntimeError`

**예제**:
```python
loop = AsyncRuntime.runtime()
```

##### `AsyncRuntime.spawn(coro: Coroutine) -> asyncio.Task`

런타임에서 비동기 태스크를 생성합니다.

**매개변수**:
- `coro` - 실행할 코루틴

**반환값**: `asyncio.Task`

**예제**:
```python
async def my_task():
    await asyncio.sleep(1)
    return "완료"

task = AsyncRuntime.spawn(my_task())
```

##### `AsyncRuntime.block_on(coro: Coroutine) -> T`

코루틴이 완료될 때까지 현재 스레드를 블로킹합니다.

**매개변수**:
- `coro` - 실행할 코루틴

**반환값**: 코루틴의 결과

**예제**:
```python
async def get_data():
    return "데이터"

result = AsyncRuntime.block_on(get_data())
print(result)  # "데이터"
```

##### `spawn_blocking(func: Callable) -> Future`

스레드 풀에서 블로킹 함수를 실행합니다.

**매개변수**:
- `func` - 실행할 블로킹 함수

**반환값**: `Future`

**예제**:
```python
def heavy_computation():
    # CPU 집약적 작업
    return sum(range(1000000))

runtime = AsyncRuntime.singleton()
future = runtime.spawn_blocking(heavy_computation)
result = future.result()
```

---

## 게임 컴포넌트

### 전투 컴포넌트

#### `Health`

엔티티의 체력을 나타내는 컴포넌트입니다.

**속성**:
- `current: int` - 현재 체력 (기본값: 100)
- `max: int` - 최대 체력 (기본값: 100)

**예제**:
```python
from game.components.combat import Health

# 기본 체력
health = Health()

# 커스텀 체력
health = Health(current=150, max=200)
```

#### `Stats`

엔티티의 전투 능력치를 나타내는 컴포넌트입니다.

**속성**:
- `melee_power: int` - 근접 공격력 (기본값: 10)
- `bow_power: int` - 활 공격력 (기본값: 10)
- `spell_power: int` - 마법 공격력 (기본값: 10)
- `melee_defense: int` - 근접 방어력 (기본값: 5)
- `bow_defense: int` - 활 방어력 (기본값: 5)
- `spell_defense: int` - 마법 방어력 (기본값: 5)
- `crit_chance: int` - 크리티컬 확률 (베이시스 포인트, 기본값: 10)
- `crit_damage: int` - 크리티컬 추가 데미지 (베이시스 포인트, 기본값: 50)

**메서드**:

##### `power_for(attack_type: AttackType) -> int`

특정 공격 유형의 공격력을 가져옵니다.

**매개변수**:
- `attack_type` - 공격 유형

**반환값**: 공격력 값

**예제**:
```python
from game.components.combat import Stats, AttackType

stats = Stats(melee_power=20)
power = stats.power_for(AttackType.MELEE)  # 20
```

##### `defense_for(attack_type: AttackType) -> int`

특정 공격 유형의 방어력을 가져옵니다.

**매개변수**:
- `attack_type` - 공격 유형

**반환값**: 방어력 값

**예제**:
```python
stats = Stats(melee_defense=15)
defense = stats.defense_for(AttackType.MELEE)  # 15
```

#### `AttackType`

공격 유형을 나타내는 열거형입니다.

**값**:
- `MELEE` - 근접 공격
- `BOW` - 활 공격
- `SPELL` - 마법 공격

**예제**:
```python
from game.components.combat import AttackType

attack = AttackType.MELEE
```

#### `resolve_damage()`

공격을 해결하고 데미지를 계산합니다.

**매개변수**:
- `target_health: Health` - 수정할 체력 컴포넌트
- `attacker: Stats` - 공격자의 능력치
- `target: Stats` - 대상의 능력치
- `weapon: AttackType` - 사용하는 공격 유형
- `ability_multiplier: Optional[int]` - 베이시스 포인트로 표현된 스킬 배수
- `rng_roll: int` - 크리티컬 체크를 위한 랜덤 값 (0-10000)

**반환값**: `Tuple[int, bool]` - (적용된 데미지, 크리티컬 여부)

**예제**:
```python
from game.components.combat import resolve_damage, Health, Stats, AttackType

target_health = Health(current=100, max=100)
attacker = Stats(melee_power=15, crit_chance=500)
target = Stats(melee_defense=5)

damage, was_crit = resolve_damage(
    target_health,
    attacker,
    target,
    AttackType.MELEE,
    ability_multiplier=15000,  # 1.5배
    rng_roll=250
)

print(f"데미지: {damage}, 크리티컬: {was_crit}")
print(f"남은 체력: {target_health.current}")
```

### 이동 컴포넌트

#### `Vec3`

3D 벡터를 나타냅니다.

**속성**:
- `x: float`
- `y: float`
- `z: float`

**예제**:
```python
from game.components.movement import Vec3

position = Vec3(1.0, 2.0, 3.0)
velocity = Vec3(0.5, 0.0, 0.5)

# 벡터 연산
result = position + velocity
```

#### `Position`

엔티티의 3D 위치입니다.

**속성**:
- `value: Vec3`

**예제**:
```python
from game.components.movement import Position, Vec3

pos = Position(10.0, 0.0, 5.0)
# 또는
pos = Position(Vec3(10.0, 0.0, 5.0))
```

#### `Rotation`

엔티티의 3D 회전입니다.

**속성**:
- `value: Vec3`

#### `Velocity`

엔티티의 이동 벡터입니다.

**속성**:
- `value: Vec3`

#### `Speed`

엔티티의 이동 속도 스칼라입니다.

**속성**:
- `value: float`

---

## 게임 시스템

### 전투 시스템

#### `AttackEvent`

공격 의도를 나타내는 이벤트입니다.

**속성**:
- `attacker: Any` - 공격하는 엔티티
- `target: Any` - 공격받는 엔티티
- `weapon: AttackType` - 사용하는 공격 유형
- `ability_multiplier_bp: Optional[int]` - 스킬 배수 (베이시스 포인트)

**예제**:
```python
from game.systems.combat import AttackEvent
from game.components.combat import AttackType

attack = AttackEvent(
    attacker=player_entity,
    target=enemy_entity,
    weapon=AttackType.MELEE,
    ability_multiplier_bp=12000  # 1.2배 데미지
)
```

#### `apply_attack_events()`

AttackEvent를 처리하고 데미지를 적용합니다.

**매개변수**:
- `ev_reader` - AttackEvent용 이벤트 리더
- `health_q` - Health 컴포넌트 쿼리 (변경 가능)
- `stats_q` - Stats 컴포넌트 쿼리
- `rng` - 게임 RNG 리소스
- `health_changed` - HealthChanged 이벤트 라이터

**반환값**: `None`

#### `death_system()`

죽은 엔티티를 처리하는 시스템입니다.

**매개변수**:
- `commands` - 엔티티 조작을 위한 명령
- `query` - 변경된 Health 컴포넌트를 가진 엔티티 쿼리

**반환값**: `None`

### RNG 시스템

#### `GameRng`

게임플레이를 위한 결정론적/빠른 RNG 래퍼입니다.

##### `GameRng.from_seed(seed: int) -> GameRng`

명시적 시드로 생성합니다 (실행 간 결정론적).

**매개변수**:
- `seed` - 시드 값

**반환값**: `GameRng` 인스턴스

**예제**:
```python
from game.systems.rng import GameRng

# 멀티플레이어/리플레이용 결정론적 RNG
rng = GameRng.from_seed(12345)
```

##### `GameRng.from_entropy() -> GameRng`

시스템 엔트로피에서 생성합니다 (비결정론적).

**반환값**: `GameRng` 인스턴스

**예제**:
```python
# 싱글플레이어용 랜덤 RNG
rng = GameRng.from_entropy()
```

##### `next_u16_in_basis() -> int`

0..=10000 범위의 베이시스 포인트 랜덤 정수를 생성합니다.

**반환값**: 0-10000 범위의 정수

**예제**:
```python
rng = GameRng.from_seed(42)
roll = rng.next_u16_in_basis()  # 0-10000
```

##### `next_f32() -> float`

0.0-1.0 범위의 랜덤 부동소수점을 생성합니다.

**반환값**: 랜덤 float

**예제**:
```python
value = rng.next_f32()  # 0.0 <= value < 1.0
```

##### `next_u32() -> int`

랜덤 32비트 부호 없는 정수를 생성합니다.

**반환값**: 0-0xFFFFFFFF 범위의 정수

##### `randint(a: int, b: int) -> int`

[a, b] 범위의 랜덤 정수를 생성합니다.

**매개변수**:
- `a` - 하한 (포함)
- `b` - 상한 (포함)

**반환값**: [a, b] 범위의 랜덤 정수

**예제**:
```python
dice_roll = rng.randint(1, 6)  # 1-6
```

##### `choice(seq) -> Any`

비어있지 않은 시퀀스에서 랜덤 요소를 선택합니다.

**매개변수**:
- `seq` - 선택할 시퀀스

**반환값**: seq의 랜덤 요소

**예제**:
```python
loot = rng.choice(['검', '활', '포션'])
```

##### `shuffle(seq) -> None`

시퀀스를 제자리에서 섞습니다.

**매개변수**:
- `seq` - 섞을 시퀀스

**예제**:
```python
deck = [1, 2, 3, 4, 5]
rng.shuffle(deck)
```

---

## 유틸리티

### 베이시스 포인트

베이시스 포인트는 백분율을 정수로 표현하는 방법입니다:

- **10000 = 100%**
- **1000 = 10%**
- **100 = 1%**
- **1 = 0.01%**

이는 네트워크 동기화 버그를 방지하고 정확한 리플레이를 가능하게 합니다.

**변환 예제**:
```python
# 백분율을 베이시스 포인트로
percentage = 25.5  # 25.5%
basis_points = int(percentage * 100)  # 2550

# 베이시스 포인트를 백분율로
basis_points = 7500
percentage = basis_points / 100  # 75.0%
```

**계산 예제**:
```python
BASIS = 10_000
ROUND = BASIS // 2

# 배수 적용 (반올림 포함)
value = 100
multiplier = 15000  # 1.5배
result = int((value * multiplier + ROUND) / BASIS)  # 150
```

---

## 이벤트

### `HealthChanged`

엔티티의 체력이 변경될 때 발생하는 이벤트입니다.

**속성**:
- `entity: Any` - 엔티티 참조
- `health: int` - 새로운 체력 값
- `max_health: int` - 최대 체력

**예제**:
```python
from game.components.combat import HealthChanged

event = HealthChanged(
    entity=player,
    health=75,
    max_health=100
)
```

---

## 프로토콜

### `Entity`

엔티티 타입을 위한 프로토콜입니다.

**속성**:
- `id: Any`

### `EventReader`

이벤트 리더를 위한 프로토콜입니다.

**메서드**:
- `read()` - 이벤트 큐에서 이벤트 읽기

### `EventWriter`

이벤트 라이터를 위한 프로토콜입니다.

**메서드**:
- `write(event: Any)` - 이벤트 큐에 이벤트 쓰기

### `Query`

ECS 쿼리를 위한 프로토콜입니다.

**메서드**:
- `get(entity: Entity)` - 엔티티의 컴포넌트 가져오기
- `get_mut(entity: Entity)` - 엔티티의 변경 가능한 컴포넌트 가져오기
- `iter()` - 쿼리 결과 반복

### `Commands`

ECS 명령을 위한 프로토콜입니다.

**메서드**:
- `entity(entity: Entity)` - 엔티티 명령 가져오기

---

## 타입 힌트

모든 공개 API는 Python 3.14 타입 힌트를 사용합니다:

```python
from typing import Optional, Tuple
from game.components.combat import Health, Stats, AttackType

def calculate_damage(
    attacker: Stats,
    target: Stats,
    attack_type: AttackType,
    multiplier: Optional[int] = None
) -> Tuple[int, bool]:
    # 구현...
    pass
```

타입 체크를 위해 mypy를 사용하세요:
```bash
mypy src/
```

---

## 추가 정보

더 많은 예제와 튜토리얼은 [docs/README.md](./README.md)를 참조하세요.
