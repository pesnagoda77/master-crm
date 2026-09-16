# -*- coding: utf-8 -*-
"""Смена человеческого имени приложения: Android (манифест + strings.xml) и iOS (Info.plist)."""
import io, os, re, sys

APPS = [
    (r'D:\Projects\Mobile\meds_tracker', 'Таблетница'),
    (r'D:\Projects\Mobile\warranty_scanner', 'Гарантийник'),
    (r'D:\Projects\Mobile\advocate', 'Адвоката!'),
]


def set_android(proj, name):
    done = []
    man = os.path.join(proj, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')
    if os.path.exists(man):
        t = io.open(man, encoding='utf-8').read()
        t2 = re.sub(r'android:label="[^"]*"', 'android:label="%s"' % name, t, count=1)
        if t2 != t:
            io.open(man, 'w', encoding='utf-8').write(t2)
            done.append('AndroidManifest')
    for rel in (r'android\app\src\main\res\values\strings.xml', r'android\app\src\main\res\values\strings.xml'.replace('values', 'values-ru')):
        p = os.path.join(proj, rel)
        if os.path.exists(p):
            t = io.open(p, encoding='utf-8').read()
            t2 = re.sub(r'(<string name="app_name">)[^<]*(</string>)', r'\g<1>%s\g<2>' % name, t)
            if t2 != t:
                io.open(p, 'w', encoding='utf-8').write(t2)
                done.append(os.path.basename(rel))
    return done or ['(в Android не нашлось, где менять)']


def set_ios(proj, name):
    p = os.path.join(proj, 'ios', 'Runner', 'Info.plist')
    if not os.path.exists(p):
        return ['(iOS-части нет)']
    t = io.open(p, encoding='utf-8').read()
    t2 = re.sub(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', r'\g<1>%s\g<2>' % name, t)
    if t2 != t:
        io.open(p, 'w', encoding='utf-8').write(t2)
        return ['Info.plist (iOS)']
    return ['(в iOS имя не нашлось)']


for proj, name in APPS:
    print('=== %s -> «%s» ===' % (os.path.basename(proj), name))
    print(' Android:', ', '.join(set_android(proj, name)))
    print(' iOS:', ', '.join(set_ios(proj, name)))
