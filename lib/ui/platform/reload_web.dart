import 'dart:js_interop';

@JS('location.reload')
external void _reload();

/// Reloads the web page (picks up a newly deployed build).
void reloadPage() => _reload();
