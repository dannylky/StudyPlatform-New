# Standalone Cantonese Vocabulary Practice - Development Notes

Last updated: 2026-10-26  
Version: v3.1.0  
Deliverable: [`index.html`](index.html)

## 1. Overview

This document records the conversion of the React/JSX source in [`react.txt`](react.txt) into a single-file, CDN-assisted HTML application that runs without an API key and without calling an AI model.

The original source was a React 18 application for Cantonese vocabulary practice. It included vocabulary cards, HanziWriter stroke animations, browser speech synthesis, chapter reading, flashcard/dictation practice, and several Gemini-powered features. The Gemini key was intentionally empty in the source, so the AI features could not work in a normal standalone environment.

The new version keeps the non-AI learning workflow and removes the AI-dependent features and all AI-related UI.

v3.1.0 hardens the existing workflow: speech callbacks use current language settings, delayed restarts cannot override Stop, HanziWriter responds to viewport changes, CDN failures produce a visible fallback, and cards, reading text, sliders, and dialogs have keyboard and screen-reader support.

### 1.1 Deliverables

| File | Description | Size |
| --- | --- | --- |
| [`index.html`](index.html) | Standalone application with embedded data and app code | 167,335 bytes |
| [`react.txt`](react.txt) | Original React source, v2.12.0, including AI code | 163,166 bytes |
| `DEVELOPMENT.md` | This development and maintenance document | see file properties |
| [`backup.ps1`](backup.ps1) | Timestamped, versioned snapshot helper | 1,541 bytes |
| `backups/` | Snapshot folders with files and `MANIFEST.json` hashes | varies |

SHA-256 of the final `index.html` as built on 2026-10-26:

```text
87314A18D57AECC057B5D96124E01363FF5AA63E745E67DF57834FB537B42572
```

The checksum will change if the HTML or embedded data is edited. Recalculate it after any edit.

## 2. Goals and Decisions

### 2.1 Goals

- Run by opening one HTML file, with no build step and no API key.
- Keep the major non-AI functions:
  - profile, subject, chapter, and UI-language switching;
  - vocabulary cards with jyutping and stroke order;
  - browser text-to-speech;
  - chapter reading in word and sentence modes;
  - flashcard practice and dictation practice;
  - card selection, range selection, random/sequence order, repeat counts, and rounds;
  - changelog and local data backup.
- Remove all calls to Gemini or any other AI service.
- Remove AI-dependent UI rather than leaving dead buttons or error messages.
- Preserve the original visual design and data as closely as possible.

### 2.2 Explicit Non-Goals

- Fully offline operation. The chosen delivery model is a single HTML file that uses CDN libraries and CDN stroke data.
- Local AI replacement features such as generated stories, generated quizzes, or generated emoji illustrations.
- New curriculum content.
- Automatic generation of chapter-practice data.
- User accounts, cloud sync, or persistence beyond the current browser session.

### 2.3 Key Decisions

1. **CDN single-file delivery.** React, ReactDOM, Tailwind, lucide-react, Babel Standalone, and HanziWriter are loaded from public CDNs. This keeps the deliverable to one HTML file.
2. **Remove AI completely.** Story generation, quiz generation, word-context generation, automatic emoji generation, and the AI error banner were deleted.
3. **Keep the non-AI chapter-practice code.** The source already had a data-driven chapter-practice modal and an empty `PRACTICE_DB`. That code remains, but the button is disabled because no practice data exists. No AI is involved.
4. **Keep browser speech synthesis.** Pronunciation uses `window.speechSynthesis`; there is no external TTS service.
5. **No persistence.** The source did not persist profile, chapter, language, speed, or practice settings, and the standalone version does not add persistence.
6. **Version bump.** The output is labelled v3.0.0 to mark the removal of AI features and the switch to a standalone build.
7. **Fail visibly.** v3.1.0 adds a dependency-free boot fallback, CDN error tracking, and a React error boundary so a failed CDN or render does not leave a blank page.
8. **Latest-value speech refs.** Language, subject, reading token, and speech sequence are stored in refs so delayed callbacks cannot act on stale render values.
9. **Accessibility without a build step.** Keyboard activation, ARIA labels, dialog focus management, focus-visible styling, and reduced-motion handling are implemented with the existing React/Tailwind runtime.

## 3. Runtime Architecture

The final file has four layers.

```text
index.html
├─ HTML head
│  ├─ meta tags and title
│  ├─ CDN scripts
│  │  ├─ Tailwind CSS Play CDN
│  │  ├─ React 18.3.1 UMD
│  │  ├─ ReactDOM 18.3.1 UMD
│  │  ├─ lucide-react 0.400.0 UMD
│  │  └─ Babel Standalone 7.25.0
│  └─ custom CSS for animation and scrollbar compatibility
├─ body
│  ├─ #root
│  ├─ noscript message
│  └─ <script type="text/babel" data-presets="react">
│     ├─ embedded data
│     ├─ helper functions
│     ├─ React components
│     ├─ App component
│     └─ ReactDOM.createRoot(...).render(<App />)
└─ end of document
```

