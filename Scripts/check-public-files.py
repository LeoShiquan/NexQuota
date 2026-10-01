#!/usr/bin/env python3
"""Check publishable files without reading ignored local configuration or sessions."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import plistlib
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
SKIP = {'.git', '.build', 'node_modules', 'Screenshots.private', '__pycache__'}
TEXT = {'.md', '.swift', '.js', '.mjs', '.py', '.sh', '.yml', '.yaml', '.json', '.svg', '.html', '.plist'}
errors = []
checked_links = 0

def publishable(path):
    relative = path.relative_to(ROOT)
    return not any(part in SKIP or part.endswith(('.app', '.build')) for part in relative.parts) and path.name != 'Config.local.plist' and path.name != '.DS_Store'

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.links = []; self.base = None
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'base': self.base = values.get('href')
        for key in ('src', 'href'):
            if key in values and tag != 'base': self.links.append(values[key])

def check_link(path, base, value):
    global checked_links
    parsed = urlsplit(value)
    if parsed.scheme or value.startswith(('#', '//')): return
    target = (base / unquote(parsed.path)).resolve()
    checked_links += 1
    if not target.is_relative_to(ROOT) or not target.exists():
        errors.append(f'{path.relative_to(ROOT)}: broken local link {value}')

for name in ['README.md', 'README.en.md', 'LICENSE', 'CONTRIBUTING.md', 'SECURITY.md', 'Config.example.plist', 'docs/RELATED_PROJECTS.md', 'docs/assets/hero.png', 'docs/assets/menu.png', 'docs/assets/settings.png', 'docs/assets/stale.png', 'docs/preview/index.html']:
    if not (ROOT / name).is_file(): errors.append(f'Missing required public file: {name}')
config = plistlib.loads((ROOT / 'Config.example.plist').read_bytes())
if urlsplit(config.get('SiteURL', '')).hostname != 'panel.example.com':
    errors.append('Example configuration must use the reserved example domain')

files = [p for p in ROOT.rglob('*') if p.is_file() and publishable(p)]
for path in files:
    if path.suffix not in TEXT and path.name not in {'LICENSE', '.gitignore'}: continue
    content = path.read_text(encoding='utf-8')
    if re.search(r'gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}', content):
        errors.append(f'{path.relative_to(ROOT)}: possible GitHub credential')
    if '-----BEGIN ' + 'PRIVATE KEY-----' in content:
        errors.append(f'{path.relative_to(ROOT)}: possible private key')
    if re.search('/Users/' + r'[A-Za-z0-9_-]+/', content):
        errors.append(f'{path.relative_to(ROOT)}: private absolute user path')
    for url in re.findall(r'https?://[^\s<>"\x27]+', content):
        parsed = urlsplit(url)
        host = parsed.hostname or ''
        if (parsed.username or parsed.password) and not host.endswith('.example.com'):
            errors.append(f'{path.relative_to(ROOT)}: URL embeds account credentials')
    if path.suffix in {'.md', '.html'}:
        parser = Links(); parser.feed(content)
        base = (path.parent / parser.base).resolve() if parser.base else path.parent
        for value in parser.links: check_link(path, base, value)
        if path.suffix == '.md':
            for value in re.findall(r'\]\(([^)]+)\)', content): check_link(path, path.parent, value)

if errors:
    print('\n'.join(errors)); sys.exit(1)
print(f'Public file check passed: {len(files)} files, {checked_links} local links, reserved example configuration.')
print('Images still require visual review before publication.')
