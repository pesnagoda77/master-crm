# -*- coding: utf-8 -*-
"""Доводка iOS-каркаса до состояния «готово к Mac» + документы и бэкап.

Использование:
    python ios_finish.py "<проект>" --name "Руна Судьбы" --bundle com.slavanapps.runeday
        [--iap "premium_forever,premium_30days"] [--info "камера нужна, чтобы сфотографировать чашку"]
"""
import argparse, io, os, shutil, sys, datetime

BACKUPS = r'D:\Projects\Backups'


def plist_add(path, key, value_xml):
    t = io.open(path, encoding='utf-8').read()
    if '<key>%s</key>' % key in t:
        return False
    t = t.replace('</dict>\n</plist>', '\t<key>%s</key>\n\t%s\n</dict>\n</plist>' % (key, value_xml), 1)
    io.open(path, 'w', encoding='utf-8').write(t)
    return True


DOC_READY = '''# Готовность к iOS — {name}

Дата подготовки: {date}
Bundle identifier: `{bundle}`
Минимальная версия iOS: 13.0

## Что уже сделано (без Mac)

| Пункт | Состояние |
|---|---|
| Иконки приложения | 15 размеров (20…1024), взяты из иконки Android |
| Экран запуска | Тёмный фон {bg}, прозрачная картинка запуска (без «флаттер-логотипа») |
| Манифест приватности Apple (`PrivacyInfo.xcprivacy`) | создан и добавлен в проект Xcode |
| Разрешения в Info.plist | {perms} |
| Вопрос про шифрование (`ITSAppUsesNonExemptEncryption`) | снят — Apple не будет спрашивать при каждой отправке |
| Автопроверка сборки на macOS | GitHub Actions, workflow `.github/workflows/ios-build.yml` |
| Bundle identifier, версия iOS | заданы в проекте |

## Что нужно сделать на Mac (по шагам)

1. Установить Xcode (App Store) и один раз выполнить `sudo xcodebuild -runFirstLaunch`.
2. В папке проекта: `flutter pub get`, затем `cd ios && pod install`.
3. Открыть `ios/Runner.xcworkspace` (именно workspace, не xcodeproj).
4. В настройках цели Runner выбрать команду разработчика (Team) и поставить автоматическую подпись.
5. Проверить сборку: `flutter build ios --release` (или Product → Archive в Xcode).
6. Загрузить в TestFlight: Product → Archive → Distribute App → App Store Connect.
7. Проверить на живом iPhone: запись, покупки (для Руны — `{iap}`), сохранение данных.

## App Store Connect (запись приложения)

- Название: {name}
- Bundle ID: `{bundle}` (создать App ID в developer.apple.com, если ещё нет)
- Категория: {category}
- Возрастной рейтинг: 4+ (если приложение — развлечение/инструмент без спорного контента; для гаданий указать «Развлечения»)
- Политика конфиденциальности: обязательна ссылка
- Внутренние покупки: {iap}
- Скриншоты: 6,7" (1290×2796), 6,5" (1242×2688) — по 3–5 штук; для iPad — если поддерживается

## Чек-лист перед отправкой на проверку

- [ ] Приложение открывается без сети и не падает на пустом списке
- [ ] Все покупки восстанавливаются кнопкой «Восстановить»
- [ ] Нет упоминаний «Android», «Google Play» в текстах
- [ ] В описании честно указано, что всё считается на устройстве (если применимо)
- [ ] Файл `PrivacyInfo.xcprivacy` в сборке (Проверить в архиве .xcarchive)
- [ ] Нет тестовых/отладочных экранов, доступных пользователю
'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('project')
    ap.add_argument('--name', required=True)
    ap.add_argument('--bundle', required=True)
    ap.add_argument('--iap', default='—')
    ap.add_argument('--category', default='Утилиты')
    ap.add_argument('--perms', default='—')
    ap.add_argument('--bg', default='#12141a')
    a = ap.parse_args()

    proj = os.path.abspath(a.project)
    ios = os.path.join(proj, 'ios')
    plist = os.path.join(ios, 'Runner', 'Info.plist')
    report = []

    # 1. снять вопрос про шифрование
    if os.path.exists(plist) and plist_add(plist, 'ITSAppUsesNonExemptEncryption', '<false/>'):
        report.append('Info.plist: добавлен ITSAppUsesNonExemptEncryption=false')

    # 2. документы
    docs = os.path.join(proj, 'docs', 'ios')
    os.makedirs(docs, exist_ok=True)
    txt = DOC_READY.format(name=a.name, bundle=a.bundle, iap=a.iap, perms=a.perms,
                           bg=a.bg, category=a.category,
                           date=datetime.date.today().strftime('%d.%m.%Y'))
    io.open(os.path.join(docs, 'ГОТОВНОСТЬ_IOS.md'), 'w', encoding='utf-8').write(txt)
    report.append('документ: docs/ios/ГОТОВНОСТЬ_IOS.md')

    # 3. бэкап подготовленного исходника
    stamp = datetime.date.today().strftime('%Y-%m-%d')
    dst = os.path.join(BACKUPS, '%s_ios_prepared_%s' % (os.path.basename(proj), stamp))
    if not os.path.exists(dst):
        os.makedirs(dst, exist_ok=True)
        ignored = shutil.ignore_patterns('build', '.dart_tool', '.git', '.gradle', '.idea', 'Pods')
        shutil.copytree(proj, os.path.join(dst, os.path.basename(proj)), ignore=ignored)
        report.append('бэкап: %s' % dst)
    else:
        report.append('бэкап уже есть: %s' % dst)

    print('=== iOS-доводка: %s ===' % a.name)
    for r in report:
        print(' •', r)
    print(' • bundle: %s | покупки: %s' % (a.bundle, a.iap))


if __name__ == '__main__':
    main()