### 3.1 CDN Dependencies

| Library | Version | URL | Purpose |
| --- | --- | --- | --- |
| React | 18.3.1 | `https://unpkg.com/react@18.3.1/umd/react.production.min.js` | UI runtime |
| ReactDOM | 18.3.1 | `https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js` | DOM renderer |
| Babel Standalone | 7.25.0 | `https://unpkg.com/@babel/standalone@7.25.0/babel.min.js` | In-browser JSX transform |
| Tailwind CSS | Play CDN | `https://cdn.tailwindcss.com` | Utility styling |
| lucide-react | 0.400.0 | `https://unpkg.com/lucide-react@0.400.0/dist/umd/lucide-react.js` | Icons |
| HanziWriter | 3.5 | `https://cdn.jsdelivr.net/npm/hanzi-writer@3.5/dist/hanzi-writer.min.js` | Stroke animation |
| HanziWriter data | CDN default | `cdn.jsdelivr.net` | Per-character stroke data |

HanziWriter is loaded lazily by `loadHanziWriter()` when the first character box mounts, rather than being included as a blocking script in the head.

### 3.2 lucide-react UMD Compatibility

The 0.400.0 UMD build of lucide-react does not use the same global names as the React UMD build. It expects a lowercase `react` global and exposes `LucideReact`, not `lucideReact`.

The final HTML bridges that mismatch with two small inline scripts:

```html
<script crossorigin src="https://unpkg.com/react@18.3.1/umd/react.production.min.js"></script>
<script>window.react = window.React;</script>
<script crossorigin src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js"></script>
<script crossorigin src="https://unpkg.com/lucide-react@0.400.0/dist/umd/lucide-react.js"></script>
<script>window.lucideReact = window.LucideReact;</script>
```

Without these aliases, lucide-react throws `Cannot read properties of undefined (reading 'forwardRef')` and the React app never mounts.

### 3.3 Browser Requirements

- A modern browser with JavaScript enabled.
- ES2020 support for optional chaining, object spread, and modern React output.
- `window.speechSynthesis` for pronunciation and reading.
- Internet access to the CDNs listed above.
- Web fonts are not required; the application uses the browser's default sans-serif and serif fonts.

### 3.4 Network and Privacy

The application makes no requests to AI endpoints. There is no API key, no `Authorization` header, and no prompt data sent to a model. The only external requests are:

- the CDN libraries listed above;
- HanziWriter character data from `cdn.jsdelivr.net`;
- Tailwind CDN's runtime style generation.

All vocabulary data, chapter text, jyutping, and UI text are embedded in the HTML.

### 3.5 Load Failure Handling

v3.1.0 adds three layers of failure handling:

1. **Boot fallback.** A dependency-free `#boot-fallback` panel is rendered outside `#root`. It shows a loading state, then a failure message with the missing CDN names and a Reload button if the app has not mounted within 15 seconds or a script error is captured.
2. **CDN tracking.** Each CDN `<script>` tag has an `onerror` handler that records the library name in `window.__cdnErrors`. Runtime exceptions are captured before mount with a capture-phase `error` listener.
3. **React error boundary.** `Root` wraps `App` in `AppErrorBoundary`. If rendering throws, the boundary shows an inline-styled error panel with the message and a Reload button. `Root` removes the boot fallback only after a successful commit.

Tailwind failure is non-blocking: the app still mounts and logs a console warning. HanziWriter is lazy-loaded, so its failure leaves the plain character fallback visible rather than blocking the app.

## 4. Data Model

All original learning data is preserved in the final HTML.

### 4.1 Profiles

| Profile | Chapters |
| --- | --- |
| User | None |
| Tony | 5 |
| Sofia | 5 |

### 4.2 Chapters

There are 10 chapter records and 223 vocabulary records in total.

| Profile | Subject | Chapter ID | Title | Content | Vocabulary records |
| --- | --- | --- | --- | --- | --- |
| Tony | Chinese | `tony_zh_exam_1` | Exam 1 (12 Nov) | None | 30 |
| Tony | Chinese | `tony_zh_dictation_1_unit_1_2` | Dictation 1 - Unit 1 & 2 | Present | 16 |
| Tony | Chinese | `tony_zh_dictation_3_ch11` | Dictation 3 - Chapter 11 | Present | 17 |
| Tony | English | `tony_en_dictation_1_unit_1_2` | Dictation 1 - Unit 1 & 2 | Present | 15 |
| Tony | English | `tony_en_dictation_2_unit_3` | Dictation 2 - Unit 3 (27 Oct) | None | 26 |
| Sofia | English | `sofia_en_dictation_1_unit_1` | Dictation 1 - Unit 1 | Present | 20 |
| Sofia | English | `sofia_en_dictation_2_unit_3` | Dictation 2 - Unit 3 (26-29 Oct) | None | 27 |
| Sofia | Chinese | `sofia_zh_exam_1` | Exam 1 (12 Nov) | None | 41 |
| Sofia | Chinese | `sofia_zh_dictation_1_unit_1_2` | Dictation 1 - Unit 1 & 2 | Placeholder text | 15 |
| Sofia | Chinese | `sofia_zh_dictation_3_ch19` | Dictation 3 - Chapter 19 | Present | 16 |

