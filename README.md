# Claude Code Statusline

A clean, informative statusline for [Claude Code](https://claude.ai/code) with context usage tracking.

## Features

- **Directory** - Current working directory (truncated if long)
- **Git status** - Branch name with staged/unstaged change indicators
- **Model** - Currently active Claude model
- **Context bar** - Visual progress bar showing context window usage
- **Session stats** - Lines added/removed during session

## Preview

```
freestar │ main │ Opus 4.5 │ ████░░░░ 48% │ +127 -34
```

## Requirements

- `bash`
- `jq` (for JSON parsing)
- `git` (for repository status)

## Installation

1. Download the script:
   ```bash
   curl -o ~/.claude/statusline.sh https://raw.githubusercontent.com/alxmlv/claude-code-statusline/main/statusline.sh
   ```

2. Add to your Claude Code settings (`~/.claude/settings.json`):
   ```json
   {
     "statusline": "bash ~/.claude/statusline.sh"
   }
   ```

## Configuration

Edit the variables at the top of `statusline.sh` to customize:

```bash
BAR_WIDTH=8           # Width of progress bar
BAR_FILLED="█"        # Filled character
BAR_EMPTY="░"         # Empty character
CONTEXT_WARNING=60    # Yellow threshold (%)
CONTEXT_DANGER=80     # Red threshold (%)
```

## Color Coding

| Element | Color |
|---------|-------|
| Directory | Cyan |
| Git branch (clean) | Green |
| Git branch (dirty) | Yellow |
| Staged changes | Green ● |
| Unstaged changes | Blue ○ |
| Context bar (low) | Green |
| Context bar (warning) | Yellow |
| Context bar (danger) | Red |
| Lines added | Green |
| Lines removed | Red |

## License

MIT
