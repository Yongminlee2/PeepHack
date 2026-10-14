# -*- coding: utf-8 -*-
"""store/icon/flat.png·fg.png(1024) 를 안드로이드 런처 아이콘 전 해상도와 아이폰 앱 아이콘(1024 한 장)으로 깐다.
먼저: flutter test tool/render_icon_test.dart   그 다음: python tool/apply_icon.py"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
ADAPTIVE = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}
BG = '#060A07'

flat = Image.open(os.path.join(ROOT, 'store', 'icon', 'flat.png')).convert('RGB')
fg = Image.open(os.path.join(ROOT, 'store', 'icon', 'fg.png')).convert('RGBA')
for d, px in LEGACY.items():
    p = os.path.join(RES, f'mipmap-{d}', 'ic_launcher.png'); os.makedirs(os.path.dirname(p), exist_ok=True)
    flat.resize((px, px), Image.LANCZOS).save(p)
for d, px in ADAPTIVE.items():
    p = os.path.join(RES, f'drawable-{d}', 'ic_launcher_foreground.png'); os.makedirs(os.path.dirname(p), exist_ok=True)
    fg.resize((px, px), Image.LANCZOS).save(p)
os.makedirs(os.path.join(RES, 'mipmap-anydpi-v26'), exist_ok=True)
open(os.path.join(RES, 'mipmap-anydpi-v26', 'ic_launcher.xml'), 'w', encoding='utf-8').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n</adaptive-icon>\n')
open(os.path.join(RES, 'values', 'colors.xml'), 'w', encoding='utf-8').write(
    f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">{BG}</color>\n</resources>\n')
flat.resize((512, 512), Image.LANCZOS).save(os.path.join(ROOT, 'store', 'icon_512.png'))

# 아이폰: 1024 한 장(알파 없음)이면 Xcode 가 나머지 크기를 만든다. 안드로이드만 바꾸고 아이폰을
# 옛 그림으로 두는 일이 없게 같이 만든다.
IOS = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
if os.path.isdir(IOS):
    for f in os.listdir(IOS):
        if f.endswith('.png'):
            os.remove(os.path.join(IOS, f))
    flat.resize((1024, 1024), Image.LANCZOS).save(os.path.join(IOS, 'AppIcon-1024.png'))
    open(os.path.join(IOS, 'Contents.json'), 'w', encoding='utf-8').write(
        '{\n  "images" : [\n    {\n      "filename" : "AppIcon-1024.png",\n      "idiom" : "universal",\n'
        '      "platform" : "ios",\n      "size" : "1024x1024"\n    }\n  ],\n'
        '  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n')
print('done')
