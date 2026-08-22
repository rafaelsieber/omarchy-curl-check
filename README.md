# Curl Check

![Curl Check reviewing the official Ollama installer](preview.png)

**Don't pipe strangers into your shell.** Curl Check adds an *Install → Curl Check* entry to the Omarchy menu that reviews any `curl | bash` install script with your default AI coding agent *before* it runs — and then runs the exact copy that was reviewed.

Piping installers straight into bash is everywhere (`curl -fsSL https://get.sometool.com | bash`), and most of the time it's fine. This plugin makes it easy to check the other times.

## What it does

1. You paste an install command (or just the script URL) — it prefills from your clipboard when it already looks like one.
2. It downloads the script **without executing it** — https only, every redirect hop checked against private/internal addresses, refuses non-text content. The script is always reviewed **in full**, never truncated: everything that runs is everything that was reviewed. Above 100 KB it warns you first that a full review will use more of your agent's tokens and take longer; above 500 KB it refuses (too big to review reliably).
3. Your default coding agent (`omarchy default agent` — Claude Code, opencode, codex, gemini, crush, or copilot) reviews the code for red flags: chained remote code execution, obfuscated payloads, sudo misuse, persistence mechanisms, data exfiltration, destructive commands.
4. You get a friendly, plain-language report in your system language:
   - **VERDICT: SAFE / CAUTION / DANGER**
   - *What this script will do* — where things get installed, what changes on your machine
   - *Keep an eye on* — anything worth knowing before saying yes
   - *Bottom line* — a one-sentence recommendation
5. You choose: run it, read the full script first, or abort. A DANGER verdict requires an extra confirmation.

When you confirm, Curl Check executes the **reviewed copy** of the script (with the interpreter and arguments from your original command), so a server can't serve a clean script to the reviewer and a malicious one to you.

## Install

```bash
omarchy plugin add https://github.com/rafaelsieber/omarchy-curl-check.git --enable
```

Enabling the plugin links `omarchy-install-curl-check` into `~/.local/bin` and adds the *Install → Curl Check* menu entry. Then use it from the Omarchy menu, or directly:

```bash
omarchy-install-curl-check "curl -fsSL https://example.com/install.sh | bash"
```

## Requirements

- Omarchy with a default coding agent configured: `omarchy default agent <name>`
- The agent must be usable non-interactively (e.g. Claude Code logged in)

## Uninstall

```bash
bash ~/.config/omarchy/plugins/rafaelsieber.curl-check/bin/curl-check-integrate remove
omarchy plugin remove rafaelsieber.curl-check
```

## Notes

- The report language follows your system locale (`$LANG`), falling back to English.
- The script is passed to the agent as untrusted data inside randomly-tokenized markers, and the agent is instructed to treat manipulation attempts as a DANGER verdict on their own. If the verdict can't be parsed, running requires the same extra confirmation as DANGER.
- Downloads are https-only and follow redirects manually: each hop's hostname must resolve to public addresses only (no loopback, LAN, link-local or CGNAT ranges), and the vetted address is pinned for the fetch.
- The verdict comes from an AI review of the script's source. It is a strong extra check, not a guarantee — a DANGER verdict is a red flag you should trust; a SAFE verdict still assumes you got the URL from the tool's official site.
- The plugin's service component only runs the idempotent integration script (symlink + menu entry). All menu changes live in a clearly marked block in `~/.config/omarchy/extensions/omarchy-menu.jsonc`.

## License

MIT
