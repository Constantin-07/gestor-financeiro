#!/usr/bin/env python3
"""Copia o app web atual para ios/Resources/www, sem o service worker
(que não existe num WKWebView com esquema próprio)."""
import os, re, shutil
aqui = os.path.dirname(os.path.abspath(__file__))
app = os.path.join(aqui, "..", "app")
www = os.path.join(aqui, "Resources", "www")
os.makedirs(www, exist_ok=True)
s = open(os.path.join(app, "index.html"), encoding="utf-8").read()
s = re.sub(r'<script>\s*if\("serviceWorker" in navigator\)\{.*?</script>\s*', "", s, flags=re.S)
open(os.path.join(www, "index.html"), "w", encoding="utf-8").write(s)
for f in ("icon.svg", "icon-192.png", "icon-512.png", "manifest.webmanifest"):
    shutil.copy(os.path.join(app, f), www)
print("www sincronizado:", www)
