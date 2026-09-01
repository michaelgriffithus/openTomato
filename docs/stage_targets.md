# Tomato stage targets

Built-in defaults used when a grow space has no override for the current stage.
Ideal bands are user-overridable per grow space; safety bands are app-owned.
VPD is air VPD (Tetens saturation vapour pressure × (1 − RH/100)), always
recomputed from the stored temperature and humidity.

| Stage | Temp °F | RH % | VPD kPa | Safety temp °F | Safety RH % |
|---|---|---|---|---|---|
| Seedling | 70–80 | 60–75 | 0.4–0.8 | 55–90 | 40–90 |
| Vegetative | 70–82 | 55–70 | 0.8–1.2 | 55–92 | 35–90 |
| Flowering | 68–80 | 55–70 | 0.8–1.2 | 55–88 | 35–85 |
| Fruit set | 65–80 | 50–65 | 0.9–1.3 | 55–90 | 35–85 |
| Ripening | 65–78 | 50–65 | 0.9–1.3 | 50–90 | 30–85 |
| Harvesting | 60–78 | 45–65 | 0.9–1.4 | 45–92 | 30–85 |
| Fallback (no active plant) | 65–80 | 50–70 | 0.8–1.2 | 50–92 | 30–90 |

## Why these numbers

Tomatoes set fruit poorly when day temperatures pass roughly 90 °F or nights drop
below about 55 °F, because pollen viability falls off; lycopene production, which
gives ripening fruit its colour, stalls above about 85 °F. Sustained humidity above
the mid-80s encourages foliar disease, and very dry air with high temperature
drives transpiration faster than roots can supply water. The VPD windows are the
ranges greenhouse growers commonly aim for.

These are guidance, not gospel. Sources to consult and cite when adjusting:

- University of Florida IFAS Extension, greenhouse tomato production guides.
- Penn State Extension, tomato production.
- Cornell Cooperative Extension, vegetable growing guides (tomato).
- University of Arizona Controlled Environment Agriculture Center, greenhouse
  tomato VPD guidance.

Record the exact document titles and URLs here when bands are changed.
