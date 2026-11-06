#!/usr/bin/env python3
"""
Pixel Now Playing - companion для Pixel Client.

Roblox не видит, что играет у тебя в системе, поэтому этот маленький локальный сервер
читает текущий трек и отдаёт его скрипту на http://127.0.0.1:8765/now

Запуск:   python PixelNowPlaying.py            (порт по умолчанию 8765)
          python PixelNowPlaying.py 9000       (свой порт; тот же укажи в HUD -> Now Playing -> Порт)

Windows: для ЛЮБОГО плеера (Spotify, YouTube Music/браузер, foobar, Яндекс Музыка...) поставь один раз:
          pip install winsdk
         Без winsdk работает запасной вариант - заголовок окна Spotify.
Linux:   нужен playerctl (sudo apt install playerctl)
macOS:   Spotify / Music через osascript
Сервер слушает только 127.0.0.1 (локально), наружу ничего не отдаёт.
"""
import json
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
EMPTY = {"title": "", "artist": "", "app": "", "playing": False}


# ---------- Windows: системный медиа-сеанс (SMTC) ----------
def win_smtc():
    try:
        import asyncio
        from winsdk.windows.media.control import (
            GlobalSystemMediaTransportControlsSessionManager as Manager,
        )

        async def run():
            mgr = await Manager.request_async()
            ses = mgr.get_current_session()
            if not ses:
                return None
            info = await ses.try_get_media_properties_async()
            pb = ses.get_playback_info()
            app = (ses.source_app_user_model_id or "").split("!")[0].replace(".exe", "")
            return {
                "title": info.title or "",
                "artist": info.artist or "",
                "app": app,
                "playing": int(pb.playback_status) == 4,  # 4 = Playing
            }

        return asyncio.run(run())
    except Exception:
        return None


# ---------- Windows: запасной вариант - заголовок окна Spotify ----------
def win_spotify_title():
    try:
        import ctypes
        from ctypes import wintypes

        user32 = ctypes.windll.user32
        found = []

        @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
        def cb(hwnd, _):
            if not user32.IsWindowVisible(hwnd):
                return True
            cls = ctypes.create_unicode_buffer(256)
            user32.GetClassNameW(hwnd, cls, 256)
            if cls.value.startswith("Chrome_WidgetWin"):
                n = user32.GetWindowTextLengthW(hwnd)
                if n:
                    buf = ctypes.create_unicode_buffer(n + 1)
                    user32.GetWindowTextW(hwnd, buf, n + 1)
                    found.append(buf.value)
            return True

        user32.EnumWindows(cb, 0)
        for t in found:
            if " - " in t and t not in ("Spotify", "Spotify Free", "Spotify Premium"):
                artist, title = t.split(" - ", 1)
                return {"title": title, "artist": artist, "app": "Spotify", "playing": True}
    except Exception:
        pass
    return None


# ---------- Linux ----------
def linux_playerctl():
    try:
        out = subprocess.check_output(
            ["playerctl", "metadata", "--format", "{{artist}}\t{{title}}\t{{playerName}}\t{{status}}"],
            stderr=subprocess.DEVNULL, timeout=2,
        ).decode("utf-8", "ignore").strip().split("\t")
        if len(out) >= 4:
            return {"title": out[1], "artist": out[0], "app": out[2], "playing": out[3] == "Playing"}
    except Exception:
        pass
    return None


# ---------- macOS ----------
def mac_osascript():
    for app in ("Spotify", "Music"):
        try:
            script = (
                f'if application "{app}" is running then tell application "{app}" to '
                f'return (artist of current track) & "\\t" & (name of current track) & "\\t" & (player state as string)'
            )
            out = subprocess.check_output(["osascript", "-e", script], stderr=subprocess.DEVNULL, timeout=2)
            a = out.decode("utf-8", "ignore").strip().split("\t")
            if len(a) >= 3:
                return {"title": a[1], "artist": a[0], "app": app, "playing": a[2] == "playing"}
        except Exception:
            continue
    return None


def now_playing():
    if sys.platform.startswith("win"):
        return win_smtc() or win_spotify_title() or EMPTY
    if sys.platform == "darwin":
        return mac_osascript() or EMPTY
    return linux_playerctl() or EMPTY


# ---------- кэш + HTTP ----------
_cache = {"t": 0.0, "d": EMPTY}
_lock = threading.Lock()


def cached():
    with _lock:
        if time.time() - _cache["t"] > 1.0:
            _cache["d"], _cache["t"] = now_playing(), time.time()
        return _cache["d"]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(cached(), ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    srv = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Pixel Now Playing: http://127.0.0.1:{PORT}/now   (Ctrl+C - выход)")
    print("Сейчас:", cached())
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
