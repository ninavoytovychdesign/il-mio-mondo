# Runs in CI right after `flutter create`: app name and the TTS query Android 11+ needs to find a voice.
import pathlib, re

m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = m.read_text()
s = re.sub(r'android:label="[^"]*"', 'android:label="Pasetto"', s, count=1)
tts = '<intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>'
if 'TTS_SERVICE' not in s:
    if '<queries>' in s:
        s = s.replace('<queries>', '<queries>\n        ' + tts, 1)
    else:
        s = s.replace('</manifest>', '    <queries>\n        ' + tts + '\n    </queries>\n</manifest>', 1)
# links to Google Calendar open in the browser / Calendar app (Android 11+ needs the query)
view = '<intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>'
if 'android:scheme="https"' not in s:
    s = s.replace('<queries>', '<queries>\n        ' + view, 1)
# nothing leaves the device: no Android cloud backup of the app data
if 'android:allowBackup' not in s:
    s = s.replace('<application', '<application android:allowBackup="false"', 1)
# voice notes in the Diary
if 'RECORD_AUDIO' not in s:
    s = s.replace('<application', '<uses-permission android:name="android.permission.RECORD_AUDIO" />\n    <application', 1)
m.write_text(s)
print(s)

# Google Play: final app id, target API 36, version from the build command
g = pathlib.Path('android/app/build.gradle.kts')
t = g.read_text()
t = re.sub(r'applicationId\s*=\s*"[^"]*"', 'applicationId = "it.pasetto.app"', t, count=1)
t = re.sub(r'targetSdk\s*=\s*[^\n]+', 'targetSdk = 36', t, count=1)
t = re.sub(r'compileSdk\s*=\s*[^\n]+', 'compileSdk = maxOf(flutter.compileSdkVersion, 36)', t, count=1)
g.write_text(t)
print(t)
