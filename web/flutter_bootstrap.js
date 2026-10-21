{{flutter_js}}
{{flutter_build_config}}
(function () {
  var workers = navigator.serviceWorker;
  var controlled = !!(workers && workers.controller);
  var unregistered = workers
    ? workers.getRegistrations().then(function (registrations) {
        return Promise.all(registrations.map(function (r) { return r.unregister(); }));
      }).catch(function () { return []; })
    : Promise.resolve([]);
  var purged = 'caches' in window
    ? caches.keys().then(function (names) {
        return Promise.all(names.map(function (name) { return caches.delete(name); }));
      }).catch(function () { return []; })
    : Promise.resolve([]);
  if (!controlled) {
    _flutter.loader.load();
    return;
  }
  Promise.all([unregistered, purged]).then(
    function (results) {
      if (results[0].length > 0) location.reload();
      else _flutter.loader.load();
    },
    function () { _flutter.loader.load(); }
  );
})();
