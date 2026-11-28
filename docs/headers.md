# HTTP-заголовки подписки FlClashZ

Справочник для Remnawave и других панелей. Заголовки передаются в HTTP-ответе при скачивании подписки, не внутри YAML. Имена регистронезависимы. При повторении одноимённого HTTP-заголовка клиент хранит первое значение.

## Совместимость

Основной префикс — `flclashz-`. Все 13 унаследованных заголовков принимаются также с `flclashx-`. При наличии обоих имён новый имеет приоритет целиком, включая пустое или ошибочное значение; списки не объединяются. Старые сохранённые профили читаются без миграции. `flclashz-zapret` не имеет старого аналога. Стандартные заголовки, YAML-ключи и протоколы ссылок этим изменением не переименовываются.

## Все заголовки приложения

| Заголовок | Формат |
|---|---|
| `flclashz-view` | `ключ:значение;ключ:значение`, см. ниже |
| `flclashz-widgets` | Имена карточек через запятую в нужном порядке |
| `flclashz-background` | URL изображения, опционально `,видимость` (1–100) |
| `flclashz-settings` | Флаги переключателей через запятую |
| `flclashz-special` | Особые флаги через запятую |
| `flclashz-update` | HTTPS URL манифеста стабильного обновления приложения |
| `flclashz-update-pre` | HTTPS URL манифеста предварительного обновления |
| `flclashz-update-core` | HTTPS URL подписанного манифеста независимого ядра Windows |
| `flclashz-servicename` | Название сервиса, текст или Base64 |
| `flclashz-servicelogo` | URL логотипа, текст или Base64 |
| `flclashz-serverinfo` | Имя серверной группы, текст или Base64 |
| `flclashz-buyplan` | URL продления, необязательно `,число дней` |
| `flclashz-buytraffic` | URL покупки трафика, необязательно `,процент остатка` |
| `flclashz-newdomain` | До 5 резервных хостов через запятую; хост, хост:порт или origin |
| `flclashz-zapret` | Четыре флага и два параметра через запятую (Windows) |

## flclashz-view

| Ключ | Допустимые значения |
|---|---|
| `proxies.type` | `list`, `tab` |
| `proxies.sort` | `none`, `delay`, `name` |
| `proxies.layout` | `loose`, `standard`, `tight` |
| `proxies.icon` | `filled`, `plain`, `hidden` |
| `proxies.card` | `loose`, `standard`, `compact`, `oneline` |
| `proxies.hidetimeout` | `true`, `false` |
| `app.theme` | `auto`, `light`, `dark` |
| `app.navbar` | `floating`, `docked` |
| `app.tabs` | `slide`, `fade` |
| `app.glass` | `none`, `standard`, `ultra` |
| `app.color` | HEX `RRGGBB` или `AARRGGBB`, необязательный # |
| `app.style` | `vivid`, `tinted`, `soft`, `monochrome` |
| `app.black` | `true`, `false` |

Для логических ключей также принимаются yes/no и 1/0. Неизвестные значения игнорируются. Неуказанные ключи не навязывают настройку.

```http
flclashz-view: proxies.type:tab;proxies.sort:delay;app.theme:dark;app.glass:standard
```

## flclashz-widgets

Имена карточек (регистронезависимы, неизвестные и повторы игнорируются):

| Имя | Карточка |
|---|---|
| currentOutbound | Текущий исходящий прокси |
| announcement | Объявление |
| networkSpeed | Скорость сети |
| outboundMode | Режим маршрутизации |
| vpnButton | Кнопка VPN (Android) |
| networkTakeover | Перехват сети (десктоп) |
| serviceStatus | Статус сервиса |
| profiles | Профили |
| proxyGroups | Группы прокси |
| connectionStats | Статистика соединений |
| intranetIp | Локальный IP |
| memoryInfo | Память |
| zapret | Zapret (Windows) |

```http
flclashz-widgets: profiles,networkSpeed,networkTakeover,zapret
```

Флаг `denywidgets` в special закрепляет набор карточек, когда он задан.

## flclashz-settings

В непустом заголовке присутствующий флаг включает соответствующий переключатель, отсутствующий выключает (с учётом пользовательского владения настройкой). Без заголовка либо при пустом значении личные настройки не навязываются панелью.

| Флаг | Действие |
|---|---|
| minimize | Сворачивать вместо выхода |
| autorun | Автозапуск приложения с системой |
| shadowstart | Тихий запуск |
| autostart | Автоматический запуск VPN |
| autoupdate | Автоматическая проверка обновления приложения |
| openlogs | Открывать логи |
| closeconnections | Закрывать соединения при смене прокси |

```http
flclashz-settings: minimize,autorun,autostart,autoupdate
```

