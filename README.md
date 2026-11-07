# 🌙 DeadMoon Universal API Verify Script

**Powered by [Ikaleio/lm-detector (`lmfpd`)](https://github.com/Ikaleio/lm-detector)**

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

A 100% self-contained, portable Windows CLI toolkit that wraps Ikaleio/lm-detector (lmfpd@latest) to fingerprint and verify upstream Large Language Models (LLMs) across OpenRouter and any custom 3rd-Party OpenAI- or Anthropic-compatible API relay.

## ✨ Key Features & Architecture (v2.2)

- **Animated Moon Boot Splash & UI:** Features an animated ASCII crest modeled after the DeadMoon headphone logo complete with floating music notes, pulsing headphone soundwaves, twinkling stars, and a smooth single-line 25% → 50% → 75% → 100% progress bar.
- **Smart Auto-Config Mode (`[M]`):** Enabled by default. Automatically probes provider endpoints, selects optimal protocol routes (`-a cc` vs `-a message`), and self-heals by dynamically catching dropped SSE streams (missing finish status) or concurrency/rate-limit blocks (HTTP 402/429/503) to auto-retry with non-streaming (`-ns`) or sequential (`-p 1`) protection.
- **Local API Key Vault (`[K]` & `[V]`):** Securely saves your API key locally inside an ignored vault file (`lm_detector_deps/saved_apikey.txt`) so you never have to re-paste it on startup, with a dedicated `[V]` viewer to reveal your full key anytime.
- **Universal Catalog Scanner (`[3]`):** Bypasses gateway pagination caps to fetch the full model catalog (e.g., 400+ models on OpenRouter) and features multi-word fuzzy search with automatic fallback matching.
- **Zero Global Dependencies:** Automatically downloads a portable instance of the Bun runtime and installs `lmfpd@latest` inside a local `./lm_detector_deps` folder on first launch.

## 🚀 Quick Start (Windows 10 / 11)

1. Download `DeadMoon_Universal_API_Verify_Script.cmd` into its own folder.
2. Double-click the `.cmd` file to launch.
3. On first launch, pick your Base URL (OpenRouter or Custom) and enter your API Key.
4. Choose whether to save your API Key locally for future sessions.

## 🙏 Credits, Citations & Upstream Attributions

This project is an interactive Windows batch/JS frontend and relay-compatibility wrapper built around:

- **Ikaleio/lm-detector (`lmfpd`)** — Created by Ikaleio for core LLM statistical fingerprinting and token distribution analysis.
- **Oven Bun (`oven-sh/bun`)** — Used as the portable local JavaScript runtime and package manager.

## 📄 License

Distributed under the MIT License.

