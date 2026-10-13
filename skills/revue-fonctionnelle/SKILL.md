---
name: revue-fonctionnelle
description: Record a real screen video of a frontend feature for the functional analyst ("revue fonctionnelle") — drives the locally running Priorx app through chrome-devtools, records the tab with getDisplayMedia + MediaRecorder, shows a drawn cursor, French step captions and highlights, fits the whole page in frame, and saves a seekable .webm. Use when asked to "record the functional review", "screen record the feature", "make a video for the analyst", "refais la vidéo de revue fonctionnelle", or to prove each acceptance criterion visually.
---

# Functional review video

A video the analyst watches to confirm each intention of the ticket is coded. It shows the real app, every
step happening on screen, and nothing else.

Supporting files (in `scripts/` next to this file):

- `page-helpers.js`: paste into `evaluate_script` once. It sets up the cursor, captions, highlights, zoom, fit, the recorder and export, plus an `__api` helper that uses the page's own session.
- `decode-b64.mjs`: turns the exported JSON into a `.webm`.
- `fix-duration.mjs`: adds the missing WebM Duration so the video can be scrubbed.

## Style the user asked for (do not regress)

- **Every step happens on screen:** clicking the list row, switching tabs, typing the value, picking from the dropdown. Navigate by clicking in the app, never through hidden jumps.
- **No section title cards, intro cards or checklist cards.** One short **French** caption per step, top right, static, no fade.
- **Minimal animation:** no smooth scrolling and no fades. Use a single orange box on the value to check, and clear it before the next step. The only motion is the cursor gliding (~0.45 s) to its next target.
- **Visible cursor** before every click and every typing step.
- **Whole page in frame:** never cut off the value being checked. Zoom out rather than scroll.

## Workflow

1. **Preconditions**
   - **Instance:** `priorx-launchpad` `instance_status` must report `up` and `ready`.
   - **MFE:** `service_status fe:<mfe>` must report `mode: local` and `health: ok`. Otherwise run `start_service`, because the twin serves the image, not your branch.
   - **Login:** open the page with chrome-devtools. If it redirects to Auth0, ask the user to log in. **Never type credentials.**
2. **Pick the data.**
   - **Which records:** use `__api` (or the page's network requests) to find records that exercise each acceptance criterion. Before recording, check the values the screens will show.
   - **Missing case:** if the sandbox lacks one, create **temporary** data through the API (e.g. a code `TMP<ticket>`).
   - **Restore list:** note every change you make so you can undo it.
3. **Load the helpers.**
   - **Configure:** edit `API_BASE` and `MFE_FIXES` in `page-helpers.js`.
   - **Inject:** paste it into `evaluate_script` with `waitForStableDom: false`.
   - **Navigate in-app from then on:** a full reload wipes the helpers.
4. **Start sharing.** `take_snapshot`, then `click` the `start-rec` button. Ask the user to click **Share / Partager** in Chrome, and wait until they confirm.
5. **Fit the page *after* sharing starts.**
   - **Why after:** Chrome's "sharing this tab" bar takes ~58 px off the viewport (`innerHeight` 674 → 616 on this laptop).
   - **Measure:** walk the tallest screen once without recording, e.g. the simulator with a product selected. `__setZoom(z)` and check that the last relevant element's `getBoundingClientRect().bottom < innerHeight - 20`. 0.62 fit fee-matrix.
   - **Capture size:** `applyConstraints({width:{max:W},height:{max:H}})` with the tab's physical size (1920×770 here). Don't upscale.
6. **Record.**
   - **Start:** `__newRecorder()`.
   - **Scripted steps** (one `evaluate_script` each): `__caption(...)`, `__moveTo(el)`, `__hl(el)`, then `__sleep(4000)` on the value to check, then `__hlClear()`.
   - **MUI Autocomplete:** typing and picking an option must be **real** input. Call `__moveTo(input)`, then DevTools `click` (snapshot uid) + `type_text`, wait for the option, call `__moveTo(option)`, then DevTools `click` its uid. Scripted `.click()` on the option does **not** select it.
   - **Buttons that ignore scripted clicks** (e.g. "Return to code list"): `__moveTo` first, then DevTools `click`.
   - **A taller screen** (e.g. more result rows): `await __fit(() => lastEl)` on that screen only.
7. **Stop and export.**
   - **Stop:** `__stopRec()`.
   - **Export:** `evaluate_script` with `filePath: <scratchpad>/live-b64.json` returning `__exportB64()`.
   - **Decode:** `node decode-b64.mjs live-b64.json raw.webm`.
8. **Fix duration.**
   - **Read it:** open `file:///…/raw.webm` in a chrome-devtools page, set `v.currentTime = 1e9`, wait ~3 s, then read `v.duration`.
   - **Write it:** `node fix-duration.mjs raw.webm <final>.webm <ms>`.
9. **Verify before reporting.**
   - **Duration:** reload the final file and check `duration` comes from the metadata.
   - **Key frames:** seek to the result screen of each case and `take_screenshot`. The checked value, its caption and its box must all be visible.
   - **Frame size:** check `videoWidth/videoHeight` is constant across several timestamps.
10. **Restore the sandbox.**
    - **Undo:** reverse every data change, then re-read it from the API to prove it matches the starting state.
    - **Report leftovers:** say what remains (e.g. soft-deleted temp codes visible under "show inactive").
11. **Save durably:** `D:\tmp\<TICKET>\<TICKET>-revue-fonctionnelle.webm`, **not** the session scratchpad (Windows temp gets cleaned). Keep the previous take as `-v1` instead of overwriting it.

## Things that do not work (tried, failed)

- **Launchpad MCP:** it can't record.
- **chrome-devtools:** it can't record either. Its performance-trace filmstrip is ~500 px wide, too small to read.
- **Playwright with copied session tokens:** blocked by tool policy (credential exfiltration). Record inside the logged-in tab instead.
- **`emulate` viewport (e.g. 1920×1160):** tab capture records the *real* window, so the video shows only the top-left corner. Its effect can also linger on the page. Open a fresh tab with `new_page` if you used it.
- **Fullscreen** (`requestFullscreen`) gave a stranger, smaller viewport. Use CSS zoom instead.
- **Zoom on `body`:** the MFE kept its old size. Zoom on `<html>` and override containers sized with `100vw` or a fixed `max-height` (`MFE_FIXES`). Dispatch `resize` afterwards.
- **Overlays under zoom:** they get zoomed too. Divide positions and sizes by `Z`; the helpers already do.
- **`applyConstraints` with `crop-and-scale`** to an aspect ratio that doesn't match crops the frame. Match the tab's real aspect.
- **Playwright's bundled ffmpeg** is stripped: it can't remux or cut. Hence `fix-duration.mjs`, and no trimming of idle pauses.
- **A slideshow of screenshots on a canvas:** the user rejected it. They want the real interaction.

## Report to the user

- **Location:** where the file is, its length and resolution.
- **Steps:** what each step shows, as a numbered list.
- **Off-screen steps:** anything not shown on screen (e.g. temp data created through the API), stated plainly.
- **Sandbox:** its state after restore.
- **Anomalies:** anything odd you noticed in the app (e.g. duplicated rows). Report it without fixing it.
