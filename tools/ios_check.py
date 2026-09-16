# -*- coding: utf-8 -*-
"""Проверка iOS-каркаса: что готово, что нет. Плюс правка текстов разрешений."""
import io, os, re, sys

APPS = [
    (r'D:\Projects\Mobile\rune_sudby_publish', 'Руна Судьбы'),
    (r'D:\Projects\Mobile\coffee_fortune\coffee_fortune_v2', 'Кофейная гуща'),
]
PERM_TEXT = {
    'NSCameraUsageDescription': 'Камера нужна, чтобы сфотографировать и сразу получить результат — фото никуда не отправляется без вашего действия.',
    'NSPhotoLibraryUsageDescription': 'Доступ к галерее нужен, чтобы выбрать уже сделанное фото. Приложение не читает другие файлы.',
    'NSMicrophoneUsageDescription': 'Микрофон используется только для записи по нажатию кнопки.',
}

for proj, name in APPS:
    print('=== %s (%s) ===' % (name, os.path.basename(proj)))
    ios = os.path.join(proj, 'ios')
    iconset = os.path.join(ios, 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    n_icons = len([f for f in os.listdir(iconset) if f.endswith('.png')]) if os.path.isdir(iconset) else 0
    big = os.path.join(iconset, 'Icon-App-1024x1024@1x.png')
    big_kb = round(os.path.getsize(big) / 1024) if os.path.exists(big) else 0
    print(' иконки: %d файлов, 1024 = %d КБ %s' % (n_icons, big_kb, 'OK' if big_kb > 20 else 'ПОХОЖЕ НА ПУСТЫШКУ'))
    li = os.path.join(ios, 'Runner', 'Assets.xcassets', 'LaunchImage.imageset')
    print(' экран запуска: картинок %d, storyboard %s' % (
        len([f for f in os.listdir(li) if f.endswith('.png')]) if os.path.isdir(li) else 0,
        'есть' if os.path.exists(os.path.join(ios, 'Runner', 'Base.lproj', 'LaunchScreen.storyboard')) else 'НЕТ'))
    pv = os.path.join(ios, 'Runner', 'PrivacyInfo.xcprivacy')
    pbx = io.open(os.path.join(ios, 'Runner.xcodeproj', 'project.pbxproj'), encoding='utf-8').read()
    print(' манифест приватности: файл %s, в проекте Xcode %s' % (
        'есть' if os.path.exists(pv) else 'НЕТ', 'да' if 'PrivacyInfo.xcprivacy' in pbx else 'НЕТ'))
    pod = os.path.join(ios, 'Podfile')
    plat = re.search(r"platform :ios, '([0-9.]+)'", io.open(pod, encoding='utf-8').read()) if os.path.exists(pod) else None
    print(' Podfile: %s' % (plat.group(1) if plat else 'НЕТ platform'))
    plist_path = os.path.join(ios, 'Runner', 'Info.plist')
    t = io.open(plist_path, encoding='utf-8').read()
    fixed = []
    for key, text in PERM_TEXT.items():
        if '<key>%s</key>' % key in t:
            new_t = re.sub(r'(<key>%s</key>\s*<string>)[^<]*(</string>)' % key, r'\g<1>%s\g<2>' % text.replace('\\', ''), t)
            if new_t != t:
                t = new_t
                fixed.append(key)
    io.open(plist_path, 'w', encoding='utf-8').write(t)
    name_ok = re.search(r'<key>CFBundleDisplayName</key>\s*<string>([^<]*)</string>', t)
    print(' Info.plist: имя «%s», шифрование снято: %s, разрешения: %s' % (
        name_ok.group(1) if name_ok else '?',
        'да' if 'ITSAppUsesNonExemptEncryption' in t else 'НЕТ',
        ', '.join(k.replace('NS', '').replace('UsageDescription', '') for k in PERM_TEXT if '<key>%s</key>' % k in t) or '—'))
    if fixed:
        print('  текст(ы) разрешений поправлены: %s' % ', '.join(fixed))
    wf = os.path.join(proj, '.github', 'workflows', 'ios-build.yml')
    print(' автопроверка сборки: %s' % ('есть' if os.path.exists(wf) else 'НЕТ'))
    doc = os.path.join(proj, 'docs', 'ios', 'ГОТОВНОСТЬ_IOS.md')
    print(' документ готовности: %s' % ('есть' if os.path.exists(doc) else 'НЕТ'))
    print(' плейсхолдеров «укажите» в Info.plist: %d' % len(re.findall(r'укажите', t)))
    print()
