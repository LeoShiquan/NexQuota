#!/usr/bin/env python3
"""Compose local documentation assets (Python 3, Swift/macOS, Node + marked).

Native screenshots: ./Scripts/render-doc-images.sh
Optional doc tooling dependency: npm install --prefix Scripts
This script does not install software, publish anything, or visit a provider.
"""
from pathlib import Path
import os
import subprocess
import struct
import zlib

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / 'docs/assets'
PREVIEW = ROOT / 'docs/preview'
ASSETS.mkdir(exist_ok=True, parents=True)
PREVIEW.mkdir(exist_ok=True, parents=True)

badges = [
    (0, 152, 'macOS 13+ target'), (162, 140, 'Apple Silicon'),
    (312, 108, 'Swift 6'), (430, 108, 'MIT License'),
]
svg = '<svg xmlns="http://www.w3.org/2000/svg" width="538" height="28" viewBox="0 0 538 28" role="img"><title>macOS 13+ target · Apple Silicon · Swift 6 · MIT</title>'
for x, width, label in badges:
    svg += f'<rect x="{x}" y="1" width="{width}" height="26" rx="6" fill="#f0f5f5" stroke="#d9e6e5"/><text x="{x + width/2}" y="18" text-anchor="middle" font-family="-apple-system,Arial,sans-serif" font-size="12" fill="#314c50">{label}</text>'
(ASSETS / 'badges.svg').write_text(svg + '</svg>', encoding='utf-8')

