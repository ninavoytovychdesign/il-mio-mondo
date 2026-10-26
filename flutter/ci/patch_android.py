# Runs in CI right after `flutter create`: app name and the TTS query Android 11+ needs to find a voice.
import pathlib, re

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = m.read_text()
s = re.sub(r'android:label="[^"]*"', 'android:label="Il mio mondo"', s, count=1)
tts = '<intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>'
if 'TTS_SERVICE' not in s:
    if '<queries>' in s:
        s = s.replace('<queries>', '<queries>\n        ' + tts, 1)
    else:
        s = s.replace('</manifest>', '    <queries>\n        ' + tts + '\n    </queries>\n</manifest>', 1)
m.write_text(s)
print(s)
