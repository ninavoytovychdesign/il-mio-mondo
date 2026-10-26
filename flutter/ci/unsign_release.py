# Before `flutter build appbundle`: the Play bundle is built without the debug key,
# it is signed afterwards with the upload key (kept outside the public repo).
import pathlib, re
g = pathlib.Path('android/app/build.gradle.kts')
t = g.read_text()
t2 = re.sub(r'\n\s*signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', '', t)
assert t2 != t, 'release signingConfig line not found'
g.write_text(t2)
print(t2)