## flclashz-special

| Флаг | Действие |
|---|---|
| androidsecure | Защита экрана Android |
| denywidgets | Запрет изменения набора карточек |
| noglobal | Скрыть глобальный режим |
| onlytun | Только TUN, системный прокси недоступен |
| hideip | Скрыть IP |
| simple | Упрощённый интерфейс |
| novibrate | Отключить вибрацию |
| onegroup | Показывать прокси только серверной группы без заголовков групп и тестов задержки |
| providermode | Оформить дашборд в стиле провайдера |
| nologo | Скрыть логотип в режиме провайдера |
| noservice | Скрыть строку сервиса в режиме провайдера |

```http
flclashz-special: providermode,denywidgets,noglobal
```

## flclashz-zapret (Windows)

```http
flclashz-zapret: autostart,mode:fullbypass,autofallback,autotune,tunemode:fast,tuneonfail
```

| Ключ | Значения / действие |
|---|---|
| autostart | Флаг, запуск с Mihomo |
| autofallback | Флаг, смена на подтверждённую стратегию |
| autotune | Флаг, первоначальный подбор при отсутствии подтверждённой стратегии и неудачных проверках |
| tuneonfail | Флаг, повторный подбор при сбое |
| mode | `mode:strictsplit`, `mode:fullbypass` |
| tunemode | `tunemode:veryfast`, `tunemode:fast`, `tunemode:full` |

Наличие флага означает включение, отсутствие — выключение, если сам заголовок присутствует. Без заголовка сохраняются личные настройки. Без mode используется личный режим, без tunemode — fast. Полное описание, условия проверок, ограничения и примеры: [flclashz-zapret-headers.md](flclashz-zapret-headers.md).

## Остальные заголовки: примеры

```http
flclashz-background: https://example.com/bg.png,35
flclashz-servicename: My VPN
flclashz-servicelogo: https://example.com/logo.svg
flclashz-serverinfo: Auto
flclashz-buyplan: https://example.com/renew,3
flclashz-buytraffic: https://example.com/traffic,10
flclashz-newdomain: backup.example.com,https://backup2.example.com:8443
flclashz-update: https://example.com/stable.json
flclashz-update-pre: https://example.com/pre.json
flclashz-update-core: https://example.com/core-manifest.json
```

- `flclashz-update-core` используется при ручной и автоматической проверке ядра независимо от канала приложения. Без действительного заголовка используется GitHub FlClashZ (`geliopat/Clash.Meta`). Подпись проверяется тем же доверенным ключом; заголовок меняет только источник манифеста, а не правила установки.

- buyplan с порогом показывает продление, когда целое число оставшихся дней не превышает порог; buytraffic — когда процент остатка не превышает порог. Без порога кнопка показывается всегда при наличии действительного URL.
- Резервные адреса заменяют origin исходного URL при сбое скачивания, сохраняя путь, query и учётные данные. Используйте только доверенные адреса панели.
- Текстовые Base64-значения поддерживают префикс `base64:`. Для кириллицы в HTTP используйте UTF-8, закодированный в Base64.

## Стандартные HTTP-заголовки подписки

| Заголовок | Назначение / формат |
|---|---|
| profile-title | Имя профиля, обычный текст или Base64 |
| profile-update-interval | Интервал обновления, целые часы 1–8784 |
| profile-web-page-url | URL страницы подписки |
| support-url | Ссылка поддержки |
| announce | Объявление, обычный текст или Base64; краткое отображение до 200 символов |
| subscription-userinfo | `upload=0; download=0; total=1073741824; expire=1795680000` — байты и Unix-время в секундах |
| content-disposition | Имя скачиваемого файла |
| x-hwid-max-devices-reached | `true` — достигнут лимит устройств |
| x-hwid-not-supported | `true` — панель не поддерживает HWID |

При разрешённой отправке идентификаторов клиент посылает `x-hwid`, `x-device-os`, `x-ver-os`, `x-device-model` в запросе.

## Применение

Заголовки сохраняются вместе с профилем. Управляемые настройки применяются при обновлении или выборе подписки. Унаследованные настройки сохраняют прежнюю логику пользовательского владения и восстановления. Zapret применяет отдельную политику только на Windows. Пример полной конфигурации заголовков:

```http
profile-title: My VPN
profile-update-interval: 12
flclashz-view: app.theme:dark;app.glass:standard
flclashz-widgets: profiles,networkSpeed,networkTakeover,zapret
flclashz-settings: minimize,autorun,autostart
flclashz-special: providermode
flclashz-zapret: autostart,mode:fullbypass,autofallback,autotune,tunemode:fast,tuneonfail
```
