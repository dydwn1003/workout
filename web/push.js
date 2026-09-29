// Web Push for reminder notifications, called from the app through
// dart:js_interop (lib/ui/platform/push_web.dart).
window.alasPush = {
  // Push works here: service workers + PushManager + Notification (iOS
  // only when the app was added to the home screen).
  supported() {
    return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  },

  // 'default' (not asked yet), 'granted' or 'denied'.
  permission() {
    return 'Notification' in window ? Notification.permission : 'denied';
  },

  // Asks for permission if needed and subscribes. Resolves to the
  // subscription as JSON ({endpoint, keys: {p256dh, auth}}), or '' when
  // the user said no.
  async subscribe(vapidPublicKey) {
    if (!this.supported()) return '';
    if (Notification.permission !== 'granted') {
      if ((await Notification.requestPermission()) !== 'granted') return '';
    }
    const reg = await navigator.serviceWorker.register('push_sw.js');
    await navigator.serviceWorker.ready;
    let sub = await reg.pushManager.getSubscription();
    if (!sub) {
      const pad = '='.repeat((4 - (vapidPublicKey.length % 4)) % 4);
      const raw = atob((vapidPublicKey + pad).replace(/-/g, '+').replace(/_/g, '/'));
      const key = Uint8Array.from(raw, (c) => c.charCodeAt(0));
      sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: key });
    }
    return JSON.stringify(sub.toJSON());
  },

  // Unsubscribes this browser. Resolves to the endpoint that was removed,
  // or '' when there was none.
  async unsubscribe() {
    if (!this.supported()) return '';
    const reg = await navigator.serviceWorker.getRegistration();
    const sub = reg && (await reg.pushManager.getSubscription());
    if (!sub) return '';
    const endpoint = sub.endpoint;
    await sub.unsubscribe();
    return endpoint;
  },
};
