# 🌙 DeadMoon Universal API Verify Script

**Powered by [Ikaleio/lm-detector (`lmfpd`)](https://github.com/Ikaleio/lm-detector) & [Oven Bun](https://github.com/oven-sh/bun)**

```text
          .       +        .================.        *        .
       +    d~~b      .==='  .------------.  '===.      d~~b     .
          . d  b    /   .-'    .      o    '-.   \     d  b   +
                   /  .'   o       .      .   '.  \        .
        *         [===]  .    /        \    .  [===]   +       *
             .--- [===]     \____/    \____/   [===] ---.
            (     [===]   o      .----.      O [===]     )   d~b
        .    '--- [===]    .    /      \   .   [===] ---'    d b
           +       \  '.     .            o  .'  /       *
        .           '.  '-.    o   .   .  .-'  .'     .       +
             *        '===='--------------'===='          .
```

A 100% self-contained, portable Windows CLI toolkit that wraps **[Ikaleio/lm-detector](https://github.com/Ikaleio/lm-detector)** (`lmfpd@latest`) to fingerprint and verify upstream Large Language Models (LLMs) across **OpenRouter** and any custom 3rd-party OpenAI- or Anthropic-compatible API relay.

Unofficial third-party API relays and aggregators can sometimes silently downgrade or spoof models behind a system prompt. **DeadMoon Universal API Verify Script** makes running cryptographic token-distribution fingerprinting effortless on Windows 10/11—with zero global Node.js or Bun installation required.

---

## ✨ Key Features & Architecture (v2.2)

* **Animated Moon Boot Splash & UI**: Features an animated ASCII crest modeled after the DeadMoon headphone logo complete with floating music notes, pulsing headphone soundwaves, twinkling stars, and a smooth single-line `25% → 50% → 75% → 100%` progress bar.
* **Smart Auto-Config Mode (`[M]`)**: Enabled by default. Automatically probes provider endpoints, selects optimal protocol routes (`-a cc` vs `-a message`), extends timeouts for reasoning models (`opus`, `r1`, `o1`, `o3`), and **self-heals** by dynamically catching dropped SSE streams (`missing finish status`) or concurrency/rate-limit blocks (`HTTP 402/429/503`) to auto-retry with non-streaming (`-ns`) or sequential (`-p 1`) protection.
* **Local API Key Vault (`[K]` & `[V]`)**: Optionally saves your API key locally inside `./lm_detector_deps/saved_apikey.txt` so you never have to re-paste it on startup, paired with a dedicated `[V]` viewer to reveal your full saved key anytime.
* **Universal Catalog Scanner (`[3]`)**: Bypasses gateway pagination caps to fetch the full model catalog (e.g., 420+ models on OpenRouter) and features multi-word fuzzy search with automatic closest-match fallback.
* **Dual-Protocol Diagnostic Ping (`[4]`)**: Fires a 1-request latency and compatibility test against both `/v1/chat/completions` (OpenAI format) and `/v1/messages` (Anthropic native format) side-by-side.
* **Zero Global Dependencies**: Automatically downloads a portable instance of the [Bun runtime](https://github.com/oven-sh/bun) and installs `lmfpd@latest` inside a local `./lm_detector_deps` folder on first launch.

---

## 🚀 Quick Start (Windows 10 / 11)

1. Download **`DeadMoon_Universal_API_Verify_ScriptV2.2.cmd`** from the repository or the **[Releases](../../releases)** page and place it in its own folder.
2. Double-click **`DeadMoon_Universal_API_Verify_ScriptV2.2.cmd`** to launch.
3. On first launch, pick your Base URL (**OpenRouter** or **Custom 3rd-Party URL**) and paste your API Key.
4. Choose whether to save your API Key locally for future sessions.

---

## 🙏 Credits, Citations & Upstream Attributions

This project is an interactive Windows batch/JS frontend and relay-compatibility wrapper built around:

* **[Ikaleio/lm-detector (`lmfpd`)](https://github.com/Ikaleio/lm-detector)** — Created by **[Ikaleio](https://github.com/Ikaleio)** for core LLM statistical fingerprinting, token distribution analysis, and reference bank verification.
* **[Oven Bun (`oven-sh/bun`)](https://github.com/oven-sh/bun)** — Used as the portable local JavaScript runtime and package manager.
* **Interactive CLI Wrapper & Smart Auto-Heal Engine** — Created by **[deadplayerdmr](https://github.com/deadplayerdmr)** with assistance from Google Gemini.

---

## 📄 License

Distributed under the MIT License. All upstream packages fetched at runtime (`lmfpd` and `bun`) remain under their respective authors' licenses.
