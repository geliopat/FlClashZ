<div align="center">

<img src="assets/images/icon.png" alt="FlClashZ" width="100">

# FlClashZ

**Mihomo + Zapret для Windows**

[![Windows x64](https://img.shields.io/badge/Windows-x64-0078D4?style=flat-square&logo=windows)](https://github.com/geliopat/FlClashZ/releases/latest)
[![Release](https://img.shields.io/github/v/release/geliopat/FlClashZ?style=flat-square)](https://github.com/geliopat/FlClashZ/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/geliopat/FlClashZ/total?style=flat-square)](https://github.com/geliopat/FlClashZ/releases)
[![License](https://img.shields.io/github/license/geliopat/FlClashZ?style=flat-square)](LICENSE)

[![Скачать установщик](https://img.shields.io/badge/%D0%A1%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C_%D1%83%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D1%89%D0%B8%D0%BA-EXE-0078D4?style=for-the-badge)](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64-setup.exe) [![Скачать portable](https://img.shields.io/badge/%D0%A1%D0%BA%D0%B0%D1%87%D0%B0%D1%82%D1%8C_portable-ZIP-475569?style=for-the-badge)](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64.zip)

[![v1.0.1 validated](https://img.shields.io/badge/v1.0.1-Windows%20validated-brightgreen?style=flat-square)](https://github.com/geliopat/FlClashZ/actions/runs/45790180974)

[Документация заголовков](docs/headers.md) · [Управление Zapret](docs/flclashz-zapret-headers.md) · [Синхронизация](docs/upstream-sync.md)

**Русский** · [English](README_EN.md) · [中文](README_ZH.md)

</div>

FlClashZ — самостоятельный форк [FlClashX](https://github.com/pluralplay/FlClashX), объединяющий прокси-клиент на базе Mihomo и управление Zapret2/Flowseal в одном приложении. Проект ориентирован на Windows x64 и совместимость с Remnawave. Не является официальным клиентом перечисленных проектов.

[Скачать](#скачать) · [Возможности](#возможности) · [Remnawave](#для-провайдеров) · [Обновления](#обновления) · [Сборка](#сборка-из-исходников)

## Скачать

Стабильная версия [1.0.1](https://github.com/geliopat/FlClashZ/releases/tag/v1.0.1) опубликована: установщик и portable прошли проверку сборки, запуска, установки, обновления при работающем приложении и изоляции от FlClashX.

| Вариант | Формат | Ссылка |
| --- | --- | --- |
| Установщик Windows x64 | EXE | [FlClashZ-windows-amd64-setup.exe](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64-setup.exe) |
| Портативная версия Windows x64 | ZIP | [FlClashZ-windows-amd64.zip](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64.zip) |

Для обычного использования и встроенного обновления выбирайте установщик. Portable распакуйте в отдельный каталог и запустите `FlClashZ.exe`. Встроенная установка обновления предусмотрена для установленной версии; портативную версию можно обновить вручную.

Целевая платформа — Windows 10/11 x64. Другие платформы унаследованы в исходном дереве, но не являются целью текущих релизов FlClashZ.

## Возможности

| Mihomo | Zapret |
| --- | --- |
| Профили из подписок и файлов, редактор YAML | Встроенное управление Zapret2 и Flowseal |
| TUN, системный прокси, правила маршрутизации | Ручной запуск, остановка и перезапуск |
| Группы прокси, DNS, соединения и логи | Готовые Lua/BAT-стратегии и импорт |
| Автоматические проверки задержек узлов и групп | Автоподбор, история проверок и резервная стратегия |
| Переопределения и скрипты | Диагностика доступности и обновление списков |

### Совместная работа

Mihomo управляет прокси-маршрутизацией и DNS. Zapret применяется в соответствии с выбранным режимом и возможностями стратегии. Режимы STRICT SPLIT и FULL BYPASS, запуск вместе с Mihomo, автоподбор и восстановление настраиваются в приложении или через подписку.

Автоматические проверки задержек используют HTTP(S) URL-тест, а не ICMP. Для балансировщиков отображается результат проверки их участников через ядро. Интервалы активных и остальных подключений задаются в настройках.

### Интерфейс Windows

- Настраиваемый дашборд, карточки, темы, стекло и акриловое меню трея.
- Отдельное управление Mihomo и Zapret; состояние и выбранная стратегия на дашборде.
- Собственные каталоги данных, служба Helper и протоколы импорта, отдельные от FlClashX.
- Подтверждение дисклеймера хранится в каталоге настроек; обновление не требует повторного подтверждения.

## Для провайдеров

Поддерживаются стандартные заголовки подписки Remnawave, HWID и параметры YAML `serverDescription`, `server-description`, `groupDescription` (если панель действительно передаёт их клиенту).

Собственные HTTP-заголовки имеют префикс `flclashz-`. Унаследованные `flclashx-*` читаются для совместимости; новые имена имеют приоритет. Пример:

```http
flclashz-view: app.theme:dark;app.glass:standard
flclashz-widgets: profiles,networkSpeed,networkTakeover,zapret
flclashz-zapret: autostart,mode:fullbypass,autofallback,autotune,tunemode:fast,tuneonfail
```

| Документация | Содержание |
| --- | --- |
| [HTTP-заголовки](docs/headers.md) | Справочник заголовков, ключей и значений |
| [Управление Zapret](docs/flclashz-zapret-headers.md) | Режимы, автоподбор и восстановление |

Для импорта установленным клиентом:

```text
flclashz://install-config?url=<URL-кодированная ссылка на подписку>
```

## Обновления

Стабильные релизы имеют теги вида `v1.0.1`. Проверка обновлений по умолчанию использует подписанный [manifest.json](https://github.com/geliopat/FlClashZ/releases/latest/download/manifest.json) из Latest. Манифест содержит версию, ссылки на пакеты, SHA-256 и цифровую подпись Ed25519. Для конкретной версии используется путь `releases/download/v<версия>/manifest.json`.

Установщик завершает работающий FlClashZ перед заменой файлов, сохраняя настройки. Релизная сборка проверяет запуск portable, установку, обновление при работающем приложении и изоляцию FlClashX. Публикация предусмотрена после прохождения проверок и подписания манифеста.

> [!IMPORTANT]
> При переходе с версии 1.0.0 установите 1.0.1 или более новую версию вручную поверх существующей установки: в старой сборке отсутствовал публичный ключ проверки манифеста. Начиная с 1.0.1 ключ встроен. Автоматическое обновление приложения не связано с синхронизацией исходных репозиториев.

## Компоненты

| Компонент | Версия в 1.0.1 | Источник |
| --- | --- | --- |
| FlClashX (основа) | `0.5.8` | [pluralplay/FlClashX](https://github.com/pluralplay/FlClashX) |
| Mihomo (в составе FlClashX) | `v1.19.34` | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) |
| Zapret2 | `v1.0.8` | [bol-van/zapret2](https://github.com/bol-van/zapret2) |
| Flowseal | `1.10.4` | [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) |
| Стратегии Lua/BAT | `8dd17fcbcca4` | [geliopat/zapret2-gui](https://github.com/geliopat/zapret2-gui/tree/8dd17fcbcca405a50f497a6e2346ca263901d775) |

## Разработка и синхронизация

**Синхронизация только вручную.** `main` — чистое зеркало FlClashX; `fix/zapret2-stability` — основная ветка FlClashZ. Mihomo отдельно не обновляется: изменения ядра, патчи и зависимости приходят вместе с FlClashX.

[Ручная синхронизация](https://github.com/geliopat/FlClashZ/actions/workflows/flclashz-upstream-sync.yml) подготавливает отдельный кандидат `sync/flclashz-*`, проверяет закреплённые версии Zapret2 и Flowseal, переносит стратегии из нашего форка с трёхсторонним слиянием и сохраняет отчёт о конфликтах. При отсутствии изменений сборка пропускается. Слияние и выпуск релиза выполняются только по отдельному решению разработчика.

[Документация синхронизации](docs/upstream-sync.md) · [Проверка Windows](https://github.com/geliopat/FlClashZ/actions/workflows/zapret-windows-validation.yml) · [Выпуск релиза](https://github.com/geliopat/FlClashZ/actions/workflows/flclashz-release.yml)

## Сборка из исходников

Для Windows нужны Flutter 3.47.6, Go 1.27.1, Rust (rustup), Visual Studio с Desktop development with C++ и Inno Setup 6.

```powershell
git clone --branch fix/zapret2-stability https://github.com/geliopat/FlClashZ.git
cd FlClashZ
flutter pub get
./scripts/setup_zapret.ps1
dart setup.dart windows --env stable --arch amd64 --targets zip,exe -v
```

Результат находится в `dist/`. Для проверки подписанных обновлений локальная сборка должна получить доверенный публичный ключ через `FLCLASHZ_UPDATE_PUBLIC_KEY`; приватный ключ хранится в GitHub Actions secrets, не в исходниках.

[Workflow Windows](https://github.com/geliopat/FlClashZ/actions/workflows/zapret-windows-validation.yml) · [Релизный workflow](https://github.com/geliopat/FlClashZ/actions/workflows/flclashz-release.yml)

## Исходные проекты и лицензия

FlClashZ сохраняет авторство и лицензию исходных проектов. Разработка форка: [geliopat](https://github.com/geliopat).

- [FlClashX](https://github.com/pluralplay/FlClashX) — upstream client, pluralplay.
- [FlClash](https://github.com/chen08209/FlClash) — original client, chen08209.
- [Mihomo](https://github.com/MetaCubeX/mihomo)
- [Zapret2](https://github.com/bol-van/zapret2)
- [Flowseal](https://github.com/Flowseal/zapret-discord-youtube)
- [zapret2-gui](https://github.com/mqclass/zapret2-gui) / [strategy fork](https://github.com/geliopat/zapret2-gui)

Лицензия: [GPL-3.0](LICENSE). За условия распространения включённых сторонних компонентов отвечают их собственные лицензии.

[Сообщить об ошибке](https://github.com/geliopat/FlClashZ/issues) · [История изменений](https://github.com/geliopat/FlClashZ/releases)

Если проект полезен, поставьте ⭐ репозиторию.
