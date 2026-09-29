// Shows reminder pushes sent by supabase/functions/daily-push and opens
// the app when one is tapped. Nothing is cached: the app loads normally.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(self.clients.claim()));

self.addEventListener('push', (event) => {
  let msg = { title: '알아서핏', body: '' };
  try {
    msg = { ...msg, ...event.data.json() };
  } catch (_) {}
  event.waitUntil(
    self.registration.showNotification(msg.title, {
      body: msg.body,
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      data: { url: msg.url || './' },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL(event.notification.data.url, self.registration.scope).href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((tabs) => {
      for (const tab of tabs) {
        if (tab.url.startsWith(self.registration.scope) && 'focus' in tab) return tab.focus();
      }
      return self.clients.openWindow(url);
    }),
  );
});
