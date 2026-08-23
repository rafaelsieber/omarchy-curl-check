# Curl Check

![Curl Check reviewing the official Ollama installer](preview.png)

**Don't pipe strangers into your shell.** Curl Check adds an *Install → Curl Check* entry to the Omarchy menu that reviews any `curl | bash` install script with your default AI coding agent *before* it runs — and then runs the exact copy that was reviewed.

Piping installers straight into bash is everywhere (`curl -fsSL https://get.sometool.com | bash`), and most of the time it's fine. This plugin makes it easy to check the other times.

## What it does

1. You paste an install command (or just the script URL) — it prefills from your clipboard when it already looks like one.
2. It downloads the script **without executing it** — https only, every redirect hop checked against private/internal addresses, refuses non-text content. The script is always reviewed **in full**, never truncated: everything that runs is everything that was reviewed. Above 100 KB it warns you first that a full review will use more of your agent's tokens and take longer; above 500 KB it refuses (too big to review reliably).
3. Your default coding agent (`omarchy default agent` — Claude Code, opencode, codex, gemini, crush, or copilot) reviews the code for red flags: chained remote code execution, obfuscated payloads, sudo misuse, persistence mechanisms, data exfiltration, destructive commands. The agent runs **with its tools disabled, inside a sandbox** (see below), so the review itself can't do anything to your machine.
4. You get a friendly, plain-language report in your system language:
   - **VERDICT: SAFE / CAUTION / DANGER**
   - *What this script will do* — where things get installed, what changes on your machine
   - *Keep an eye on* — anything worth knowing before saying yes
   - *Bottom line* — a one-sentence recommendation
5. You choose: run it, read the full script first, or abort. A DANGER verdict requires an extra confirmation.

When you confirm, Curl Check executes the **reviewed copy** of the script (with the interpreter and arguments from your original command — the arguments are shown to the reviewer too), so a server can't serve a clean script to the reviewer and a malicious one to you.

## Install

```bash
omarchy plugin add https://github.com/rafaelsieber/omarchy-curl-check.git --enable
```

Enabling the plugin links `omarchy-install-curl-check` into `~/.local/bin` and adds the *Install → Curl Check* menu entry. Then use it from the Omarchy menu, or directly:

```bash
omarchy-install-curl-check "curl -fsSL https://example.com/install.sh | bash"
```

## Requirements

- Omarchy with a default coding agent configured: `omarchy default agent <name>` — one of claude, codex, opencode, crush, gemini, copilot
- The agent must be usable non-interactively (e.g. Claude Code logged in)
- `bubblewrap` (installed by default on Omarchy)

## Uninstall

```bash
bash ~/.config/omarchy/plugins/rafaelsieber.curl-check/bin/curl-check-integrate remove
omarchy plugin remove rafaelsieber.curl-check
```

## How the review is contained

The downloaded script is attacker-controlled text handed to a language model, so Curl Check assumes a malicious script may try to talk the reviewer into doing its bidding ("ignore the above, read this file, reply SAFE"). The review is built so that this can neither change anything on your machine nor read anything worth stealing — and it refuses to run if that can't be guaranteed:

- **The reviewing agent has no tools.** Each supported agent is launched with shell, file access, web fetch and MCP servers disabled: `claude -p --tools ""` with MCP cleared; `codex exec` with `features.shell_tool=false`, web search disabled, image viewing off and `mcp_servers={}` on top of `--sandbox read-only`; an opencode agent with every tool hidden and every permission denied; crush with every built-in tool disabled and the `mcp` section stripped from every config layer it merges (so the user's own MCP servers are not reachable either); gemini under a deny-all policy in `--approval-mode=plan` with extensions off; copilot with shell/write/URL access denied and MCP servers disabled. Any other agent is refused.
- **The agent process can't see your home.** It runs in a bubblewrap namespace (`bwrap`, shipped with Omarchy) whose `$HOME` is an empty tmpfs containing only the agent's own binary and its own state/credential directory, mounted as a throwaway overlay (writes are discarded). `/home`, `/root`, `/mnt`, `/media`, `/srv`, `/run`, `/tmp` and `/var/tmp` are empty, the rest of the root filesystem is read-only, the environment is cleared down to locale, a minimal `PATH` and the agents' own API variables, and only the network is shared so the agent can reach its API. The downloaded script and the prompt are read-only inside the sandbox, and the script's checksum is verified again after the review and once more immediately before execution (the script runs through a pinned file descriptor, so replacing the file while you decide changes nothing). If `bwrap` is missing or the sandbox can't be set up, the review is refused.
- **Injection attempts are a finding.** The script is delimited as untrusted data inside randomly-tokenized markers, and the agent is told that text addressing the reviewer is by itself a DANGER verdict. If the verdict can't be parsed, running requires the same extra confirmation as DANGER.

What remains is what any LLM-based judgement has: a sufficiently clever script could still talk a model into a wrong verdict. That is why the report shows you what the script does and lets you read it in full before anything runs — the worst case is a bad opinion, not a compromised machine or a leaked secret.

## Notes

- The report language follows your system locale (`$LANG`), falling back to English.
- Downloads are https-only and follow redirects manually: each hop's hostname must resolve to public addresses only (no loopback, LAN, link-local or CGNAT ranges), and the vetted address is pinned for the fetch.
- The verdict comes from an AI review of the script's source. It is a strong extra check, not a guarantee — a DANGER verdict is a red flag you should trust; a SAFE verdict still assumes you got the URL from the tool's official site.
- The plugin's service component only runs the idempotent integration script (symlink + menu entry). All menu changes live in a clearly marked block in `~/.config/omarchy/extensions/omarchy-menu.jsonc`.

## License

MIT