hero = '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="referrer" content="no-referrer"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src file:; style-src 'unsafe-inline'"><style>
*{box-sizing:border-box}html,body{margin:0;width:1440px;height:760px;overflow:hidden}body{background:linear-gradient(120deg,#eef8f4 0%,#f5f9fa 62%,#e8f3f7 100%);color:#162d36;font-family:-apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif}.logo{position:absolute;top:77px;left:77px;display:flex;align-items:center;gap:19px}.logo img{width:76px;height:76px;border-radius:20px}.logo strong{font-size:34px;font-weight:680;letter-spacing:-1px}.logo small{display:block;font-size:13px;letter-spacing:2px;color:#4a676e;margin-top:5px}.copy{position:absolute;left:82px;top:231px;width:660px}.copy h1{font-size:68px;line-height:1.24;letter-spacing:-3px;font-weight:660;margin:0 0 28px}.copy p{font-size:23px;line-height:1.7;max-width:570px;color:#48626a;margin:0}.facts{display:flex;gap:24px;margin-top:38px;font-size:17px;color:#2c6368}.facts span{display:flex;align-items:center;gap:8px}.facts i{width:7px;height:7px;background:#16858a;border-radius:50%;display:inline-block}.scene{position:absolute;left:850px;top:106px;width:462px}.bar{height:36px;width:462px;border:1px solid #d1dfe1;border-radius:10px;background:rgba(255,255,255,.92);display:flex;justify-content:flex-end;gap:11px;align-items:center;padding:0 18px;color:#263d44;font-size:14px;box-shadow:0 4px 14px rgba(22,61,73,.04)}.bar svg{width:20px;height:15px}.active{font-weight:650;display:flex;align-items:center;gap:7px;background:#e1eeed;padding:5px 10px;border-radius:6px}.window{margin:13px auto 0;width:410px;background:#fff;border:1px solid #c9d7da;border-radius:17px;overflow:hidden;box-shadow:0 18px 44px rgba(25,61,72,.16)}.window img{width:100%;display:block}.scene-note{margin-top:24px;text-align:center;color:#54717a;font-size:13px;letter-spacing:.5px}.bottom{position:absolute;left:83px;bottom:49px;right:83px;border-top:1px solid #cbdedd;padding-top:18px;display:flex;justify-content:space-between;font-size:13px;color:#547078}.bottom strong{font-weight:600;color:#36585f}
</style></head><body><div class="logo"><img src="../assets/AppIcon.png" alt="NexQuota 图标"><div><strong>NexQuota</strong><small>NEXITALLY QUOTA MONITOR</small></div></div><div class="copy"><h1>流量余额，<br>抬头就能看见。</h1><p>把 Nexitally 账户的剩余额度与套餐周期，<br>放进每天都在看的菜单栏。</p><div class="facts"><span><i></i>原生界面</span><span><i></i>定时刷新</span><span><i></i>会话留在本机</span></div></div><div class="scene"><div class="bar"><span class="active"><svg viewBox="0 0 20 15" fill="none"><rect x="1" y="3" width="17" height="10" rx="2" stroke="currentColor" stroke-width="1.4"/><rect x="3" y="5" width="10" height="6" rx="1" fill="currentColor"/><path d="M18 6h1v4h-1" stroke="currentColor"/></svg>375.0G</span><span>周五 18:00</span></div><div class="window"><img src="../assets/menu.png" alt="演示用量：剩余 375 GB"></div><div class="scene-note">原生视图 · 固定演示数据</div></div><div class="bottom"><strong>Nexitally 账户用量 · 非官方工具</strong><span>Swift / SwiftUI / WebKit · Source build</span></div></body></html>'''
(PREVIEW / 'hero.html').write_text(hero, encoding='utf-8')
env = os.environ.copy()
node = env.get('NEXQUOTA_DOC_NODE', 'node')
subprocess.run([node, str(ROOT / 'Scripts/render-readme.mjs'), str(ROOT / 'README.md'), str(PREVIEW / 'index.html')], check=True, env=env)
binary = ROOT / '.build/render-html'
binary.parent.mkdir(parents=True, exist_ok=True)
subprocess.run(['swiftc', '-O', '-swift-version', '6', '-warnings-as-errors', '-parse-as-library', '-module-cache-path', str(ROOT / '.build/module-cache'), str(ROOT / 'Scripts/render-html.swift'), '-o', str(binary)], check=True)
subprocess.run([str(binary), str(PREVIEW / 'hero.html'), str(ASSETS / 'hero.png'), '1440', '760'], check=True)
subprocess.run([str(binary), str(PREVIEW / 'index.html'), str(PREVIEW / 'readme-preview.png'), '1100', '-1'], check=True)
subprocess.run([str(binary), str(PREVIEW / 'index.html'), str(PREVIEW / 'readme-full.png'), '1100', '0'], check=True)
# Retain only pixel, color and display-resolution chunks. Drop EXIF, text,
# provenance/content credentials and other non-visual ancillary metadata.
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
PNG_VISUAL_CHUNKS = {b'IHDR', b'IDAT', b'IEND', b'sRGB', b'iCCP', b'gAMA', b'cHRM', b'pHYs', b'PLTE', b'tRNS'}


def strip_png_metadata(data):
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError('Expected a PNG image')
    cleaned = bytearray(PNG_SIGNATURE)
    offset = len(PNG_SIGNATURE)
    while offset + 12 <= len(data):
        length = struct.unpack('>I', data[offset:offset + 4])[0]
        end = offset + length + 12
        if end > len(data):
            raise ValueError('Truncated PNG chunk')
        kind = data[offset + 4:offset + 8]
        expected_crc = struct.unpack('>I', data[end - 4:end])[0]
        if zlib.crc32(data[offset + 4:end - 4]) != expected_crc:
            raise ValueError('Invalid PNG chunk checksum')
        if kind in PNG_VISUAL_CHUNKS:
            cleaned.extend(data[offset:end])
        offset = end
        if kind == b'IEND':
            return bytes(cleaned)
    raise ValueError('Missing PNG end chunk')


def strip_icns_metadata(data):
    if data[:4] != b'icns' or len(data) < 8:
        raise ValueError('Expected an ICNS image')
    total = struct.unpack('>I', data[4:8])[0]
    if total != len(data):
        raise ValueError('Invalid ICNS container length')
    elements = bytearray()
    offset = 8
    while offset + 8 <= total:
        kind = data[offset:offset + 4]
        length = struct.unpack('>I', data[offset + 4:offset + 8])[0]
        if length < 8 or offset + length > total:
            raise ValueError('Invalid ICNS element length')
        payload = data[offset + 8:offset + length]
        # The optional info element describes the authoring tool, not pixels.
        if kind != b'info':
            if payload.startswith(PNG_SIGNATURE):
                payload = strip_png_metadata(payload)
            elements.extend(kind + struct.pack('>I', len(payload) + 8) + payload)
        offset += length
    if offset != total:
        raise ValueError('Truncated ICNS element')
    return b'icns' + struct.pack('>I', len(elements) + 8) + elements


for path in [ROOT / 'Resources/AppIcon.png', *ASSETS.glob('*.png'), *PREVIEW.glob('*.png')]:
    path.write_bytes(strip_png_metadata(path.read_bytes()))
icon = ROOT / 'Resources/AppIcon.icns'
icon.write_bytes(strip_icns_metadata(icon.read_bytes()))
print('Composed hero, badges, and README previews; PNG and ICNS metadata removed.')
