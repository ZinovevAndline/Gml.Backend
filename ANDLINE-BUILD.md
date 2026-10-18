# Сборка ANDLINE Backend

`src/Gml.Web.Api` и `src/gml-core` закреплены gitlink-коммитами наших форков.
API, Core, DTO и EndpointSDK компилируются вместе на .NET 10. Подмена DLL
в готовом upstream-образе не требуется.

```sh
git submodule update --init -- src/gml-core src/Gml.Web.Api
docker build --build-arg BUILD_COMMIT="$(git rev-parse HEAD)" -t andline-gml-api .
```

Для чтения приватного Core нужен доступ существующего токена к `Gml.Core`.
Не передавайте токен через Docker ARG или URL, сохранённый в репозитории.
Pterodactyl получает исходники через BuildKit secret `GML_GITHUB_TOKEN`.
Его workflow разрешает SHA Backend до сборки, а Backend закрепляет SHA API/Core.

После изменения API/Core обновите соответствующий gitlink в Backend,
затем запустите сборку `gml-pterodactyl`. Простая повторная сборка Backend
не подтягивает незакреплённые изменения зависимостей.

Отдельные игровые сессии этим изменением не включаются. До внедрения
полного протокола остаётся существующий общий доступ GML на аккаунт.
Откат: использовать предыдущий неизменяемый тег образа Pterodactyl.
