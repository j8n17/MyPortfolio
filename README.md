# MyPortfolio - ChatGPT를 활용한 SwiftUI 포트폴리오 앱 개발 프로젝트

[![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org/)
[![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![Database](https://img.shields.io/badge/Database-CoreData-lightgrey.svg)](https://developer.apple.com/documentation/coredata)
[![API](https://img.shields.io/badge/API-한국투자증권-yellow.svg)](https://apiportal.koreainvestment.com/)
[![AI Model](https://img.shields.io/badge/AI%20Model-ChatGPT%20(o3--mini)-green.svg)](https://openai.com/)

**개발 기간:** 2025.02.03 ~ 2025.02.10

**본 프로젝트는 Swift나 iOS 앱 개발 경험이 없는 상태에서 ChatGPT(o3-mini)를 활용하여 iOS 앱을 개발하는 과정을 기록하고 경험을 공유하는 것을 주목적으로 합니다.** 그 과정에서 SwiftUI와 CoreData를 사용하여 개인 포트폴리오 관리 기능을 구현했습니다. 사용자는 주식, 현금 등의 자산을 등록하고, 목표 비중과 현재 비중을 비교하며 리밸런싱을 관리할 수 있습니다. 백그라운드에서 주기적으로 주식 가격을 업데이트하고, 설정된 임계값을 초과하면 사용자에게 알림을 보냅니다.

---

**목차**
1.  [프로젝트 개요](#1-프로젝트-개요)
2.  [주요 기능](#2-주요-기능)
3.  [파일 구조](#3-파일-구조)
4.  [기술 스택](#4-기술-스택)
5.  [시작하기](#5-시작하기)
6.  [ChatGPT 개발 경험](#6-chatgpt-개발-경험)
7.  [주요 기능 시연](#7-주요-기능-시연)

---

## 1. 프로젝트 개요

**본 프로젝트의 핵심 목표는 ChatGPT와 같은 AI 모델을 활용하여 iOS 앱 개발을 처음부터 진행하는 경험을 쌓고, 그 과정에서 발생하는 문제점과 해결 방안, AI 협업 노하우를 탐색하는 것입니다.**

이를 위해 실제 활용 가능한 앱 테마로 '개인 포트폴리오 관리'를 선정했습니다. 개발된 MyPortfolio 앱은 사용자가 자신의 투자 포트폴리오를 효과적으로 관리할 수 있도록 돕는 기능을 포함합니다. 주식 종목별 목표 비중을 설정하고, 실시간 가격 정보를 바탕으로 현재 자산 배분 상태를 시각적으로 파악할 수 있습니다. 또한, 백그라운드 업데이트와 알림 기능을 통해 포트폴리오 변동성을 지속적으로 모니터링하고 적절한 시점에 리밸런싱을 고려하도록 지원합니다.

---

## 2. 주요 기능

*   **포트폴리오 대시보드 (`PortfolioView`, `AssetStatusView`):**
    *   총 자산, 현금, 주식 평가액 등 전체 자산 현황 표시
    *   보유 주식 목록 및 개별 주식 정보(현재가, 수량, 평가금액, 일일 변동률) 제공
    *   주식별 목표 비중 대비 현재 비중 표시
*   **주식 관리 (`StockAddView`, `StockRowView`, `StockDetailView`):**
    *   새로운 주식 종목 추가 (종목 코드로 검색하여 이름 자동 완성)
    *   보유 주식 정보 수정 (수량, 목표 비중 등) 및 삭제
    *   개별 주식 상세 정보 확인
*   **실시간 가격 업데이트 (`StockPriceFetcher`, `StockRefreshOperation`, `BackgroundTaskManager`):**
    *   한국투자증권 API를 통해 주식의 현재 가격 및 일일 변동률 정보 조회
    *   앱이 백그라운드 상태일 때 주기적으로 가격 정보 자동 업데이트
*   **데이터 관리 (`StockStore`, `PersistenceController`, `CoreData` 모델):**
    *   CoreData를 사용하여 주식 정보, 현금 보유액, 설정값 등 영구 저장
    *   `StockStore`를 통해 데이터 CRUD 작업 관리
*   **설정 (`SettingsView`, `CashEditView`, `APIKeySettingView`):**
    *   보유 현금 금액 입력 및 수정
    *   한국투자증권 API 사용을 위한 Key 및 Secret 설정
    *   리밸런싱 알림 발생 기준 임계값(변동률 %) 설정
*   **리밸런싱 알림 (`NotificationManager`):**
    *   백그라운드 업데이트 시, 개별 주식의 목표 비중 대비 현재 비중 차이가 설정된 임계값을 초과하면 사용자에게 알림 발송

---

## 3. 파일 구조

```
MyPortfolio/
├── MyPortfolioApp.swift           # 앱 진입점 및 라이프사이클 관리
├── Info.plist
├── Assets.xcassets/               # 앱 아이콘, 이미지 등 리소스
├── Preview Content/               # SwiftUI 프리뷰용 데이터
│
├── Views/                         # SwiftUI 뷰 정의
│   ├── ContentView.swift          # 메인 컨텐츠 뷰 (탭 뷰 등)
│   ├── PortfolioView.swift        # 포트폴리오 목록 및 요약 뷰
│   ├── AssetStatusView.swift      # 자산 현황 상세 뷰
│   ├── StockRowView.swift         # 주식 목록의 각 행 뷰
│   ├── StockAddView.swift         # 주식 추가/편집 뷰
│   ├── StockDetailView.swift      # 주식 상세 정보 뷰
│   ├── SettingsView.swift         # 설정 메인 뷰
│   ├── CashEditView.swift         # 현금 수정 뷰
│   └── APIKeySettingView.swift    # API 키 설정 뷰
│
├── Utilities/                     # 유틸리티 및 비즈니스 로직
│   ├── PersistenceController.swift # CoreData 스택 설정
│   ├── MyPortfolioModel.xcdatamodeld/ # CoreData 데이터 모델
│   ├── Stock.swift                # 주식 데이터 모델 (Struct)
│   ├── StockStore.swift           # CoreData와 상호작용하는 데이터 관리 클래스
│   ├── StockPriceFetcher.swift    # 주가 정보 API 호출 로직
│   ├── Key.swift                  # API 키 관리 (gitignore 필요)
│   ├── FormatterHelper.swift      # 숫자, 날짜 등 포맷팅 헬퍼
│   ├── BackgroundTaskManager.swift # 백그라운드 작업 관리
│   ├── StockRefreshOperation.swift # 백그라운드 주가 업데이트 작업
│   ├── NotificationManager.swift  # 사용자 알림 관리
│   └── StockEditData.swift        # 주식 편집 시 사용하는 임시 데이터 구조체
│
├── MyPortfolio.xcodeproj/         # Xcode 프로젝트 파일
├── StockEntity+CoreDataClass.swift # CoreData ManagedObject 클래스 (자동 생성)
├── StockEntity+CoreDataProperties.swift # CoreData ManagedObject 속성 (자동 생성)
├── SettingsEntity+CoreDataClass.swift # CoreData ManagedObject 클래스 (자동 생성)
└── SettingsEntity+CoreDataProperties.swift # CoreData ManagedObject 속성 (자동 생성)
```

*참고: `merged_swift_files.txt`와 `merge.py`는 ChatGPT에게 전체 코드를 전달하기 위해 생성된 파일입니다.*

---

## 4. 기술 스택

*   **UI:** SwiftUI
*   **데이터 관리:** CoreData
*   **비동기 처리:** Combine, async/await
*   **네트워킹:** URLSession (StockPriceFetcher 내에서 사용)
*   **백그라운드 처리:** BackgroundTasks Framework
*   **알림:** UserNotifications Framework
*   **API:** 한국투자증권 REST API (국내주식시세)
*   **개발 환경:** Xcode

---

## 5. 시작하기

1.  **Repository 클론**
2.  **빌드 및 실행:** Xcode 시뮬레이터 또는 실제 기기에 앱을 빌드하고 실행합니다.
3.  **API 키 설정:**
    *   한국투자증권 API 사용을 위한 App Key와 App Secret을 발급받습니다.
    *   앱 실행 후 설정 화면에서 입력합니다.

---

## 7. 주요 기능 시연

| 새로고침 (주식 정보 업데이트) | 주식 추가 | 리밸런싱 |
| ------------------------ | -------- | -------- |
| ![demo1](https://github.com/j8n17/MyPortfolio/blob/main/demo/MyPortfolio_refresh.gif) | ![demo2](https://github.com/j8n17/MyPortfolio/blob/main/demo/MyPortfolio_add.gif) | ![demo3](https://github.com/j8n17/MyPortfolio/blob/main/demo/MyPortfolio_rebalancing.gif) |

---

## 6. ChatGPT 개발 경험

본 프로젝트는 Swift나 iOS 앱 개발 경험이 없는 상태에서 ChatGPT(o3-mini)를 활용하여 개발되었습니다. 개발 과정과 느낀 점은 다음과 같습니다.

### 개발 순서

1.  **기본 앱 실행:** "Hello world"를 출력하는 가장 기본적인 앱을 생성하고 실행합니다.
2.  **기능 및 UI 구현:**
    *   **반복적 개발:** ChatGPT에게 필요한 기능을 요청하고, UI 변경사항을 지시하며, 발생하는 문제를 해결하는 과정을 반복합니다.
    *   **코드 리뷰:** 개발 중 다른 ChatGPT 세션을 활용하여 작성된 코드에 대한 리뷰를 요청하고 개선합니다.
3.  **오류 발생 가능성이 높은 신규 기능 추가:** API 연동, 데이터 저장 방식 변경 등 기존 코드와 다른 context를 가지는 새로운 기능을 추가합니다. 이 단계에서는 오류 발생 가능성이 높으므로, **별도의 프로젝트에서 해당 기능 구현을 먼저 연습한 후 본 프로젝트에 통합**하는 방식을 사용했습니다.
4.  **코드 분리:** 개발이 진행됨에 따라 복잡해지는 코드를 UI 관련 코드와 기능(로직) 관련 코드로 분리하여 가독성과 유지보수성을 높입니다.

### ChatGPT 활용 소감

*   **장점:**
    *   `o3-mini` 모델은 긴 context를 잘 유지하여 여러 차례 요청을 주고받아도 이전 내용을 기억하고 일관성 있는 답변을 제공했습니다. 덕분에 복잡한 기능 구현도 비교적 원활하게 진행할 수 있었습니다.
*   **단점:**
    *   **코드 전달의 어려움:** 코드가 길어지고 파일이 많아지면서 생성된 코드를 에디터로 옮기는 데 어려움이 있었습니다.
    *   **코드 중복 위험:** 코드를 수동으로 옮기는 과정에서 실수로 다른 파일에 중복된 코드가 삽입될 위험이 있습니다.
    *   **수동 변경 후 동기화 필요:** 개발자가 직접 코드를 수정한 경우, 변경 사항을 ChatGPT에게 다시 전달(전체 코드 제공 등)해야만 AI가 최신 상태를 인지하고 정확한 다음 작업을 수행할 수 있습니다.
    *   **최신 버전 미반영 가능성:** 최신 Swift 버전이나 라이브러리 변경사항을 반영하지 못하는 코드를 생성할 수 있습니다.
    *   **코드 복잡성 증가:** 초기 개발 단계에서 명확한 구조 없이 기능 추가에만 집중하면 UI 코드와 로직 코드가 뒤섞여 코드의 복잡성이 증가할 수 있습니다.

### AI 코딩 시 유의사항

*   **전체적인 맥락 제공:** AI에게 세부적인 기능 구현만 요청하기보다, 프로젝트의 전체적인 목표와 구조, 현재 상태 등 충분한 맥락(context)을 함께 제공해야 원하는 방향으로 코드가 작성될 가능성이 높습니다.
*   **초기 방향 설정의 중요성:** 개발 초기에 잘못된 방향으로 코드를 작성하기 시작하면, 나중에 이를 수정하는 데 훨씬 더 많은 시간과 노력이 소요될 수 있습니다. 따라서 초반 설계와 AI와의 명확한 소통이 중요합니다.