# iOS Keyboard — Implementation Notes

## Targets
- **App target** (SwiftUI) — onboarding + settings. Hosts the App Group.
- **Keyboard extension target** (`UIInputViewController` subclass, via KeyboardKit) — the keyboard itself.
- **App Group** — `group.<bundleid>` shared `UserDefaults` for settings (digit style, default language).

## KeyboardKit (free core only)
- Use the open-source core for: key rendering, the **callout/gesture system** (powers flick-down), the **dynamic layout engine**, key feedback/haptics, and the **emoji keyboard** (D14).
- Do **not** use Pro features (prebuilt locales/Persian layout, themes, autocomplete) — those are paid. We define EN/FA layouts ourselves.
- **Fallback (approach B):** if the free core can't cleanly do RTL + flick callouts, build the keyboard from scratch in SwiftUI/UIKit. Decide during Spike #1.

## Layouts
### English (QWERTY)
```
Row1: Q W E R T Y U I O P
Row2: A S D F G H J K L
Row3: ⇧ Z X C V B N M ⌫
Row4: 123  🌐  mic  space  return
```
### Farsi (standard Persian, RTL)
```
Row1: ض ص ث ق ف غ ع ه خ ح
Row2: ج چ پ ش س ی ب ل ا ت ن م ک گ   (standard Persian second/third rows; render RTL)
Row3: ⇧ ظ ط ز ر ذ د ئ و ⌫
Row4: ۱۲۳  🌐  mic  space  return
```
> Use the standard iOS Persian layout as the reference for exact key order; render right-to-left. (Confirm exact key matrix against the iOS Persian keyboard during implementation.)

## Flick-down numbers
- **Tap** top-row key = letter. **Flick down** = number.
- Implement via KeyboardKit callout/gesture actions on the 10 top-row keys.
- Positional mapping:
  - EN: `Q W E R T Y U I O P` → `1 2 3 4 5 6 7 8 9 0`
  - FA: `ض ص ث ق ف غ ع ه خ ح` → `۱ ۲ ۳ ۴ ۵ ۶ ۷ ۸ ۹ ۰`
- Show a small grey number hint on each top-row key.
- Digit style follows active layout (D9); a settings toggle can force Western/Persian.
- **Unit-test** the flick→digit mapping (pure function, language-aware).

## Voice capture
- Mic key in Row4. Tap → start; overlay shows live waveform + timer + **Stop**.
- Capture with `AVAudioEngine` (or `AVAudioRecorder`), **16kHz mono**, encode **m4a/AAC**.
- Hard cap **60s** (auto-stop).
- Requires **Full Access**; if not enabled, mic is disabled and onboarding prompts the user.
- POST to the Worker (see `backend.md`), then insert returned text at the cursor via the text document proxy.
- **Unit-test** encoding params + the (mocked) network client; **manually test** real mic on device.

## Settings (App Group)
- Default language (EN/FA) for the keyboard on launch.
- Digit style (match layout / always Western / always Persian).
- About + privacy disclosure.

## Known iOS gotchas
- Keyboard extensions can't use Apple's built-in dictation — that's why we run our own.
- ~60MB memory ceiling — don't load models/large assets in the extension.
- Mic-in-extension requires Full Access and must be validated on a real device (Spike #1).
- RTL: ensure cursor/insertion behaves correctly in RTL host fields (system handles most; verify).

## What needs the owner's Mac / device (not doable from the AI environment)
- Building/running in Xcode, enabling the keyboard in iOS Settings, granting Full Access, real-mic testing, and (later) TestFlight/App Store. Step-by-step lives in `setup-prerequisites.md` and the on-device test plan in `testing.md`.
