"""나눔고딕코딩(OFL)에서 영문·숫자·기호만 잘라 HackMono 로 만든다.
한글은 이 글꼴로 그리면 글자 사이가 벌어져 보여서, 한글은 기기 기본 글꼴이 그리게 둔다.
OFL 은 고친 글꼴에 원래 이름(Nanum…)을 쓰지 못하게 하므로 이름도 HackMono 로 바꾼다.

  python tool/subset_font.py <NanumGothicCoding.ttf>   → assets/fonts/HackMono.ttf
"""
import sys
from fontTools import subset
from fontTools.ttLib import TTFont

src = sys.argv[1]
out = 'assets/fonts/HackMono.ttf'
opts = subset.Options()
opts.name_IDs = ['*']
opts.layout_features = ['*']
font = TTFont(src)
s = subset.Subsetter(opts)
s.populate(unicodes=[*range(0x20, 0x7F), *range(0xA0, 0x100), *range(0x2010, 0x2028),
                     *range(0x2190, 0x2200), *range(0x2500, 0x2600), 0x2605, 0x2606])
s.subset(font)
names = {1: 'HackMono', 3: 'HackMono-Regular', 4: 'HackMono', 6: 'HackMono-Regular', 16: 'HackMono'}
for rec in font['name'].names:
    if rec.nameID in names:
        rec.string = names[rec.nameID]
font.save(out)
print(out, len(font.getGlyphOrder()), 'glyphs')