Notes:

- `sofia_zh_dictation_1_unit_1_2` contains a placeholder instruction rather than the actual dictation paragraph.
- Four chapters have no reading text. The reading button shows a toast instead of silently doing nothing.
- Vocabulary counts include both single words and full-sentence entries.

### 4.3 Vocabulary Record Shape

```js
{
  word: '好動',
  translation: 'active',
  chars: [
    { c: '好', p: 'hou3' },
    { c: '動', p: 'dung6' }
  ]
}
```

- `word` is the Chinese word or English phrase/sentence.
- `translation` is the English or Chinese meaning, depending on the subject.
- `chars` is used for Chinese character stroke boxes and jyutping.
- Sentence entries use `chars: []` and render as text instead of character boxes.

### 4.4 Other Data Structures

| Constant | Purpose |
| --- | --- |
| `UI_TEXT` | UI labels in Cantonese, Simplified Chinese, and English |
| `PROFILES` | User, Tony, Sofia |
| `CHANGELOG_DATA` | In-app changelog, including the v3.0.0 entry |
| `HOMOPHONE_DB` | Homophone hints for reading-mode word clicks |
| `CHAPTERS` | Profile, subject, title, and reading content |
| `VOCABULARY_DB` | Vocabulary records keyed by chapter ID |
| `PRACTICE_DB` | Data-driven chapter-practice content; currently `{}` |

## 5. Features Retained

### 5.1 Navigation and Settings

- Profile switching.
- Subject switching: Chinese, English, General Studies.
- Chapter selection.
- UI language switching: Cantonese, Mandarin, English.
- Speech-speed slider from 0.2x to 1.5x.
- Changelog modal.

The General Studies subject and the User profile have no chapters in the embedded data, so they show an empty state. This matches the source data.

### 5.2 Vocabulary Cards

- Responsive grid layout.
- Chinese character stroke boxes with jyutping above each character.
- Translation or word text in the card footer.
- Click anywhere on a card to pronounce it.
- Card-number badge to select or deselect a card for practice.
- Dictation mode hides card content and translation until the reveal phase.
- Active card highlighting and countdown badge during practice.
- v3.1.0: each card is a keyboard-focusable button (`Enter`/`Space`) with an accessible label that hides the word during dictation. The number badge is a real `<button>` with `aria-pressed`; its label includes the card number.

The AI-generated decorative emoji illustration and the per-card AI sparkle button were removed. The card layout was rebalanced to work without the decorative image area.

### 5.3 Stroke Order

- HanziWriter 3.5 is lazy-loaded from jsDelivr.
- Each Chinese character gets its own writer instance.
- Characters animate when the card is pronounced.
- Responsive box sizes: 44 px on small screens, up to 88 px on large screens.
- If character data fails to load, the plain character remains visible as a fallback.
- Animation speed reads the global `window.__speechSpeed` value when the writer is created.
- v3.1.0: breakpoint changes call `writer.updateDimensions()` instead of leaving a fixed-size SVG.
- v3.1.0: unmount/cleanup cancels quizzes, pauses animations, clears the container, and cancels the staggered animation timer.
- v3.1.0: the lazy loader resets its cached promise after a script failure so a later mount can retry.
- Stroke animation and particles are skipped when `prefers-reduced-motion: reduce` is active.

### 5.4 Speech Synthesis

- Uses only the browser's `window.speechSynthesis` API.
- No external speech service, key, or model.
- Female-sounding voices are preferred when available.
- Voice selection:
  - English subject or English card pronunciation: English voices.
  - Cantonese UI: Cantonese/zh-HK voices, then any Chinese voice.
  - Mandarin UI: zh-CN/zh-TW or Mandarin voices, then any Chinese voice.
  - English UI with Chinese content: Chinese voices for chapter reading.
- If Cantonese is unavailable, the application falls back to another Chinese voice instead of failing silently.
- The speech-rate slider affects chapter reading and chapter-practice read-aloud. Card pronunciation and flashcard/dictation narration use 1.0x, matching the source behavior.
- If `speechSynthesis` is unavailable, the application shows a toast. Starting chapter reading or flashcard practice is blocked with the same message.
- v3.1.0: `languageRef` and `subjectRef` make delayed speech callbacks use the latest settings. A speech sequence token prevents an older utterance from clearing a newer card highlight.
- v3.1.0: a reading token invalidates the 50 ms restart timer, so Stop always wins over a pending speed-change or chapter-start restart.
- v3.1.0: speech timers are cleared on stop, restart, and unmount. Clicking a card while chapter reading is active stops the reading session instead of racing the next sentence.
- v3.1.0: voice-change listening uses `addEventListener`/`removeEventListener` instead of overwriting `onvoiceschanged`.

### 5.5 Chapter Reading

