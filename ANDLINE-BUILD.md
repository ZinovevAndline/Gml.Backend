# Сборка ANDLINE GML Backend

`src/Gml.Web.Api` и `src/gml-core` — **git submodule** с точными коммитами
наших форков. Приложение, модели и EndpointSDK компилируются из одних исходников
на .NET 10. Нельзя подменять API DLL в upstream-образе или собирать
`Gml.Web.Api` отдельно со старым NuGet `Gml.Core`.

## Согласованные исходники для ANDLINE MainMenu

- API: `ZinovevAndline/Gml.Web.Api` @ `9d649a251f62e2a7e5180fbc5f21167819a734e3`
- Core: `ZinovevAndline/Gml.Core` @ `c2fb62479abdbe653da7cc7d7a9338a5a18fc76b`
- Изменение API: [PR #3](https://github.com/ZinovevAndline/Gml.Web.Api/pull/3).
- Сайт: [andline PR #153](https://github.com/ZinovevAndline/andline/pull/153).
- Minecraft-клиент: [AndlineClient PR #1](https://github.com/ZinovevAndline/AndlineClient/pull/1).
- Лаунчер: [Gml.Launcher PR #7](https://github.com/ZinovevAndline/Gml.Launcher/pull/7).

Поднятие **обоих** gitlink необходимо: обновлённая версия API с функциями
доставки файлов использует типы Core, добавленные после прежнего закреплённого коммита.
Кроме того, `AndlineLauncherSessionHandler` проверяет точный SHA-256 хеш
активной и неотозванной игровой GML-сессии. Сайт получает только её ID;
знания UUID или авторизации в браузере недостаточно для выдачи токена MainMenu.

## Воспроизводимая сборка

Для чтения приватного `Gml.Core` Git должен иметь доступ к репозиторию.
Используйте уже настроенный секрет или Git credential helper. Не сохраняйте
персональный токен в `.gitmodules`, Dockerfile, командах CI или образе.

```bash
git submodule update --init -- src/gml-core src/Gml.Web.Api
git submodule status -- src/gml-core src/Gml.Web.Api
dotnet test src/Gml.Web.Api/tests/Gml.WebApi.Tests/Gml.WebApi.Tests.csproj \
  -c Release -p:GmlCoreRoot="$(pwd)/src/gml-core"
docker build --build-arg BUILD_COMMIT="$(git rev-parse HEAD)" \
  -t andline-gml-api .
```

При локальной проверке не запускайте `dotnet test` из каталога одного API
без `GmlCoreRoot`: его старый NuGet-пакет не содержит нужных моделей сессий.
Production Dockerfile уже устанавливает `GmlCoreRoot=/src/src/gml-core`
и собирает именно закреплённые gitlink.

## Конфигурация и порядок развёртывания

1. Слить и проверить соответствующие PR API и Laravel, затем PR Backend.
2. Пересобрать образ через действующий `gml-pterodactyl` pipeline с новым
   **SHA Backend**; старый тег не подтянет новые gitlink автоматически.
3. В GML Backend задать `ANDLINE_GML_SESSION_SECRET` (не менее 32 символов).
   В Laravel `services.andline_gml_session_secret` должен содержать **тот же**
   секрет. Не путать его с `ANDLINE_GML_SHARED_SECRET`.
   В обычном Docker Compose ключ берётся из `.env`, а конфигурации
   `docker-compose*.yml` передают его в API-контейнер. Значение нельзя
   коммитить; пустой ключ означает отказ в авторизации MainMenu.
4. В админке сайта проверить `gml_session_control_url`: HTTPS URL корня
   GML API без суффикса пути. Доступ Laravel → GML API должен работать.
   Если используется Compose без Pterodactyl, укажите вместо upstream
   `ghcr.io/gml-launcher/gml.web.api` собственный опубликованный образ:
   образ по умолчанию из старого Compose **не** содержит наших изменений.
   Для локальной Compose-сборки `docker-compose.yml` и
   `docker-compose-external-debug.yml` теперь используют корневой Dockerfile
   со связанными исходниками API/Core.
5. Только после проверки backend и сайта выпускать новый Gml.Launcher и
   AndlineClient. Внутри игры используется отдельный JWT только для чтения,
   без сайта, платежей и прав администратора.

### Обязательная проверка на тестовом окружении

- Пользователь с действующей GML-сессией открывает меню: ник и `users.souls`
  приходят с Laravel, последующее изменение баланса — через Socket.IO.
- С неверным, просроченным или отозванным GML-токеном обмен возвращает отказ.
  Отзыв устройства отключает приватный баланс; публичные сведения о сервере
  остаются доступными.
- Токен MainMenu не авторизует покупку, изменение аккаунта или admin Socket.IO.
- При недоступности GML Backend приватные данные недоступны (fail closed);
  секреты и токены не попадают в логи.

Эта документация описывает ожидаемые сценарии для smoke-тестов, **не**
подтверждает успешную проверку реального игрового клиента или production.

## Откат

Верните предшествующий неизменяемый образ Backend / gitlink-коммиты,
затем восстановите совместимую версию Laravel и клиента. Данные пользователей
и миграции БД этот шаг не изменяет. До восстановления согласованных версий
доступ к приватному меню должен оставаться закрыт.
