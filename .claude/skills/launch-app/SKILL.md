---
name: launch-app
description: Build and run the Adapt Flutter app in a browser (web target), optionally take phone-sized screenshots with Playwright. Use when asked to run, start, preview or screenshot the app.
---

# Launch the app

1. Make sure Flutter is available: `scripts/setup_flutter.sh` (installs the pinned SDK to `~/flutter` if missing), then `export PATH="$HOME/flutter/bin:/opt/flutter/bin:$PATH"`.
2. Start it in the background: `scripts/run_web.sh` (release build, serves `build/web` on port 8080). For hot reload use `scripts/run_web.sh --dev`.
3. Open http://localhost:8080. On a local machine, the user can open that URL directly in a browser.

## Screenshots (cloud sessions / headless)

Flutter web draws to a canvas, so drive it with mouse coordinates at a 390x844 viewport:

```js
const { chromium } = require('playwright');
const b = await chromium.launch();
const p = await (await b.newContext({ viewport: { width: 390, height: 844 }, locale: 'ko-KR' })).newPage();
await p.goto('http://localhost:8080', { waitUntil: 'networkidle' });
await p.waitForTimeout(4000);
```

Useful coordinates on the welcome screen: consent checkbox (44, 545), "sample data" link (195, 807).
Bottom nav tabs at y=812: Today x=49, Trend x=146, Check-in x=244, Settings x=341.

The "sample data" button fills 5 weeks of history, so the weekly check-in is immediately due.
