'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "365f1315f2d0f5297476947da285b497",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"manifest.json": "2d705a3681c90eed445e8a5c234ce4dd",
"version.json": "96505a44f2a354fc6595fd81103778f4",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"main.dart.js": "4699614dbf1638b6de7990b4edd480a9",
"index.html": "c705a8460e1a3da6cb5b21f16e8c96b4",
"/": "c705a8460e1a3da6cb5b21f16e8c96b4",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/getwidget/icons/slack.png": "19155b848beeb39c1ffcf743608e2fde",
"assets/packages/getwidget/icons/google.png": "596c5544c21e9d6cb02b0768f60f589a",
"assets/packages/getwidget/icons/dribble.png": "1e36936e4411f32b0e28fd8335495647",
"assets/packages/getwidget/icons/youtube.png": "1bfda73ab724ad40eb8601f1e7dbc1b9",
"assets/packages/getwidget/icons/pinterest.png": "d52ccb1e2a8277e4c37b27b234c9f931",
"assets/packages/getwidget/icons/whatsapp.png": "30632e569686a4b84cc68169fb9ce2e1",
"assets/packages/getwidget/icons/twitter.png": "caee56343a870ebd76a090642d838139",
"assets/packages/getwidget/icons/wechat.png": "ba10e8b2421bde565e50dfabc202feb7",
"assets/packages/getwidget/icons/linkedin.png": "822742104a63a720313f6a14d3134f61",
"assets/packages/getwidget/icons/line.png": "da8d1b531d8189396d68dfcd8cb37a79",
"assets/packages/getwidget/icons/facebook.png": "293dc099a89c74ae34a028b1ecd2c1f0",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/NOTICES": "6dcd56eed620d938e5e29459d7d9dde4",
"assets/AssetManifest.json": "78a0a774f06e9a8ef941d1fc37bac6f9",
"assets/AssetManifest.bin": "4b120793b220907a6ce9b3bfdd44d736",
"assets/AssetManifest.bin.json": "b2febf57b0ff1c9a5f2caea984d1a760",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/fonts/MaterialIcons-Regular.otf": "1f3e32494750cb8b74da4d5bd46637bc",
"assets/assets/mock/GET_districts_pathParams.json": "5cca149e56c8e631d238a5904bf6a11a",
"assets/assets/mock/GET_authorities_queryParams.json": "c55677bcaf8b0da284a89b8e12f7906d",
"assets/assets/mock/POST_authenticate_verify_otp.json": "adc816f81b7890aabb21de6bc78f5394",
"assets/assets/mock/POST_account_reset_password_init.json": "df5fa5686cdf4a05b36ef18d0a878d8c",
"assets/assets/mock/POST_account.json": "2911acfc2d1c5a9153b9da3094dd64d8",
"assets/assets/mock/POST_authenticate_send_otp.json": "22e67cc3ae278cb47bca0058382d3330",
"assets/assets/mock/POST_account_change-password.json": "d93801af044833f1d393f38e3348456e",
"assets/assets/mock/GET_customer.json": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/mock/menus.json": "ffb09cef1a6ca0c540b1e6612998d9c7",
"assets/assets/mock/POST_admin_users.json": "2911acfc2d1c5a9153b9da3094dd64d8",
"assets/assets/mock/GET_admin_users.json": "f846bd16784da106d3cd3b5dbf327f8d",
"assets/assets/mock/GET_admin_users_list_queryParams.json": "1750cb4d6799cca9017d640b1d425249",
"assets/assets/mock/GET_authorities.json": "c55677bcaf8b0da284a89b8e12f7906d",
"assets/assets/mock/GET_districts_queryParams.json": "7662179144bee9bc05a86fcdd4ef22c6",
"assets/assets/mock/GET_account.json": "f846bd16784da106d3cd3b5dbf327f8d",
"assets/assets/mock/GET_districts_cities_pathParams.json": "7662179144bee9bc05a86fcdd4ef22c6",
"assets/assets/mock/GET_districs.json": "7662179144bee9bc05a86fcdd4ef22c6",
"assets/assets/mock/POST_register.json": "91c693ce607706457d3af8fefa79826f",
"assets/assets/mock/menu.json": "d37cde48d985c130f97143eb63738c68",
"assets/assets/mock/dashboard.json": "e8502cd5804a17c23528401b2bf61cc5",
"assets/assets/mock/PUT_admin_users.json": "2911acfc2d1c5a9153b9da3094dd64d8",
"assets/assets/mock/GET_cities_pathParams.json": "bfae2aebfbc795f664397608cf136784",
"assets/assets/mock/GET_cities_queryParams.json": "4477d808a9da9214d66fee23ec406fbe",
"assets/assets/mock/GET_admin_users_filter_queryParams.json": "1750cb4d6799cca9017d640b1d425249",
"assets/assets/mock/GET_cities.json": "4477d808a9da9214d66fee23ec406fbe",
"assets/assets/mock/GET_admin_users_queryParams.json": "97985e084b3ab74e8e5e45d7f0ff7493",
"assets/assets/mock/POST_cities.json": "bfae2aebfbc795f664397608cf136784",
"assets/assets/mock/GET_admin_users_pathParams.json": "2911acfc2d1c5a9153b9da3094dd64d8",
"assets/assets/mock/GET_authorities_pathParams.json": "0b4da8652f404a920960eecb2aeae293",
"assets/assets/mock/GET_admin_users_list.json": "1750cb4d6799cca9017d640b1d425249",
"assets/assets/mock/POST_districts.json": "5cca149e56c8e631d238a5904bf6a11a",
"assets/assets/mock/GET_admin_users_authorities_pathParams.json": "1750cb4d6799cca9017d640b1d425249",
"assets/assets/mock/POST_authorities.json": "39f85c5216f47be21c1274e6ac916881",
"assets/assets/mock/users.json": "25d8b31a6b41aa6fb5023a07ee08b322",
"assets/assets/mock/POST_authenticate.json": "adc816f81b7890aabb21de6bc78f5394",
"assets/assets/mock/PUT_account.json": "de35700c7c0e1336e46cb3e933cb4016",
"assets/assets/images/logoLight.png": "eb1f2c6d4f21b7c4a1382664d3b5dd19",
"assets/assets/images/assets.md": "26983f7094ee9e2e99401338d27b8ec0",
"assets/assets/images/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"assets/assets/images/img.png": "eb1f2c6d4f21b7c4a1382664d3b5dd19"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
