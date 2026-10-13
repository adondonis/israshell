#!/usr/bin/env python3
"""voice-transcribe.py PORT LANG -> records the default mic until SIGTERM and prints json:
{"text": "..."} (nothing for silence) or {"error": "..."}."""

import array
import io
import json
import re
import signal
import subprocess
import sys
import wave

RATE = 16000
FRAME = RATE // 50
FLOOR = 60
RATIO = 2.5
MIN_FRAMES = 8
SILENCE_FRAMES = 100  # 2s of quiet after speech -> ask the shell to stop
PAD = 10
TARGET_PEAK = 20000
MAX_GAIN = 20
PHANTOM_SPEECH_S = 1.5  # hallucinations
PHANTOMS = {"thank you", "thanks", "thanks for watching",
            "thank you for watching", "you", "bye", "bye bye"}

port, lang = sys.argv[1], sys.argv[2]


def out(**kw):
    print(json.dumps(kw), flush=True)
    sys.exit(0)


try:
    rec = subprocess.Popen(["pw-record", "-a", "--rate", str(RATE),
                           "--channels", "1", "--format", "s16", "-"], stdout=subprocess.PIPE)
except OSError as e:
    out(error=str(e))
for sig in (signal.SIGTERM, signal.SIGINT):
    signal.signal(sig, lambda *_: rec.terminate())

frames = []
levels = []
told = False
while len(buf := rec.stdout.read(FRAME * 2)) == FRAME * 2:
    frames.append(buf)
    levels.append(sum(map(abs, array.array("h", buf))) / FRAME)
    if not told and len(levels) % 25 == 0 and len(levels) > SILENCE_FRAMES:
        t = max(FLOOR, RATIO * sorted(levels)[len(levels) // 5])
        if sum(l > t for l in levels) >= MIN_FRAMES and all(l <= t for l in levels[-SILENCE_FRAMES:]):
            told = True
            print('{"silence": true}', flush=True)
if not levels:
    out(text="")
threshold = max(FLOOR, RATIO * sorted(levels)[len(levels) // 5])
loud_at = [i for i, l in enumerate(levels) if l > threshold]
if len(loud_at) < MIN_FRAMES:
    out(text="")
speech_s = len(loud_at) * 0.02
pcm = array.array("h", b"".join(
    frames[max(0, loud_at[0] - PAD):loud_at[-1] + 1 + PAD]))
gain = min(MAX_GAIN, TARGET_PEAK / max(1, max(abs(s) for s in pcm)))
if gain > 1:
    pcm = array.array("h", (int(s * gain) for s in pcm))

clip = io.BytesIO()
with wave.open(clip, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(pcm.tobytes())

r = subprocess.run(["curl", "-sSf", "-m", "120", "--retry", "300", "--retry-connrefused", "--retry-delay", "1",
                    "-F", "file=@-;filename=a.wav", "-F", f"language={lang}", "-F", "temperature=0", "-F", "response_format=json",
                    f"http://127.0.0.1:{port}/inference"], input=clip.getvalue(), capture_output=True)
try:
    text = json.loads(r.stdout)["text"]
except Exception:
    out(error=r.stderr.decode().strip() or "bad response")
text = re.sub(r"\[[^\]]*\]|\([^)]*\)|\*[^*]*\*", "",
              text)  # [BLANK_AUDIO], (music), *scream*
text = " ".join(text.split())
if not re.search(r"\w", text):
    text = ""
if speech_s < PHANTOM_SPEECH_S and re.sub(r"[^\w ]", "", text.lower()).strip() in PHANTOMS:
    text = ""
out(text=text)
