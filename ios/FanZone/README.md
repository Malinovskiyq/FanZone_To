# FanZone — iOS App

iOS-приложение для болельщиков ХК «Сибирь» — система бронирования мест в фан-секторе.

---

## Требования

- **Xcode 15.0+**
- **iOS 16.0+** (минимальный deployment target)
- **macOS Ventura+** для разработки
- Запущенный [FanZone Backend](../backend/README.md)

---

## Создание Xcode проекта

1. Откройте **Xcode → File → New → Project**
2. Выберите **iOS → App**
3. Настройки:
   - **Product Name**: `FanZone`
   - **Organization**: ваша организация
   - **Bundle ID**: `com.yourorg.fanzone`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployments**: iOS 16.0
4. Сохраните проект в папку `E:\prilox\ios\FanZone\`
5. **Удалите** стандартные файлы `ContentView.swift` и `Assets.xcassets` (они будут заменены)

---

## Добавление файлов в проект

После создания проекта добавьте все файлы из папки `FanZone/`:

1. В **Project Navigator** (левая панель) кликните правой кнопкой на папку `FanZone`
2. Выберите **"Add Files to FanZone..."**
3. Выберите все подпапки: `App`, `Core`, `Design`, `Features`, `Models`
4. Убедитесь, что выбрано **"Create groups"** и **"Add to targets: FanZone"**

---

## Настройка Info.plist

Добавьте следующие ключи в `Info.plist`:

```xml
<!-- Разрешения для камеры (QR-сканер) -->
<key>NSCameraUsageDescription</key>
<string>Для сканирования QR-кодов билетов</string>

<!-- Разрешения для фото -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Для загрузки фотографии профиля</string>

<!-- API Base URL (опционально, можно менять здесь) -->
<key>API_BASE_URL</key>
<string>http://localhost:3000/api/v1</string>

<key>UPLOADS_BASE_URL</key>
<string>http://localhost:3000</string>
```

---

## Настройка Capabilities

В **Xcode → Target → Signing & Capabilities** добавьте:
- **Push Notifications** (для APNs)
- **Background Modes** → Remote notifications

---

## Конфигурация API URL

Базовый URL задаётся в [AppConfiguration.swift](FanZone/AppConfiguration.swift):

```swift
// Через Info.plist (рекомендуется):
// API_BASE_URL = http://your-server.com/api/v1

// Через переменные окружения при запуске в симуляторе:
// Edit Scheme → Run → Environment Variables
// API_BASE_URL = http://localhost:3000/api/v1
```

Для **тестирования на реальном устройстве** (не в симуляторе):
- Замените `localhost` на локальный IP вашего Mac (например, `192.168.1.100`)
- Или задеплойте backend на сервер

---

## Запуск

1. Убедитесь, что backend запущен (`npm run dev` в папке `backend/`)
2. Выберите симулятор (iPhone 15 Pro, iOS 17+)
3. Нажмите ▶️ **Run** (Cmd+R)

---

## Архитектура приложения

### Структура файлов

```
FanZone/
├── App/
│   └── RootView.swift          # Корневой вид, роутинг по ролям
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift     # HTTP клиент (async/await, token refresh)
│   │   └── APIEndpoint.swift   # 40+ API эндпоинтов
│   ├── Auth/
│   │   ├── AuthManager.swift   # Менеджер аутентификации (@MainActor)
│   │   └── KeychainManager.swift # Безопасное хранение токенов
│   └── Extensions/
│       ├── Date+Extensions.swift  # Форматирование дат по-русски
│       └── View+Extensions.swift  # CardStyle, ButtonStyles
├── Models/
│   ├── User.swift              # User, UserProfile, SocialLink
│   ├── Match.swift             # Match, Team, Arena, FanSector
│   ├── Booking.swift           # Booking, BookingStatus, AttendanceRecord
│   ├── Stats.swift             # UserStats, AdminStats
│   └── Notification.swift      # AppNotification
├── Design/
│   ├── AppTheme.swift          # Цвета, градиенты, радиусы
│   └── Components/
│       ├── FZButton.swift      # Primary/Secondary/Destructive кнопки
│       ├── FZCard.swift        # FZCard, StatCard, FZTextField, EmptyState
│       ├── StatusBadge.swift   # Бейджи статусов
│       ├── MatchCard.swift     # Карточка матча
│       └── UserAvatarView.swift # Аватар с fallback-инициалами
└── Features/
    ├── Auth/                   # Login, Register, ForgotPassword
    ├── Home/                   # Главный экран (героическая карточка матча)
    ├── Matches/                # Список матчей, детали, форма бронирования
    ├── Bookings/               # Мои брони, детали, электронный билет + QR
    ├── Profile/                # Профиль, редактирование, соцсети, история
    ├── BookingManager/         # Панель ответственного: заявки, участники, сканер
    └── Admin/                  # Управление матчами, пользователями, статистика
```

### Навигация по ролям

```
USER:
└── TabView: Главная | Матчи | Брони | Профиль

BOOKING_MANAGER:
└── TabView: Заявки | Матчи | Участники | Сканер | Профиль

ADMIN:
└── TabView: Главная | Матчи | Заявки | Пользователи | Статистика
```

---

## Дизайн-система

| Цвет | Hex | Применение |
|---|---|---|
| `brandPrimary` | `#0066CC` | Кнопки, акцент ХК Сибирь |
| `brandSecondary` | `#FFD700` | Золотой акцент (VS, цифры) |
| `background` | `#0D0D0D` | Основной фон |
| `surface` | `#1A1A2E` | Карточки |
| `success` | `#34C759` | Подтверждено, посетил |
| `warning` | `#FF9500` | На рассмотрении |
| `error` | `#FF3B30` | Отклонено, ошибки |

---

## Ключевые экраны

| Экран | Роль | Описание |
|---|---|---|
| LoginView | Все | Красивый тёмный экран входа |
| HomeView | USER/ADMIN | Героическая карточка ближайшего матча |
| MatchDetailView | Все | Детали матча + кнопка бронирования |
| BookingFormView | USER | Подтверждение заявки |
| TicketView | USER | Электронный билет с QR-кодом |
| ProfileView | Все | Статистика + соцсети + история |
| BookingRequestsView | MANAGER/ADMIN | Подтверждение/отклонение заявок |
| MatchParticipantsView | MANAGER | Отметка посещаемости |
| QRScannerScreenView | MANAGER | Сканирование QR-кодов |
| AdminMatchesView | ADMIN | Управление матчами |
| AdminUsersView | ADMIN | Управление пользователями |
| AdminStatsView | ADMIN | Статистика системы |

---

## Безопасность

- **Keychain** — токены никогда не хранятся в UserDefaults
- **Автообновление токена** — при 401 APIClient автоматически обновляет access token
- **QR-код** — содержит только случайный UUID, не персональные данные
- **RBAC** — все права проверяются на сервере, не только в UI

---

## Тестовые аккаунты (после db:seed)

| Роль | Email | Пароль |
|---|---|---|
| Болельщик | fan@fanzone.ru | Fan123! |
| Ответственный | manager@fanzone.ru | Manager123! |
| Администратор | admin@fanzone.ru | Admin123! |
