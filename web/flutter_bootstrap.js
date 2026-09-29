{{flutter_js}}
{{flutter_build_config}}
// No service worker: it only cached old builds (see the Pages workflow's
// cache-busting), and reminders are app notifications, not web pushes.
_flutter.loader.load();