- Opens the selected chapter's content in a dedicated reading panel.
- Word mode:
  - Segments Chinese text with `Intl.Segmenter('zh-Hant')` when available.
  - Falls back to per-character segmentation.
  - Clicking a word pronounces it and can show a homophone tooltip.
- Sentence mode:
  - Clicking a sentence pronounces the whole sentence.
- Reading controls:
  - play/restart;
  - pause/resume;
  - stop;
  - close;
  - repeat count from 1 to 100.
- Current sentence and current word highlighting.
- Automatic scrolling to the active sentence; instant scrolling under reduced motion.
- Floating bottom control bar while reading is active.
- Empty chapters show `此章節暫未提供課文內容。` instead of doing nothing.
- v3.1.0: sentences and words are keyboard-activatable (`Enter`/`Space`) with button semantics, and the reading panel is a labelled region.
- v3.1.0: changing speed mid-read restarts the current chunk with the current language and subject, not the values captured at first render.
- v3.1.0: starting flashcard practice or pronouncing a card while reading interrupts the reading session cleanly.

The sentence splitter was changed from the original regex, which treated apostrophes as delimiters and split `"We mustn't pick..."` into two chunks. The new splitter is:

```js
/[^，。！？；、：\n.!?]+[，。！？；、：\n.!?]?/g
```

It handles Chinese and English sentence punctuation without splitting contractions.

Word IDs in reading mode are now unique per sentence and word position:

```js
const wordId = `s${idx}-w${wIdx}`;
```

This avoids collisions between the same word index in different sentences.

### 5.6 Flashcard Practice

- Setup modal with:
  - standard flashcard mode or dictation mode;
  - selected-card set or a card-number range;
  - random or sequential order;
  - wait time from 1 to 45 seconds;
  - repeat count from 1 to 5;
  - session rounds from 1 to 10.
- Selected cards take priority over the range when at least one card is selected.
- Standard mode:
  - shows the countdown;
  - pronounces each word the configured number of times;
  - advances automatically.
- Dictation mode:
  - hides the card content;
  - pronounces the word repeatedly;
  - counts down;
  - reveals the card;
  - advances after a short reveal delay.
- Rounds are reshuffled when random order is selected.
- Floating progress bar shows current card, round, and a stop button.
- The active card is scrolled into view.

Starting practice requires the speech-synthesis API. This is deliberate: both practice modes depend on audio, so the application shows a toast instead of starting a silent session.

### 5.7 Chapter Practice

- The original chapter-practice modal remains in the code.
- It supports the original `concept_map` and `mixed_qa` data shapes, including multiple-choice questions, free-text answers, per-question reveals, suggested answers, and read-aloud buttons.
- `PRACTICE_DB` is empty in the embedded data, so the `章節練習` button is disabled on every chapter. This is the same effective behavior as the source.
- No AI is used for chapter practice.

### 5.8 Changelog and Data Backup

- Changelog modal with month tabs.
- The v3.1.0 entry documents the speech, resilience, and accessibility changes. The v3.0.0 entry documents the standalone conversion and AI removal.
- The download button exports the current data as JavaScript:
  - profiles;
  - changelog;
  - vocabulary database;
  - chapters;
  - practice database.
- The download filename is `Cantonese_Vocab_App_Data_v3.1.0.js`.
- This is a data backup, not a copy of the full HTML application.

### 5.9 Visual, Interaction, and Accessibility Details

- Responsive Tailwind layout.
- Particle effects on card and reading clicks, skipped under reduced motion.
- Toast messages for download, missing chapter content, and missing speech support. The toast is a polite live region.
- Custom CSS for animation classes that are normally provided by `tailwindcss-animate`:
  - `animate-in`
  - `fade-in`
  - `zoom-in-95`
  - `slide-in-from-*`
- Hidden-scrollbar and custom-scrollbar helpers.
- v3.1.0 adds `:focus-visible` outlines and a `prefers-reduced-motion` media query.
- v3.1.0 dialogs use `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, Escape-to-close, initial focus, a Tab focus trap, and focus restoration to the trigger.
- v3.1.0 mode buttons expose `aria-pressed`; selects and sliders have accessible names; decorative emoji and background blobs are hidden from assistive technology.
- v3.1.0 updates `document.documentElement.lang` and the localized document title when the UI language changes.

## 6. AI Features Removed

| Original feature | What was removed |
| --- | --- |
| Gemini API access | `apiKey`, `fetchGemini`, request payloads, retry delays, JSON response parsing |
| AI error handling | `apiErrorMsg`, API error banner, `t.apiError` |
| Automatic card emoji generation | emoji generation effect, `cardImages` state, `ImageOff`/`Loader2` card states, decorative emoji block |
| Per-card AI context | sparkle button, `handleWordAI`, `selectedWord`, `wordAIData`, `isGeneratingWordAI`, AI context modal |
| Random vocabulary story | story button, `handleGenerateStory`, `storyData`, `isGeneratingStory`, story panel |
| AI quiz | quiz button, `handleGenerateQuiz`, `quizData`, `isGeneratingQuiz`, `quizAnswerStatus`, `selectedOption`, quiz modal |
| AI UI text | story/quiz/context/loading/error strings in all three UI languages |
| Unused AI-era icons | `Loader2`, `ArrowRight`, `ImageOff`, and other unused imports |

Outside the changelog text that explains the removal, the app contains no AI-related code, prompts, API keys, or network calls.

## 7. Implementation Details

### 7.1 UMD Conversion

The original file began with ES module imports and ended with an exported component:

```js
import React, { useState, ... } from 'react';
import { ... } from 'lucide-react';
export default function App() { ... }
```

The standalone version uses globals and a ReactDOM root:

```js
const { useState, useEffect, useRef, useCallback, memo } = React;
const { Volume2, Sparkles, ... } = lucideReact;

