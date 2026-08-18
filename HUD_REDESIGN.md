# Right-pane HUD redesign

Working notes for replacing the grey `CharacterWindowBackground` with the
wooden pane art. Measurements taken from `newInventory.png` (898x1752), cropped
to the artwork bbox `(64,26) 763x1656` and scaled to a 600px design height.

**Resulting pane: 276 x 600 design px** (currently 200 x 600).

## Art spec for the clean plate

Same composition and framing as the mockup — if the layout shifts, the
measurements below have to be retaken.

Remove everything the live UI draws:

| Bake into the art | Draw live (must be absent from the art) |
| --- | --- |
| Wooden frame, vines, lantern, corner bolts | The minimap image |
| Minimap window (empty dark interior) | Character name ("Goat") and class icon |
| Empty bar tracks/grooves | Bar fills and their text (`21/150`, `770/770`, `252/252`) |
| Empty slot recesses | Items, tier tags (`UT`, `TO`), slot numerals `3`-`8` |
| Tab row backing | Tab icons and the selected-tab highlight |
| Potion pip icons | Potion counts (`0/6`) |
| Bottom clasp | |

Notes:

- **Background**: keep the surround pure black. It gets keyed to transparency
  on import (anything with luma < 12), which lets the vines and lantern hang
  over the play area instead of sitting on a hard rectangle.
- **Size**: any resolution is fine, it gets area-averaged down to 276x600.
  Bigger than 2x the target is ideal.
- **Empty slots must have no numerals** — the client draws slot numbers itself,
  and baked ones would double up under items.

## Measured geometry (design px, origin = pane top-left)

| Element | x | y | w | h |
| --- | --- | --- | --- | --- |
| Minimap window | 30 | 21 | 202 | 180 |
| Name row | - | 206 | - | 35 |
| Fame bar | - | 245 | - | 18 |
| HP bar | - | 267 | - | 23 |
| MP bar | - | 290 | - | 21 |
| Equipment row | 34 | 316 | 211 | 57 |
| Tab row | - | 377 | - | 31 |
| Inventory row 1 | 34 | 412 | 211 | 49 |
| Inventory row 2 | 34 | 465 | 211 | 53 |
| Potion counters | - | 522 | - | 31 |

Item slots: first at x 34, tile ~48, pitch ~53 (so ~4-5px padding), 4 columns.

## Why this design unblocks item sizing

The old pane could not go past 43px tiles: the inventory tab had only 126px of
content height (`TabStripView` 153 minus 27 of tab buttons) to fit two tile rows
plus the potion row, and the strip itself was boxed between y=346 and the
interact panel at y=500. This art re-proportions the whole pane, giving the
inventory rows ~106px and landing tiles at 48px naturally.

## Implementation order

1. Import the clean plate, key black to alpha, scale to 276x600, embed it.
2. `CharacterWindowBackground` draws the bitmap instead of `drawRect`.
3. Set `UiMetrics.HUD_WIDTH = 276` and the vertical constants from the table.
   Camera offset and chat box width follow automatically.
4. `ItemTile.drawBackground` stops painting its grey rounded rect so the wooden
   recesses show through; keep the hover/selection highlight.
5. Restyle bars (`StatMetersView`, `CharacterDetailsView`) to fill the baked
   tracks, and the tab strip to sit in the baked tab row.
6. Set `ITEM_TILE_SIZE = 48`, `ITEM_GRID_PADDING = 5`, `ITEM_ICON_SIZE = 120`.

Steps 4-6 need visual iteration — screenshots after each pass.
