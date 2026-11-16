# Network requests

AI Stylist works fully offline. This file lists **every** network request the app can make.
Any new request must be added here (D-12) before it ships.

The app never sends photos, wardrobe items, embeddings, preferences, feedback, device IDs,
analytics or crash reports. There is no account, no backend and no background networking.
All requests go through the single `httpClientProvider` (`lib/features/weather/weather_providers.dart`);
tests replace it with a fake, so tests cannot reach the network.

## 1. Live weather (opt-in)

| | |
| --- | --- |
| When | Only when the user taps **Get current weather** in the Stylist, after turning on live weather and accepting the consent dialog. Never automatic. |
| Host | `api.open-meteo.com` (HTTPS) |
| Request | `GET /v1/forecast?latitude=<lat>&longitude=<lon>&current=temperature_2m,precipitation,weather_code&timezone=UTC` |
| Data sent | The chosen city's latitude and longitude, rounded to 2 decimals (~1 km), from the bundled city list. The `User-Agent` header `AIStylist/0.1 (Flutter app)`. As with any request, the device's IP address is visible to the host. |
| Not sent | GPS or precise location (no location permission is used), city search text, any wardrobe or profile data, cookies, API keys. |
| Response used | `current.temperature_2m`, `current.precipitation`, `current.weather_code`, `current.time` |
| Caching | In memory only, 15 minutes per city. |
| Failure | Timeout (10 s), no connection, bad status or malformed data → a message, and manual weather stays usable. |
| Turning it off | Style preferences → Live weather → *Allow live weather*. Off by default. |
| Terms | Data CC BY 4.0, attributed in the app. The free API is non-commercial only (D-35). |

City search uses the bundled GeoNames list (`assets/cities/cities.json`) and sends nothing.

## 2. Optional model downloads

| | |
| --- | --- |
| When | Only when the user taps **Download** (or **Resume download**) on the On-device models screen and confirms the size dialog. |
| Host | The `https` URL in the model's entry in the bundled manifest (`assets/models/manifest.json`). The manifest currently lists **no** downloadable models, so this request cannot happen in the current build. |
| Request | `GET <url>`, with `Range: bytes=<n>-` when resuming a partial download. |
| Data sent | The `User-Agent` header `AIStylist/0.1 (Flutter app)` and the device's IP address. Nothing else. |
| Verification | Exact size and SHA-256 from the bundled manifest; a mismatch deletes the file. Files are only read as model weights, never executed (D-37). |
| Failure | The app keeps working; colour analysis is built in and every attribute can be set by hand. |

## Platform permissions

- Android: `android.permission.INTERNET` (release manifest), used only by the two requests
  above. No location, no network-state permission.
- iOS: no extra permission is needed for HTTPS requests. Not yet verified on a device (needs
  macOS).