function App() { ... }

class AppErrorBoundary extends React.Component { ... }

function Root() {
  useEffect(() => {
    window.__appMounted = true;
    document.getElementById('boot-fallback')?.remove();
  }, []);
  return <AppErrorBoundary><App /></AppErrorBoundary>;
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Root />);
```

Babel Standalone compiles the JSX in the browser. The script tag uses `data-presets="react"`.

### 7.2 TTS Voice Selection

`getVoiceUtterance(text, rate, forceEnglish, appLanguage)` centralizes utterance creation.

The selection order is:

1. English when `forceEnglish` is true.
2. Cantonese/yue/zh-HK for the Cantonese UI.
3. Mandarin/zh-CN/zh-TW for the Mandarin UI.
4. Any Chinese voice as a fallback.
5. Browser default if no matching voice exists.

`preferFemale` looks for known female voice names and otherwise excludes obvious male voice names.

`handlePronounce` is the central pronunciation entry point for cards, reading words/sentences, practice narration, and chapter-practice read buttons. It:

- interrupts chapter reading if one is active;
- increments a speech sequence token and cancels any current speech;
- waits 50 ms in a tracked timer before speaking to avoid Chrome cancel/speak races;
- reads `languageRef.current` and `subjectRef.current`, so delayed callbacks use the latest UI settings;
- applies `speedRef.current` when `isContentReading` is true;
- sets the active-card state only when its sequence token is still current;
- calls an optional completion callback exactly once, which practice uses to sequence repeated words.

Card pronunciation and flashcard/dictation narration use 1.0x. Chapter reading and chapter-practice read-aloud use the slider value.

### 7.3 Reading Engine

`handleReadChapter`:

1. Finds the current chapter.
2. Shows a toast if the chapter has no content.
3. Shows a toast if speech synthesis is unavailable.
4. Splits the content into sentence chunks.
5. Stores the chunks in both state and a ref.
6. Resets repeat and round state.
7. Captures a reading token, cancels the previous speech, and starts the first chunk after 50 ms only if the token is still current.

`playChunk` advances through the chunks, repeats the whole chapter when requested, and stops at the end. `readSingleSentence` and `readSingleWord` allow manual clicks or keyboard activation while reading and invalidate any pending auto-start. All three use current refs for speed, language, and subject and show a localized toast if speech is unavailable. Speed changes restart the current chunk under a new reading token, so Stop or a manual interruption wins over the delayed restart.

### 7.4 Practice Engine

The practice state is a single object:

```js
{
  isActive,
  isDictation,
  revealedWords,
  originalWords,
  words,
  currentIndex,
  countdown,
  currentRound,
  totalRounds
}
```

A `useEffect` watches the active card and runs either the standard or dictation sequence. Timers are cleared on stop, card change, or unmount. `practiceTimerRef` prevents overlapping countdowns. Starting practice stops any active chapter reading, increments the speech token, and clears a pending speech timer before unlocking audio.

### 7.5 Toast Handling

A single `showToast(message, duration)` helper replaced the scattered toast code. It clears the previous timer before starting a new one and cleans up on unmount. The toast is rendered as a `role="status"` live region.

Toasts are used for:

- data backup completion;
- chapters without reading content;
- browsers without speech synthesis;
- starting practice with an empty selection.

All toast messages now come from `UI_TEXT`.

### 7.6 Data Download

`handleDownloadSource` builds a JavaScript file from the embedded constants and triggers a Blob download. It does not include the HTML shell or the React component code.

### 7.7 Accessibility Implementation

- `WordCard` uses `role="button"`, `tabIndex=0`, Enter/Space handling, and an aria label that hides the word during dictation.
- Reading sentences and segmented words are keyboard-activatable spans with button semantics.
- The modal accessibility effect stores the trigger, focuses the first control, traps Tab, closes on Escape, and restores focus on cleanup.
- `aria-pressed` is used for profile, subject, language, reading-mode, practice-type, practice-order, changelog-month, and card-selection toggles.
- Icon-only controls have `aria-label`; selects and sliders have accessible names and value text.
- The document `lang` attribute and title follow the selected UI language.
- `prefers-reduced-motion` disables particles, stroke animation, smooth scrolling, and CSS animations.

## 8. Code Map

Line numbers refer to the final `index.html` at the time of writing. They may shift after edits.

| Area | Approximate line |
| --- | --- |
| HTML head, boot fallback script, CDN scripts, CSS | 1-91 |
| Body, boot fallback panel, app script start | 92-105 |
| `APP_VERSION` | 108 |
| `loadHanziWriter` | 116 |
| `segmentChineseText` | 146 |
| `getVoiceUtterance` | 157 |
| `UI_TEXT` | 207 |
| `PROFILES` | 213 |
| `CHANGELOG_DATA` | 219 |
| `HOMOPHONE_DB` | 236 |
| `CHAPTERS` | 240 |
| `VOCABULARY_DB` | 258 |
| `PRACTICE_DB` | 504 |
| `BlankInput` | 510 |
| `SectionSeparator` | 540 |
| `getSeparatorConfig` | 550 |
| `CharacterBox` | 607 |
| `WordCard` | 704 |
| `App` | 773 |
| `handleDownloadSource` | 894 |
| `handlePronounce` | 994 |
| `startPractice` | 1037 |
| `stopPractice` | 1061 |
| `stopChapterReading` | 1139 |
| `playChunk` | 1153 |
| `readSingleSentence` | 1174 |
| `readSingleWord` | 1187 |
| `handleSpeedChange` | 1205 |
| `handlePauseToggle` | 1224 |
| `handleReadChapter` | 1229 |
| Practice setup modal | 1792 |
| Changelog modal | 1881 |
| `AppErrorBoundary` and `Root` | 1929 |
| React root render | 1972 |

## 9. Build and Validation Process

### 9.1 Conversion Steps

1. Read the original `react.txt`.
2. Normalize line endings to LF.
3. Replace the React/lucide imports with UMD global destructuring.
4. Remove the Gemini key and `fetchGemini`.
5. Replace the voice helper with the improved fallback implementation.
6. Rewrite `UI_TEXT` without AI strings and update the subtitle.
7. Insert the v3.0.0 changelog entry.
8. Remove AI state, handlers, JSX, icons, and props.
9. Remove the card emoji illustration and per-card AI button.
10. Add toast handling, empty-chapter guards, and speech guards.
11. Rename the story-reading flag to content-reading and keep the behavior used by chapter-practice narration.
12. Fix unique reading word IDs.
13. Fix the reading sentence splitter for English contractions.
14. Remove `export default` and add the ReactDOM root render.
15. Wrap the app code in the HTML shell.
16. Add custom animation/scrollbar CSS.
17. Add the React/lucide UMD global aliases.
18. Validate JSX and test in a real browser.

v3.1.0 steps:

19. Add `languageRef`, `subjectRef`, speech sequence, speech timer, and reading token refs.
20. Interrupt reading when speech starts from a card or practice session; invalidate delayed restarts on stop.
21. Add HanziWriter resize updates, cleanup, retryable lazy loading, and reduced-motion handling.
22. Add the boot fallback, CDN error tracking, `Root`, and `AppErrorBoundary`.
23. Add `activePracticeTab` to all chapter-practice reveal/input keys.
24. Add keyboard semantics, ARIA labels, dialog focus management, live toast, localized title/lang, and focus-visible styling.
25. Add the v3.1.0 changelog entry and download filename bump.
26. Re-run the automated browser checks and update this document.

### 9.2 JSX Validation

The app script is still compiled in the browser by Babel Standalone with the `react` preset. The v3.1.0 script mounts successfully in Chrome, which confirms the JSX and class/function syntax compile. The earlier standalone transform counts no longer apply because the script changed.

### 9.3 Browser Validation

Testing was performed with headless Chrome through the Chrome DevTools Protocol over HTTP and by opening the local `file://` URL directly. The CDP harness injects a deterministic fake `speechSynthesis` before page load so reading and practice can be tested without installed voices.

