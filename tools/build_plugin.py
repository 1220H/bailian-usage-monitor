#!/usr/bin/env python3
"""Build the SwiftBar plugin: render the ring icons and embed them in the script.

    pip install pillow
    python3 tools/build_plugin.py

Reads tools/plugin.tpl.sh, writes swiftbar/bailian.5m.sh
Rings: 0%..100% in 5% steps, light + dark menu bar variants, 36px @144dpi (= 18pt Retina).
"""
import base64, io, math, pathlib
from PIL import Image, ImageDraw

REPO_URL = "https://github.com/1220H/bailian-usage-monitor"
ROOT = pathlib.Path(__file__).resolve().parent.parent
S=8; PX=36; W=PX*S
def color(p):
    if p>=50: return (52,199,89,255)
    if p>=20: return (255,159,10,255)
    return (255,69,58,255)
def ring(p, dark):
    im=Image.new('RGBA',(W,W),(0,0,0,0)); d=ImageDraw.Draw(im)
    sw=4.2*S; pad=3*S; box=[pad,pad,W-pad,W-pad]
    track=(255,255,255,80) if dark else (0,0,0,55)
    d.ellipse(box,outline=track,width=int(sw))
    if p>0:
        c=color(p); a0=-90; a1=-90+360*p/100
        d.arc(box,a0,a1,fill=c,width=int(sw))
        r=(W-2*pad)/2 - sw/2; cx=cy=W/2
        for a in (a0,a1) if p<100 else ():
            x=cx+r*math.cos(math.radians(a)); y=cy+r*math.sin(math.radians(a))
            d.ellipse([x-sw/2,y-sw/2,x+sw/2,y+sw/2],fill=c)
    im=im.resize((PX,PX),Image.LANCZOS)
    b=io.BytesIO(); im.save(b,'PNG',dpi=(144,144),optimize=True)
    return base64.b64encode(b.getvalue()).decode(), im
light=[]; dark=[]
for p in range(0,101,5):
    light.append(ring(p,False)[0]); dark.append(ring(p,True)[0])
rings='RING_L=(\n'+'\n'.join(light)+'\n)\nRING_D=(\n'+'\n'.join(dark)+'\n)\n'
tpl=(ROOT/'tools'/'plugin.tpl.sh').read_text(encoding='utf-8').replace('__REPO_URL__', REPO_URL)
out=tpl.rstrip()+'\n\n# ====== 圆环图标（由 tools/build_plugin.py 生成：0%~100%，每 5% 一张；浅色/深色菜单栏各一套）======\n'+rings+'\nmain\n'
dst=ROOT/'swiftbar'/'bailian.5m.sh'
dst.write_text(out, encoding='utf-8'); dst.chmod(0o755)
print(f'wrote {dst.relative_to(ROOT)} ({len(out):,} bytes)')
