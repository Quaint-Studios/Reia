# Reia - Python 3.14 프로젝트 문서

## 개요

Reia는 Godot 엔진과 통합되는 오픈소스 RPG/MMO 게임 엔진 확장입니다. 이 프로젝트는 원래 Rust로 작성되었으며, Python 3.14로 완전히 변환되었습니다.

## 목차

1. [프로젝트 소개](#프로젝트-소개)
2. [아키텍처](#아키텍처)
3. [주요 기능](#주요-기능)
4. [설치 방법](#설치-방법)
5. [사용 가이드](#사용-가이드)
6. [개발 가이드](#개발-가이드)

## 프로젝트 소개

### 목적

Reia는 다음과 같은 게임 모드를 지원하는 오픈소스 액션 어드벤처 RPG/MMO입니다:

- **싱글플레이 오프라인** - 혼자서 플레이
- **프라이빗 서버** - 친구들과 함께
- **공식 MMO** - 대규모 온라인 멀티플레이어

### 특징

- 플레이어 소유 떠다니는 섬
- 절차적 생성 월드
- 경제 시스템
- ECS (Entity-Component-System) 아키텍처
- 비동기 네트워킹
- 결정론적 게임플레이 (멀티플레이어 지원)

## 아키텍처

### 기술 스택

| 컴포넌트 | 기술 |
|---------|------|
| 게임 엔진 | Godot 4.x |
| 백엔드 언어 | Python 3.14 |
| 비동기 런타임 | asyncio |
| 데이터베이스 | Turso (SQLite 호환) |
| 네트워킹 | 커스텀 프로토콜 (개발 중) |

### 모듈 구조

```
python/
├── src/
│   ├── __init__.py          # 메인 확장 진입점
│   ├── extras/              # Godot 통합 유틸리티
│   │   └── godot_asyncio.py # 비동기 런타임
│   ├── game/                # 게임 로직
│   │   ├── components/      # ECS 컴포넌트
│   │   ├── systems/         # ECS 시스템
│   │   ├── features/        # 기능 플러그인
│   │   ├── world/           # 월드 엔티티
│   │   └── nodes/           # Godot 노드
│   ├── network/             # 네트워킹
│   └── db/                  # 데이터베이스
├── docs/                    # 문서
├── tests/                   # 테스트
└── requirements.txt         # 의존성
```

## 주요 기능

### 1. 비동기 런타임 통합

`AsyncRuntime` 클래스는 Godot의 동기 실행 모델과 Python의 asyncio 비동기 실행을 연결합니다.

```python
from extras.godot_asyncio import AsyncRuntime

# 비동기 태스크 생성
task = AsyncRuntime.spawn(my_coroutine())

# 완료될 때까지 블로킹
result = AsyncRuntime.block_on(my_coroutine())

# 스레드 풀에서 블로킹 함수 실행
future = runtime.spawn_blocking(my_blocking_function)
```

### 2. 전투 시스템

전투 시스템은 부동소수점 정밀도 문제를 피하기 위해 베이시스 포인트(10000 = 100%)를 사용한 고정소수점 연산을 사용합니다.

```python
from game.components.combat import Health, Stats, AttackType, resolve_damage

# 공격자 설정 (크리티컬 확률 5%)
attacker = Stats(melee_power=15, crit_chance=500)
target_health = Health(current=100, max=100)
target_stats = Stats(melee_defense=5)

# 데미지 계산
damage, was_crit = resolve_damage(
    target_health,
    attacker,
    target_stats,
    AttackType.MELEE,
    ability_multiplier=15000,  # 1.5배 데미지
    rng_roll=250  # 0-10000 사이 랜덤값
)
```

#### 베이시스 포인트 시스템

- **10000 = 100%**
- **5000 = 50%**
- **500 = 5%**

네트워크 동기화 버그를 방지하고 정확한 리플레이 시뮬레이션을 가능하게 합니다.

### 3. 결정론적 RNG

`GameRng` 클래스는 시드 기반(결정론적) 및 엔트로피 기반 RNG를 모두 제공합니다:

```python
from game.systems.rng import GameRng

# 결정론적 (멀티플레이어/리플레이용)
rng = GameRng.from_seed(12345)

# 비결정론적 (싱글플레이어용)
rng = GameRng.from_entropy()

# 값 생성
roll = rng.next_u16_in_basis()  # 0-10000
value = rng.next_f32()          # 0.0-1.0
```

### 4. ECS 컴포넌트

#### Health (체력)

```python
@dataclass
class Health(Component):
    current: int = 100
    max: int = 100
```

#### Stats (능력치)

```python
@dataclass
class Stats(Component):
    melee_power: int = 10      # 근접 공격력
    bow_power: int = 10        # 활 공격력
    spell_power: int = 10      # 마법 공격력

    melee_defense: int = 5     # 근접 방어력
    bow_defense: int = 5       # 활 방어력
    spell_defense: int = 5     # 마법 방어력

    crit_chance: int = 10      # 크리티컬 확률 (베이시스 포인트)
    crit_damage: int = 50      # 크리티컬 추가 데미지 (베이시스 포인트)
```

#### Movement (이동)

```python
@dataclass
class Position:
    value: Vec3 = Vec3(0.0, 0.0, 0.0)

@dataclass
class Velocity:
    value: Vec3 = Vec3(0.0, 0.0, 0.0)

@dataclass
class Speed:
    value: float = 1.0
```

## 설치 방법

### 요구사항

- Python 3.14 이상
- pip

### 설치 단계

```bash
# 저장소 클론
git clone https://github.com/eightynine01/Reia.git
cd Reia/python

# 의존성 설치
pip install -r requirements.txt

# 또는 개발 모드로 설치
pip install -e ".[dev]"
```

## 사용 가이드

### 기본 사용법

```python
from reia import initialize_extension, deinitialize_extension

# 확장 초기화
initialize_extension()

# ... 게임 로직 ...

# 확장 정리
deinitialize_extension()
```

### 전투 시스템 사용

```python
from game.components.combat import AttackEvent
from game.systems.combat import apply_attack_events

# 공격 이벤트 생성
attack = AttackEvent(
    attacker=player_entity,
    target=enemy_entity,
    weapon=AttackType.MELEE,
    ability_multiplier_bp=12000  # 1.2배 데미지
)

# 이벤트 처리
apply_attack_events(
    ev_reader,
    health_query,
    stats_query,
    rng,
    health_changed_writer
)
```

## 개발 가이드

### 테스트 실행

```bash
# 모든 테스트 실행
pytest

# 특정 테스트 파일 실행
pytest tests/test_combat.py

# 커버리지와 함께 실행
pytest --cov=src
```

### 코드 포맷팅

```bash
# 코드 포맷팅
black src/

# 린트 검사
ruff check src/

# 자동 수정
ruff check --fix src/
```

### 타입 체크

```bash
# 타입 체크 실행
mypy src/
```

### 개발 워크플로우

1. **기능 브랜치 생성**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **코드 작성 및 테스트**
   ```bash
   # 테스트 작성
   vim tests/test_my_feature.py

   # 기능 구현
   vim src/game/my_feature.py

   # 테스트 실행
   pytest tests/test_my_feature.py
   ```

3. **코드 품질 검사**
   ```bash
   black src/
   ruff check src/
   mypy src/
   ```

4. **커밋 및 푸시**
   ```bash
   git add .
   git commit -m "feat: 새로운 기능 추가"
   git push origin feature/my-feature
   ```

## Rust 버전과의 차이점

### 타입 안전성

- **Rust**: 컴파일 타임 타입 체크, 소유권 시스템
- **Python**: 런타임 타입 체크, mypy를 통한 선택적 정적 분석

### 성능

- **Rust**: 컴파일됨, 제로 비용 추상화
- **Python**: 인터프리터, 동적 타입
- **영향**: Rust 버전이 계산 집약적 작업에서 10-100배 빠름
- **완화**: PyPy 또는 Cython 사용 가능

### 메모리 관리

- **Rust**: 소유권 시스템, 명시적 수명
- **Python**: 가비지 컬렉션, 참조 카운팅

### 동시성

- **Rust**: Send/Sync 트레잇, 안전한 동시성
- **Python**: GIL로 인한 진정한 병렬성 제한
- **완화**: CPU 바운드 작업에 multiprocessing 사용

## 프로젝트 상태

현재 알파 버전으로 핵심 시스템이 구현되어 있습니다:

- ✅ AsyncIO 통합
- ✅ 전투 컴포넌트 및 시스템
- ✅ 이동 컴포넌트
- ✅ RNG 시스템
- ⚠️  네트워크 시스템 (플레이스홀더)
- ⚠️  데이터베이스 통합 (플레이스홀더)
- ⚠️  게임 월드 엔티티 (플레이스홀더)
- ⚠️  AI 시스템 (플레이스홀더)

## 기여하기

이 프로젝트는 Rust에서 Python 3.14로 변환되었습니다. 기여 시 원래 아키텍처와의 일관성을 유지해 주세요.

## 라이선스

MIT License (원래 Rust 버전과 동일)

## 참고 문서

- [변환 요약](./변환_요약.md) - 상세한 변환 노트
- [API 문서](./API_문서.md) - API 레퍼런스
- [설치 가이드](./설치_가이드.md) - 상세 설치 안내

## 원본 Rust 버전

원본 Rust 구현은 `/rust` 디렉토리에서 찾을 수 있습니다.
