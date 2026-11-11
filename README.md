<div align="center">

# 🌕 DeadMoon-Universal-API-Verify-Script 🌙

**100% Self-Contained Windows LLM Fingerprint & Relay Verification Toolkit with Smart Auto-Heal, Universal Catalog Scanner & Kinetic Moon UI**

[![DeadMoon Suite](https://img.shields.io/badge/🌕_DeadMoon-Tool_Suite-111827?style=for-the-badge&labelColor=000000)](https://github.com/Deadplayerdmr/)
[![Platform](https://img.shields.io/badge/Platform-Windows_10_%7C_11-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Bun Runtime](https://img.shields.io/badge/Runtime-Oven_Bun-FBF0DF?style=for-the-badge&logo=bun&logoColor=000000)](https://github.com/oven-sh/bun)
[![Engine](https://img.shields.io/badge/Engine-lm--detector_(lmfpd)-8B5CF6?style=for-the-badge)](https://github.com/Ikaleio/lm-detector)
[![License](https://img.shields.io/badge/License-MIT-10B981?style=for-the-badge)](LICENSE)

*Part of the [DeadMoon Tool Suite](https://github.com/Deadplayerdmr/) by [@Deadplayerdmr](https://github.com/Deadplayerdmr)*

</div>

---

## 🖥️ Terminal Preview

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

---

## 🌙 Overview

**DeadMoon-Universal-API-Verify-Script** is a 100% self-contained, portable Windows CLI toolkit that wraps **[Ikaleio/lm-detector](https://github.com/Ikaleio/lm-detector)** (`lmfpd@latest`) to statistically fingerprint and verify upstream Large Language Models (LLMs) across **OpenRouter** and any custom 3rd-party OpenAI- or Anthropic-compatible API relay.

Unofficial third-party API relays and aggregators can sometimes silently downgrade, quantize, or spoof models behind a system prompt. **DeadMoon Universal API Verify Script** makes running cryptographic token-distribution fingerprinting effortless on Windows 10/11 with **zero global Node.js or Bun installation required**.

---

## ✨ Key Features & Architecture (v2.2)

- **🌕 Animated Moon Boot Splash & UI**: Features an animated ASCII crest modeled after the DeadMoon headphone logo complete with floating music notes, pulsing headphone soundwaves, twinkling stars, and a smooth single-line `25% -> 50% -> 75% -> 100%` progress bar.
- **🧠 Smart Auto-Config Mode (`[M]`)**: Enabled by default. Automatically probes provider endpoints, selects optimal protocol routes (`-a cc` vs `-a message`), extends timeouts for reasoning models (`opus`, `r1`, `o1`, `o3`), and **self-heals** by dynamically catching dropped SSE streams (`missing finish status`) or concurrency/rate-limit blocks (`HTTP 402/429/503`) to auto-retry with non-streaming (`-ns`) or sequential (`-p 1`) protection.
- **🔐 Local API Key Vault (`[K]` & `[V]`)**: Optionally saves your API key locally inside `./lm_detector_deps/saved_apikey.txt` so you never have to re-paste it on startup, paired with a dedicated `[V]` viewer to reveal your full saved key anytime.
- **🔍 Universal Catalog Scanner (`[3]`)**: Bypasses gateway pagination caps to fetch the full model catalog (e.g., 420+ models on OpenRouter) and features multi-word fuzzy search with automatic closest-match fallback.
- **📡 Dual-Protocol Diagnostic Ping (`[4]`)**: Fires a 1-request latency and compatibility test against both `/v1/chat/completions` (OpenAI format) and `/v1/messages` (Anthropic native format) side-by-side.
- **📦 Zero Global Dependencies**: Automatically downloads a portable instance of the [Bun runtime](https://github.com/oven-sh/bun) and installs `lmfpd@latest` inside a local `./lm_detector_deps` folder on first launch.

---

## 🚀 Quick Start (Windows 10 / 11)

1. Download **`DeadMoon_Universal_API_Verify_ScriptV2.2.cmd`** from the repository or the **[Releases](../../releases)** page and place it in its own folder.
2. Double-click **`DeadMoon_Universal_API_Verify_ScriptV2.2.cmd`** to launch.
3. On first launch, pick your Base URL (**OpenRouter** or **Custom 3rd-Party URL**) and paste your API Key.
4. Choose whether to save your API Key locally for future sessions.

---

## 🎛️ Interactive Menu Reference

| Option | Action | Description |
| :---: | :--- | :--- |
| **`[1]`** | **Verify a Single Model** | Type an exact model ID (e.g., `anthropic/claude-opus-4.6`, `openai/gpt-4.1`, `deepseek/deepseek-r1`) |
| **`[2]`** | **Batch-Verify Models** | Verify a comma- or space-separated queue of model IDs |
| **`[3]`** | **Auto-Detect Provider Catalog** | Fetch the full `/models` catalog, fuzzy-filter by keyword, and pick models by number/range |
| **`[4]`** | **Quick Diagnostic Ping** | Test `/v1/chat/completions` (`-a cc`) and `/v1/messages` (`-a message`) side-by-side |
| **`[M]`** | **Smart Auto-Config Mode** | Auto-tunes protocol and self-heals on dropped SSE streams or rate-limit errors |
| **`[6]`–`[9]`, `[S]`** | **Manual Protocol Toggles** | Toggle Anthropic Messages (`-a message`), Sequential (`-p 1`), Non-Streaming (`-ns`), Tokenizer Probe, or Strict Scoring (`-s`) |
| **`[5]` / `[K]` / `[V]`** | **Endpoint & API Key Vault** | Switch Base URL, manage local/session API keys, or reveal your saved key |
| **`[R]` / `[I]` / `[U]`** | **Tuning, Offline Analysis & Updates** | Adjust rounds/samples/effort, re-analyze saved `report_*.json` files offline, or update `lmfpd@latest` |

---

## 📚 Credits, Citations & Upstream Attributions

This project is an interactive Windows batch/JS frontend and relay-compatibility wrapper built around:

- **[Ikaleio/lm-detector (`lmfpd`)](https://github.com/Ikaleio/lm-detector)** — Created by **[Ikaleio](https://github.com/Ikaleio)** for core LLM statistical fingerprinting, token distribution analysis, and reference bank verification.
- **[Oven Bun (`oven-sh/bun`)](https://github.com/oven-sh/bun)** — Used as the portable local JavaScript runtime and package manager.
- **Interactive CLI Wrapper & Smart Auto-Heal Engine** — Created by **[@Deadplayerdmr](https://github.com/Deadplayerdmr)**.

---

## 📄 License

Distributed under the [MIT License](LICENSE). All upstream packages fetched at runtime (`lmfpd` and `bun`) remain under their respective authors' licenses.

---

## 🌌 The DeadMoon Tool Suite

| Repository | Role in the Ecosystem |
| :--- | :--- |
| 🌕 **[DeadMoon-Download-Bot](https://github.com/Deadplayerdmr/DeadMoon-Download-Bot)** | Whitelisted 8-platform Telegram audio acquisition bot with direct lossless engines, lock-free scheduler & 477 offline tests |
| 📻 **[DeadMoon-Telegram-Broadcaster-Bot](https://github.com/Deadplayerdmr/DeadMoon-Telegram-Broadcaster-Bot)** | 24/7 automated Telegram-to-Icecast radio broadcaster with smooth 22% audio-ducked ads, `/replaytrack` & fallback rotation |
| 🌾 **[DeadMoon-Credential-Harvester](https://github.com/Deadplayerdmr/DeadMoon-Credential-Harvester)** | Local Tampermonkey userscript (`2.3v`) for harvesting streaming ARLs, OAuth tokens, Netscape cookies & Widevine `.wvd` bundles |
| 🔐 **[DeadMoon-Unified-Spotify-Provisioner](https://github.com/Deadplayerdmr/DeadMoon-Unified-Spotify-Provisioner)** | Automated Windows polyglot provisioner for Spotify Premium `sp_dc` cookies & Android Widevine L3 `device.wvd` CDMs |
| 🎶 **[DeadMoon-Playlist-Transfer-Tool](https://github.com/Deadplayerdmr/DeadMoon-Playlist-Transfer-Tool)** | Single-file Windows polyglot tool for migrating Deezer Favorites (Artists, Albums & Playlists) via CSV |
| 🤖 **[DeadMoon-OpenHands-Launcher](https://github.com/Deadplayerdmr/DeadMoon-OpenHands-Launcher)** | Zero-friction Windows launcher & installer for OpenHands with kinetic ASCII UI & automatic `winnat` port recovery |
| 🔍 **[DeadMoon-Universal-API-Verify-Script](https://github.com/Deadplayerdmr/DeadMoon-Universal-API-Verify-Script)** | Self-contained Windows LLM statistical fingerprint verifier (`lmfpd`) with Smart Auto-Heal & catalog scanner |

---

<div align="center">

**🌕 DeadMoon-Universal-API-Verify-Script 🌙** — Crafted by [@Deadplayerdmr](https://github.com/Deadplayerdmr/)

</div>
