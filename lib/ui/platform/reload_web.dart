import 'dart:js_interop';

@JS('location.reload')
external void _reload();

@JS('sessionStorage.getItem')
external JSString? _get(JSString key);

@JS('sessionStorage.setItem')
external void _set(JSString key, JSString value);

const _key = 'alasfit.reloadedFor';

/// Reloads the web page to pick up a newly deployed build, remembering
/// [forBuild] so a reload that still gets the old files (a stale cache)
/// isn't offered again and again.
void reloadPage({String? forBuild}) {
  if (forBuild != null) {
    try {
      _set(_key.toJS, forBuild.toJS);
    } catch (_) {} // storage blocked: reload anyway
  }
  _reload();
}

/// The build the page was last reloaded for in this browser tab.
String? reloadedFor() {
  try {
    return _get(_key.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}
