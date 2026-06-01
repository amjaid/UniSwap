importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDQ8hxT93w_cRAr5EZ0hEXZsbd56ISdB0E',
  authDomain: 'uniswap-utm-38aea.firebaseapp.com',
  projectId: 'uniswap-utm-38aea',
  storageBucket: 'uniswap-utm-38aea.firebasestorage.app',
  messagingSenderId: '891739966810',
  appId: '1:891739966810:web:e65109298b4998f9fa7763',
  measurementId: 'G-WGJQ5XWFMB'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  if (!payload || !payload.notification) return;
  const { title, body } = payload.notification;
  self.registration.showNotification(title || 'UniSwap', {
    body: body || 'You have a new notification.'
  });
});
