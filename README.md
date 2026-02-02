# Vibration Analyzer

**설비 예지보전을 위한 프로덕션급 진동 분석기 앱**

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()
[![Build](https://img.shields.io/badge/Build-Passing-green.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg)]()

## 🔗 Quick Links

| 리소스 | URL |
|--------|-----|
| **GitHub Repository** | https://github.com/daper-corp/vibration-analyzer |
| **웹 데모** | https://5060-iqxyh1sysjapvts6gbdl2-8f57ffe2.sandbox.novita.ai |
| **APK 다운로드** | `build/app/outputs/flutter-apk/app-release.apk` (17.6MB) |

---

## 📱 앱 개요

Vibration Analyzer는 스마트폰 가속도계를 활용하여 산업 설비의 진동을 측정하고 분석하는 전문 진단 도구입니다. ISO 10816 국제 표준을 준수하여 설비 상태를 자동 판정하며, 베어링 결함 주파수 분석을 통한 예지보전을 지원합니다.

### 주요 특징

- **FFT 스펙트럼 분석**: 1024/2048/4096 포인트 선택 가능
- **ISO 10816-1/3 자동 판정**: 기계 등급별 Zone A~D 평가
- **베어링 결함 진단**: BPFO, BPFI, BSF, FTF 주파수 계산
- **오프라인 완전 동작**: 네트워크 없이 현장 사용 가능
- **현장 최적화 UX**: 150px 대형 버튼, 화면 꺼짐 방지, 강화 햅틱 피드백

---

## 🏗️ 기술 스택

### 측정 엔진
| 구성요소 | 사양 |
|----------|------|
| 센서 | SensorManager (accelerometerEventStream) |
| 샘플링 레이트 | 200Hz 목표 (기기 의존) |
| FFT 알고리즘 | Cooley-Tukey radix-2 |
| 윈도우 함수 | Hanning, Hamming, Flat-Top, Rectangular |
| 안티앨리어싱 | IIR 저역통과 필터 (fc = fs/2.5) |
| 신호 평균화 | Linear / Exponential |

### 프레임워크 및 라이브러리
```yaml
dependencies:
  flutter: 3.35.4
  sensors_plus: 6.1.x          # 가속도계 센서
  fl_chart: 0.70.x             # 스펙트럼/파형 차트
  hive_flutter: 1.1.0          # 로컬 DB (오프라인)
  provider: 6.1.5+1            # 상태 관리
  wakelock_plus: 1.2.x         # 화면 꺼짐 방지
  pdf: 3.11.x                  # PDF 리포트 생성
  csv: 6.0.x                   # CSV 내보내기
```

---

## 📊 측정 파라미터

### 진동 값
| 파라미터 | 단위 | 설명 |
|----------|------|------|
| 가속도 RMS | m/s², g | 실효값 (진동 에너지) |
| 가속도 Peak | m/s², g | 최대값 (충격 감지) |
| 속도 RMS | mm/s | ISO 10816 평가 기준값 |
| 속도 Peak | mm/s | 최대 속도 |
| 변위 RMS | μm | 저주파 진동 지표 |
| 변위 Peak | μm | 최대 변위 |
| Crest Factor | - | Peak/RMS (충격 지표) |
| Kurtosis | - | 첨도 (임펄스 지표) |

### 단위 변환
```
가속도 → 속도: 적분 (사다리꼴 적분법 + 2Hz 고역통과 필터)
속도 → 변위: 이중 적분 (DC 드리프트 제거)
1g = 9.80665 m/s²
```

---

## 🏭 ISO 10816-1 진동 심각도 기준

### 기계 등급 정의
| 등급 | 정격 출력 | 설치 조건 | 예시 |
|------|----------|----------|------|
| Class I | ≤ 15 kW | - | 소형 모터, 펌프 |
| Class II | 15-75 kW | - | 중형 모터, 펌프 |
| Class III | > 75 kW | 강성 기초 | 대형 펌프, 팬 |
| Class IV | > 75 kW | 유연 기초 | 터보 기계 |

### 판정 기준 (속도 RMS, mm/s)
| Zone | Class I | Class II | Class III | Class IV | 상태 |
|------|---------|----------|-----------|----------|------|
| **A** | < 0.71 | < 1.12 | < 1.8 | < 2.8 | 양호 (신품 수준) |
| **B** | 0.71-1.8 | 1.12-2.8 | 1.8-4.5 | 2.8-7.1 | 만족 (장기 운전 가능) |
| **C** | 1.8-4.5 | 2.8-7.1 | 4.5-11.2 | 7.1-18.0 | 불만족 (단기 운전만) |
| **D** | > 4.5 | > 7.1 | > 11.2 | > 18.0 | 불허 (손상 위험) |

---

## 🔩 베어링 결함 주파수

### 계산 공식
```
BPFO = (n/2) × fr × (1 - d/D × cosθ)    # 외륜 결함
BPFI = (n/2) × fr × (1 + d/D × cosθ)    # 내륜 결함
BSF  = (D/2d) × fr × (1 - (d/D×cosθ)²)  # 전동체 결함
FTF  = (fr/2) × (1 - d/D × cosθ)        # 케이지 결함

여기서:
  n  = 전동체 개수
  fr = 축 회전 주파수 (RPM/60)
  d  = 전동체 직경 (mm)
  D  = 피치원 직경 (mm)
  θ  = 접촉각 (도)
```

### 내장 베어링 데이터베이스
- 6205, 6206, 6207, 6208, 6209, 6210 (심구 볼베어링)
- 6305, 6306 (심구 볼베어링)
- 7205, 7206 (앵귤러 콘택트)
- NU205, NU206 (원통 롤러베어링)

---

## 📁 프로젝트 구조

```
flutter_app/
├── lib/
│   ├── main.dart                    # 앱 진입점
│   ├── constants/
│   │   ├── app_constants.dart       # ISO 기준값, FFT 설정
│   │   └── app_theme.dart           # 다크 테마 정의
│   ├── models/
│   │   ├── measurement.dart         # 데이터 모델 정의
│   │   └── measurement.g.dart       # Hive 어댑터 (생성됨)
│   ├── providers/
│   │   └── app_provider.dart        # 전역 상태 관리
│   ├── screens/
│   │   ├── home_screen.dart         # 메인 대시보드
│   │   ├── measurement_screen.dart  # 측정 화면
│   │   ├── equipment_screen.dart    # 설비 관리
│   │   ├── history_screen.dart      # 측정 이력/트렌드
│   │   └── bearing_calculator_screen.dart  # 베어링 계산기
│   ├── services/
│   │   ├── vibration_analyzer_service.dart # 센서 + 신호처리
│   │   ├── storage_service.dart     # Hive DB 관리
│   │   └── export_service.dart      # CSV/PDF 내보내기
│   ├── utils/
│   │   ├── fft_engine.dart          # FFT + 윈도우 + 적분
│   │   └── logger.dart              # 로깅 유틸리티
│   └── widgets/
│       ├── measurement_display.dart # 측정값 표시 위젯
│       └── spectrum_chart.dart      # FFT 스펙트럼 차트
├── android/
│   └── app/src/main/AndroidManifest.xml  # 권한 설정
├── assets/
│   ├── icons/                       # 앱 아이콘
│   ├── images/                      # 이미지 리소스
│   └── data/                        # 정적 데이터
└── pubspec.yaml                     # 의존성 정의
```

---

## 🔐 Android 권한

```xml
<!-- 측정 중 화면 켜짐 유지 -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>

<!-- 측정 위치 사진 첨부 -->
<uses-permission android:name="android.permission.CAMERA"/>

<!-- 햅틱 피드백 -->
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- 고속 센서 접근 (Android 12+) -->
<uses-permission android:name="android.permission.HIGH_SAMPLING_RATE_SENSORS"/>

<!-- 가속도계 필수 -->
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="true"/>
```

---

## 🚀 빌드 및 실행

### 개발 환경 요구사항
- Flutter 3.35.4+
- Dart 3.9.2+
- Android SDK 35+
- Java 17+

### 명령어
```bash
# 의존성 설치
flutter pub get

# 코드 분석
flutter analyze

# 웹 미리보기 (시뮬레이션 데이터)
flutter build web --release
python3 -m http.server 5060 --directory build/web

# Android APK 빌드
flutter build apk --release

# Android App Bundle 빌드 (Play Store 배포용)
flutter build appbundle --release
```

### 빌드 결과물
| 파일 | 경로 | 크기 |
|------|------|------|
| APK | `build/app/outputs/flutter-apk/app-release.apk` | ~17.6MB |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | ~15MB |
| Web | `build/web/` | - |

---

## ⚙️ 핵심 알고리즘

### 1. FFT 엔진 (Cooley-Tukey)
```dart
// 비트 역순 정렬 + 버터플라이 연산
void transform(Float64List real, Float64List imag) {
  // 1. Bit-reversal permutation
  for (int i = 0; i < size; i++) {
    final j = _bitReversalTable[i];
    if (i < j) { /* swap */ }
  }
  
  // 2. Cooley-Tukey iterative FFT
  for (int len = 2; len <= size; len <<= 1) {
    // 버터플라이 연산 with 미리 계산된 twiddle factor
  }
}
```

### 2. 적분 (가속도 → 속도)
```dart
// 사다리꼴 적분 + 고역통과 필터
static Float64List integrateToVelocity(Float64List accel, double sampleRate) {
  // 1. DC 오프셋 제거
  // 2. 사다리꼴 적분: v[i] = v[i-1] + (a[i-1] + a[i]) × dt / 2
  // 3. 2Hz 고역통과 필터 (드리프트 제거)
  // 4. 잔여 DC 오프셋 제거
}
```

### 3. 중력 제거
```dart
// 동적 가속도 추출
final magnitude = sqrt(x² + y² + z²);
final dynamicAccel = abs(magnitude - 9.80665);  // |벡터합 - 중력|
```

---

## 📋 데이터 관리

### 계층 구조
```
설비 (Equipment)
└── 위치 (Location)
    └── 측정 포인트 (Point)
        └── 측정 데이터 (Measurement)
```

### Hive 박스 구성
| Box 이름 | TypeId | 용도 |
|----------|--------|------|
| measurements | 0 | 측정 데이터 |
| equipment | 1 | 설비 정보 |
| locations | 2 | 위치 정보 |
| points | 3 | 측정 포인트 |
| bearings | 4 | 저장된 베어링 |
| settings | 5 | 앱 설정 |

---

## 🧪 검증 상태

### 코드 품질
| 항목 | 상태 | 비고 |
|------|------|------|
| Flutter Analyze | ✅ 0 이슈 | 경고/오류 없음 |
| APK 빌드 | ✅ 성공 | 17.6MB (arm64) |
| Web 빌드 | ✅ 성공 | 시뮬레이션 모드 |

### 기능 검증
| 기능 | 상태 | 비고 |
|------|------|------|
| FFT 분석 | ✅ 검증됨 | 1024/2048/4096 |
| ISO 10816 판정 | ✅ 검증됨 | Class I-IV |
| 베어링 주파수 | ✅ 검증됨 | BPFO/BPFI/BSF/FTF |
| 데이터 저장 | ✅ 검증됨 | Hive 오프라인 |
| CSV/PDF 내보내기 | ✅ 검증됨 | - |

### 권장 추가 검증
| 항목 | 우선순위 | 설명 |
|------|----------|------|
| 실제 설비 비교 측정 | 🔴 높음 | 교정된 진동계와 비교 |
| 센서 캘리브레이션 | 🟡 중간 | 기기별 보정 |
| 고주파 응답 테스트 | 🟡 중간 | 200Hz 달성 확인 |

---

## ⚠️ 제한사항 및 주의사항

### 측정 한계
1. **스마트폰 센서 한계**: 전문 진동계 대비 정밀도/해상도 낮음
2. **샘플링 레이트**: 기기 및 OS에 따라 실제 달성률 다름
3. **고주파 분석**: Nyquist 한계 (fs/2 = ~100Hz)

### 사용 권장
- ✅ 상태 모니터링 및 트렌드 분석
- ✅ 예지보전 스크리닝
- ✅ 교육 및 훈련 목적
- ⚠️ 정밀 진단은 전문 장비 병행 권장

### 알려진 이슈
1. 일부 기기에서 200Hz 샘플링 미달성
2. 이중 적분 시 DC 드리프트 (필터로 보상됨)
3. 웹 버전은 시뮬레이션 데이터 사용

---

## 📄 라이선스

이 소프트웨어는 독점 소프트웨어입니다. 무단 복제, 배포, 수정을 금합니다.

---

## 📞 지원

- **이슈 리포트**: GitHub Issues
- **기술 문의**: 개발팀 연락

---

## 🔄 버전 이력

### v1.0.0 (2025-02-02)
- 초기 릴리스
- FFT 스펙트럼 분석
- ISO 10816-1/3 자동 판정
- 베어링 결함 주파수 계산기
- 설비 > 위치 > 포인트 계층 관리
- CSV/PDF 리포트 내보내기
- 오프라인 완전 지원
- 다크 인더스트리얼 테마

---

---

## 🔧 개발 환경 설정

### 필수 요구사항
```
Flutter SDK: 3.35.4+
Dart SDK: 3.9.2+
Android SDK: 35 (Android 15)
Java: OpenJDK 17+
```

### 처음 시작하기
```bash
# 레포지토리 클론
git clone https://github.com/daper-corp/vibration-analyzer.git
cd vibration-analyzer

# 의존성 설치
flutter pub get

# Hive 어댑터 생성 (이미 생성되어 있음)
# flutter pub run build_runner build --delete-conflicting-outputs

# 분석 실행
flutter analyze

# 웹 미리보기 실행
flutter build web --release
python3 -m http.server 5060 --directory build/web

# Android APK 빌드
flutter build apk --release
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

*이 문서는 자동 생성되었습니다. 최종 수정: 2025-02-02*

**© 2025 daper-corp. All rights reserved.**