Final result:

- The app mounts successfully.
- 30 cards render for the initial Tony Chinese Exam 1 chapter.
- No JavaScript exceptions are raised during a normal load.
- The only console messages are non-fatal warnings from the Tailwind Play CDN and the in-browser Babel transformer.
- HanziWriter SVG width changes from 78 px to 34 px when the viewport changes from desktop to mobile.
- Changing language to English updates `document.lang`, the title, and the speed-slider label.
- Changing speed mid-read uses the current language (`zh-TW`) and new rate.
- Stop during the 50 ms restart gap does not restart reading.
- Modal Escape-to-close, focus restore, and Tab wrapping work.
- Blocking React/Babel shows the boot fallback with the missing CDN names and `__appMounted` remains false.
- A temporary copy with two `PRACTICE_DB` tabs renders both tabs, selects an answer in Tab A, and switches to Tab B without errors.

### 9.4 Test Matrix

| Test | Expected | Result |
| --- | --- | --- |
| Open `file:///.../index.html` directly | App mounts | Pass |
| Initial render | Tony, Chinese, Exam 1, 30 cards | Pass |
| Switch chapter to Tony Chinese Dictation 1 | 16 cards and section separators | Pass |
| Open chapter reading | Reading panel with chapter text | Pass |
| English reading in sentence mode | Five complete sentences; `mustn't` not split | Pass |
| Switch UI language to English | English labels and subtitle | Pass |
| Switch subject to English | English chapter list and cards | Pass |
| Empty chapter reading | Toast: no chapter content | Pass |
| User profile | No chapters and no cards; read toast | Pass |
| Standard practice | Countdown, active card, floating progress bar, stop | Pass |
| Selected-card practice | `已選取 1 個單字`, progress `1 / 1` | Pass |
| Dictation practice | All cards hidden, countdown, stop | Pass |
| Card click | Speech path runs without exceptions | Pass |
| Changelog | Modal opens, v3.1.0 entry and download button present | Pass |
| Chapter-practice button | Disabled because `PRACTICE_DB` is empty | Pass |
| Console errors during normal load | None | Pass |
| Language switch | `document.lang`, title, and slider label update | Pass |
| Speed change mid-read | Restarts with current language and new rate | Pass |
| Stop during restart gap | Reading does not resume | Pass |
| HanziWriter resize | SVG resizes at responsive breakpoints | Pass |
| Dialog semantics | `role="dialog"`, `aria-modal`, labelled heading | Pass |
| Escape and focus restore | Dialog closes and trigger regains focus | Pass |
| Tab focus trap | Tab wraps inside the dialog | Pass |
| Card keyboard activation | Enter/Space triggers pronunciation path | Pass |
| Card selection | Badge is a button and `aria-pressed` toggles | Pass |
| Practice session | Floating bar appears and Stop removes it | Pass |
| Boot fallback | Blocked React/Babel shows error details | Pass |
| Chapter-practice tabs | Two temporary tabs render and switch cleanly | Pass |
| `file://` direct open | App mounts and renders 30 cards | Pass |

