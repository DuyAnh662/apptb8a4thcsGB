importScripts('config.js');

const SUPABASE_URL = CONFIG.SUPABASE_URL;
const SUPABASE_ANON_KEY = CONFIG.SUPABASE_KEY;

self.addEventListener("install", event => {
  console.log("Service worker installed.");
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", event => {
  // Cho phép web hoạt động offline (tùy bạn muốn thêm logic gì)
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const data = event.notification.data || {};

  event.waitUntil((async () => {
    const allClients = await clients.matchAll({ includeUncontrolled: true });
    if (allClients.length > 0) {
      const client = allClients[0];
      client.focus();
      client.postMessage({ type: 'notification_click', data });
    } else {
      const url = data.url || '/';
      await clients.openWindow(url);
    }
  })());
});

self.addEventListener('notificationclose', function (event) {
  // Could be used for analytics
});

self.addEventListener('push', function (event) {
  console.log('[SW] Push received');

  event.waitUntil((async () => {
    try {
      // Try to get payload from push event first
      let title = 'Thông báo mới';
      let body = '';
      let data = {};

      if (event.data) {
        try {
          const payload = event.data.json();
          title = payload.title || title;
          body = payload.body || payload.message || '';
          data = payload.data || {};
        } catch (e) {
          // If no JSON payload, fetch from Supabase
          console.log('[SW] No payload, fetching from Supabase...');
        }
      }

      // If no body from payload, fetch latest notification from Supabase
      if (!body) {
        try {
          const response = await fetch(
            `${SUPABASE_URL}/rest/v1/notification?order=created_at.desc&limit=1`,
            {
              headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
              }
            }
          );

          if (response.ok) {
            const notifications = await response.json();
            if (notifications && notifications.length > 0) {
              const n = notifications[0];
              title = n.title || title;
              body = n.message || n.content || '';
              data = { url: n.url || '/', id: n.id };
              console.log('[SW] Fetched notification:', title);
            }
          }
        } catch (fetchError) {
          console.error('[SW] Fetch error:', fetchError);
        }
      }

      // Show notification
      await self.registration.showNotification(title, {
        body: body,
        icon: '/icons/icon-192.png',
        badge: '/icons/icon-72.png',
        data: data,
        vibrate: [100, 50, 100],
        requireInteraction: true,
      });

      console.log('[SW] Notification shown:', title);
    } catch (e) {
      console.error('[SW] Push error:', e);
      // Fallback notification
      await self.registration.showNotification('Thông báo mới', {
        body: 'Bạn có thông báo mới',
        icon: '/icons/icon-192.png',
      });
    }
  })());
});