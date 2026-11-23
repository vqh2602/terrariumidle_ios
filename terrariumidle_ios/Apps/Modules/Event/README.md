# Event WebView

`EventView` loads the remote `event_terrarium.json` feed. Cards use the device language, falling back to English, and show the feed in reverse order. Start/end dates are inclusive. Expired, upcoming, and version-incompatible events remain visible but cannot open.

The three legacy links map to the existing hosted pages:

| Feed link | Page | JavaScript handler |
| --- | --- | --- |
| `clam-level-up` | `event_level_terrarium/index.html` | `event_get_bag_level` |
| `clam-floor` | `events_floors/index.html` | `event_get_bag_floor` |
| `clam-lavender-plant` | `lucky-wheel/index.html` | `clam-lavender-plant` |

HTTPS links open in WKWebView without reward handlers. Links to another host open externally.

The app exposes `window.TerrariumBridge`. The website must use this API:

```javascript
await window.TerrariumBridge.callHandler('event_get_bag_level', 'true');
await window.TerrariumBridge.callHandler('event_get_bag_floor', 'true');
await window.TerrariumBridge.callHandler('clam-lavender-plant', {code: 'ticket'});
```

The app dispatches `TerrariumBridgeReady` when the bridge is installed. The previous `window.flutter_inappwebview` API is no longer exposed; hosted pages must migrate before reward callbacks work on iOS.

The bridge returns a Promise and accepts calls only from the matching main-frame HTTPS host, page path, and event handler. Native checks enforce dates, app version, logged-in user, level/floor requirements, existing ownership, and oxygen balance. Reward amounts and supported codes are defined in `EventReward`, matching the current wheel reward amounts. Arbitrary quantities from JavaScript are ignored. The wheel costs 100 oxygen per accepted reward callback.

Firestore must confirm the write before the Promise resolves and local state is published. Failures reject the Promise and show a native status message. Successful claims update the page's query parameters and wheel oxygen value. Badge claims are deduplicated by ownership; concurrent claims and wheel callbacks within two seconds of a completed claim are rejected.

The existing web page selects wheel outcomes on the client. This bridge preserves that contract; it does not provide server-authoritative prize selection or cross-device claim transactions. Changes to the hosted prize catalog must also update the native reward policy.