The warnings from Tailwind and Babel are expected in this CDN/in-browser-transpile delivery model. They do not affect functionality. The blocked-CDN test intentionally produces network/script errors before the fallback appears.

## 10. Known Limitations

1. **Internet is required for the UI and stroke data.** The HTML file itself is standalone, but React, Tailwind, Babel, lucide, HanziWriter, and character data come from CDNs.
2. **TTS quality depends on installed voices.** A Cantonese voice may not be installed. The application falls back to another Chinese voice, which may pronounce Cantonese text with Mandarin pronunciation.
3. **In-browser Babel is not production-optimal.** There is a runtime compile step and a console warning. A precompiled build would start faster.
4. **Tailwind Play CDN is not intended for production.** It generates styles at runtime and prints a warning.
5. **Chapter practice is disabled.** `PRACTICE_DB` is empty, so the button is disabled even though the modal code remains.
6. **Some chapter content is empty or placeholder.** Four chapters have no reading text, and one Sofia chapter contains a placeholder instruction.
7. **No persistence.** Profile, chapter, language, speed, and practice settings reset on reload.
8. **Some strings remain hardcoded Chinese.** Navigation subject labels, content-specific chapter-practice labels, and a few reading hints still use Chinese when the UI language is English.
9. **Mobile Safari speech behavior was not explicitly tested.** Some browsers require speech to start directly inside a user gesture; delayed speech or timer-driven practice narration may behave differently.
10. **The data backup is not a full source backup.** The download button exports data constants, not the complete HTML/React application.
11. **The boot fallback is heuristic.** It relies on script `onerror` attributes, capture-phase errors, and a 15-second timeout. A strict CSP that blocks inline handlers would weaken detection.
12. **The dialog focus trap is lightweight.** It cycles focus inside the dialog but does not mark the rest of the page inert. Escape closes the topmost modal state.
13. **The error boundary covers render errors, not event-handler errors.** Event-handler exceptions are still reported to the console while the UI remains mounted.

## 11. Maintenance Guide

### 11.1 Adding or Editing Vocabulary

Edit `VOCABULARY_DB` in `index.html`. Add a chapter key and an array of records:

```js
'chapter_id': [
  {
    word: '詞語',
    translation: 'meaning',
    chars: [
      { c: '詞', p: 'ci4' },
      { c: '語', p: 'jyu5' }
    ]
  }
]
```

For full-sentence entries, use `chars: []`.

### 11.2 Adding a Chapter

1. Add a chapter to `CHAPTERS` under the correct profile:

```js
{
  id: 'profile_subject_name',
  title: 'Chapter title',
  subject: 'chinese',
  content: 'Reading text'
}
```

Use `chinese`, `english`, or `gs` for the subject.

2. Add vocabulary under the same chapter ID in `VOCABULARY_DB`.
3. Optionally add a visual separator in `getSeparatorConfig`.
4. If the chapter needs chapter practice, add an entry to `PRACTICE_DB`.
5. Update `APP_VERSION`, the initial `<title>`, and `CHANGELOG_DATA`.
6. If chapter practice is added, include `activePracticeTab` in any new reveal/input keys so tabs cannot collide.
7. Run the CDP checks in section 9.3 and update the checksum in section 1.1.

### 11.3 Adding Chapter-Practice Data

`PRACTICE_DB` accepts either a single practice object or an array of practice objects. The modal supports:

