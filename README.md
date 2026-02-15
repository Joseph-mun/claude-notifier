# ClaudeNotifier

macOS native notification tool for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) hooks.

Built with Swift using `UNUserNotificationCenter` — replaces `terminal-notifier` which has compatibility issues on macOS Sonoma+.

## Features

- **Alert-style notifications** that persist until user action
- **Click-to-focus** specific VS Code project window via `NSWorkspace.open`
- **Programmatic dismiss** via `remove` command
- **Group-based notification management** (same group replaces previous)
- **No Dock icon** — runs as accessory app (`LSUIElement`)

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)

## Build & Install

```bash
./build.sh
```

This will:
1. Compile the Swift source
2. Create an app bundle with VS Code icon
3. Install to `~/.claude/notifier/ClaudeNotifier.app`
4. Create symlink at `~/bin/claude-notifier`

## Setup

Request notification permissions (run once):

```bash
open ~/.claude/notifier/ClaudeNotifier.app --args setup
```

Then go to **System Settings → Notifications → ClaudeNotifier** and set style to **Alerts** (not Banners).

## Usage

### Send a notification

```bash
open -g ~/.claude/notifier/ClaudeNotifier.app --args send \
  --title "Title" \
  --message "Body text" \
  --subtitle "Subtitle" \
  --sound "default" \
  --group "my-group" \
  --project-dir "/path/to/project"
```

### Remove a notification

```bash
open -g ~/.claude/notifier/ClaudeNotifier.app --args remove --group "my-group"
open -g ~/.claude/notifier/ClaudeNotifier.app --args remove --all
```

## Claude Code Hooks Integration

Used with three hook scripts in `~/.claude/hooks/`:

| Hook | Script | Purpose |
|------|--------|---------|
| PermissionRequest | `notify-permission.sh` | Alert when tool needs approval |
| Stop | `notify-complete.sh` | Alert when task completes |
| PostToolUse | `notify-dismiss.sh` | Dismiss permission alert after approval |

## License

MIT
