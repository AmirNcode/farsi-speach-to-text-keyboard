# Testing Strategy

## Principles
- TDD for pure logic (mapping, encoding params, request building, validation).
- Integration-test the backend against real sample audio.
- A manual on-device plan for the things tests can't cover (real mic, Full Access, RTL feel).

## Backend (automated)
- **Integration:** Vitest + Miniflare. Use a short **Farsi** clip and a short **English** clip → assert:
  - response is `200` with non-empty `text`
  - `language` is detected correctly (`fa` / `en`)
- **Unit:** provider interface selection; `X-App-Token` validation (401 on bad/missing); size cap (413).
- Keep sample audio clips in `/backend/test/fixtures/`.

## iOS (automated)
- **Flick→digit mapping:** pure function, both languages, all 10 positions.
- **Digit style:** match-layout / force-Western / force-Persian.
- **Audio encoding:** asserts 16kHz mono / m4a params.
- **Network client:** mocked Worker responses (success, 401, 413, 502, offline).

## iOS (manual on-device test plan)
Run on a real iPhone (Simulator can't fully prove mic/Full Access):
1. Install keyboard; enable Full Access.
2. **EN dictation:** tap mic, speak an English sentence, Stop → correct text inserted at cursor.
3. **FA dictation:** switch to FA layout, speak Farsi → accurate Farsi text inserted.
4. **Language fallback:** on FA layout, speak English → auto-detect still yields English.
5. **Flick numbers:** EN flick `Q…P` → `1…0`; FA flick top row → `۱…۰`.
6. **60s cap:** recording auto-stops at 60s.
7. **Errors:** airplane mode → mic shows "No connection — try again", nothing dropped.
8. **RTL:** Farsi text inserts and edits correctly in RTL fields.
9. **(If D14 in) Emoji:** emoji keyboard opens and inserts.

## Definition of done (v1)
- All automated tests green.
- Manual plan passes on a real device.
- Farsi accuracy judged "good enough" by the owner on everyday phrases.