- `type: 'concept_map'` for the concept-map layout;
- `type: 'mixed_qa'` for sections containing multiple-choice questions, free-text questions, instructions, and sentence-making prompts.

The exact expected fields are visible in the chapter-practice modal code. Because `PRACTICE_DB` is currently empty, the button remains disabled.

### 11.4 Updating the Version

Update all of the following:

- `APP_VERSION`;
- the initial `<title>` in the HTML head;
- the changelog list (add a new entry; keep v3.0.0 and v3.1.0 history);
- the download filename if the version is included there;
- `DEVELOPMENT.md` header, checksum, size, and test matrix;
- the backup folder version/label when snapshotting.

`document.title` is updated at runtime from `t.title` and `APP_VERSION`; `document.documentElement.lang` follows the selected UI language.

### 11.5 Rebuilding From `react.txt`

`index.html` is the canonical standalone deliverable. `react.txt` is the original AI-enabled source and should not be treated as the current app.

If a rebuild from `react.txt` is needed, repeat the conversion steps in section 9.1 and re-run the JSX and browser checks. In particular, remember:

- remove `export default`;
- set the lucide UMD globals;
- remove all AI state and JSX;
- keep the reading/practice logic;
- validate that no `apiKey`, `fetchGemini`, or `generativelanguage` references remain.

### 11.6 Local Testing

Serve the folder with a static server:

```powershell
python -m http.server 8765 --bind 127.0.0.1
```

Then open:

```text
http://127.0.0.1:8765/index.html
```

Direct `file://` opening also works.

### 11.7 Backup and Versioning

Run the snapshot helper before each change set:

```powershell
.\backup.ps1 -Version v3.1.0 -Label pre-edit
```

The helper creates `backups/<version>_<timestamp>[_label]/` and copies `index.html`, `DEVELOPMENT.md`, `react.txt`, and `backup.ps1`. It writes `MANIFEST.json` with the version, label, creation time, byte sizes, and SHA-256 for each file. Snapshots are immutable; use a new version or label instead of overwriting an existing folder.

A suggested workflow is:

1. Snapshot the current released version before editing.
2. Make and validate the change set.
3. Snapshot the new version before documentation or a second change set.
4. Keep the release checksum in section 1.1 in sync with the final `index.html`.

## 12. Security and Privacy Notes

- No API key is embedded.
- No AI service is called.
- No vocabulary, chapter text, or practice results are sent to a model.
- The application does not use cookies, localStorage, or a backend.
- The only external requests are CDN library/style/stroke-data requests.
- The data backup is generated locally with a Blob URL.
- If the application is deployed on a public site, the CDN dependencies should be reviewed or self-hosted for reliability and supply-chain control.

## 13. Future Improvements

- Precompile JSX with Babel or Vite and ship plain JavaScript.
- Compile Tailwind CSS ahead of time instead of using the Play CDN.
- Bundle React, lucide, and HanziWriter locally for offline use.
- Bundle HanziWriter character data for offline stroke animation.
- Add a service worker/PWA manifest.
- Add a local chapter-practice generator based on chapter vocabulary and content.
- Add a voice picker and remember the user's voice choice.
- Persist profile, chapter, language, and speed in `localStorage`.
- Move all remaining hardcoded Chinese strings into `UI_TEXT`.
- Add automated Playwright tests for the test matrix in section 9.4.
- Test and tune speech behavior on mobile Safari and Android Chrome.
- Consider a real build pipeline if the app grows beyond a single-file distribution.

## Appendix A: v3.1.0 Changelog Entry

```text
v3.1.0 | 2026-10-26 16:41
- 修正：調整語速後改用最新語言設定朗讀，停止朗讀不會被延遲啟動覆蓋。
- 改善：HanziWriter 尺寸更新與清理、CDN 載入失敗提示及應用程式錯誤畫面。
- 改善：鍵盤操作、螢幕閱讀器標籤、對話框焦點管理及減少動態效果。
```

Previous release:

```text
v3.0.0 | 2026-10-25 10:00
- 轉換：建立無需 API 金鑰的單一 HTML 版本，所有詞彙資料內嵌。
- 移除：AI 詞彙語境、隨機故事、隨堂測驗與自動表情符號功能。
- 保留：單字卡、筆順動畫、語音朗讀、章節朗讀及單字抽查。
- 修正：英文句子分段、朗讀詞語識別，以及沒有課文內容時的提示。
```

## Appendix B: Verification Snapshot

```text
File:       C:\Work\Projects\OpenCode\Study New\index.html
Version:    v3.1.0
Size:       167,335 bytes
SHA-256:    87314A18D57AECC057B5D96124E01363FF5AA63E745E67DF57834FB537B42572
JSX check:  Pass (mounts in Chrome with Babel Standalone, react preset)
Browser:    Chrome headless via CDP, HTTP and file://
JS errors:  None during normal load
Warnings:   Tailwind Play CDN production warning; Babel in-browser transformer warning
Tests:      30 cards, 10 chapters, 223 vocabulary records; resize, dialogs, keyboard,
            speech-language/rate, stop-race, practice start/stop, CDN fallback
```
