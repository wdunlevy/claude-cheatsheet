---
name: cheatsheet
description: CI variant — generate Claude Code cheatsheet HTML, snapshot, and manifest. The GitHub Actions workflow renders the PDF and commits.
user-invocable: false
---

# Generate Claude Code Cheatsheet (CI variant)

You are running inside a GitHub Actions Ubuntu runner, invoked by
`.github/workflows/cheatsheet.yml`. Your job is the **content** layer only.
The workflow handles PDF rendering, `latest.pdf` refresh, git commit, and
notification.

## What you produce

Exactly four files in the working directory:

| File | Purpose |
|------|---------|
| `current.html`    | The cheatsheet HTML (workflow renders to PDF) |
| `snapshot.json`   | The current inventory, replaces the previous snapshot |
| `manifest.json`   | `{ "version": "...", "lastGenerated": "...", "note": "..." }` |
| `last-run.json`   | Run result the workflow consumes (see Step 6) |

## What you do NOT do

- Do NOT run Chrome or any PDF tool.
- Do NOT touch `latest.pdf`.
- Do NOT run any `git` command.
- Do NOT search the home directory or invoke `find` / `mdfind` / `fd`.
  Stay inside the working directory.

## Process

### Step 1: Gather Current Data

Collect every skill, slash command, keyboard shortcut, and CLI flag you can
see from this Claude Code session.

1. **Skills** — read from the system reminder's skill list in your context.
2. **Built-in commands** — slash commands shipped with Claude Code (not
   plugin-installed). Common set: `/add-dir`, `/agents`, `/branch`, `/btw`,
   `/clear`, `/color`, `/compact`, `/config`, `/context`, `/copy`, `/cost`,
   `/debug`, `/doctor`, `/effort`, `/export`, `/extra-usage`, `/fast`,
   `/feedback`, `/help`, `/ide`, `/mcp`, `/memory`, `/model`, `/permissions`,
   `/plan`, `/plugins`, `/release-notes`, `/remote-control`, `/rename`,
   `/resume`, `/rewind`, `/sandbox`, `/skills`, `/stats`, `/status`,
   `/terminal-setup`, `/theme`, `/todos`, `/upgrade`, `/usage`, `/voice`.
   Trust the existing snapshot for the canonical list and add what you see.
3. **Keyboard shortcuts** — trust `snapshot.json`'s existing list.
4. **CLI flags & subcommands** — run `claude --help` to enumerate flags and
   subcommands, then merge with the snapshot.

### Step 2: Compare Against Previous Snapshot

Read `snapshot.json`. For each category compute:

- **New**: in current data, not in snapshot
- **Removed**: in snapshot, not in current
- **Changed**: same name, different description / category / color

If there are ZERO differences AND the prompt did not say "Force regeneration:
true":

- Do NOT regenerate `current.html`.
- Do NOT bump `manifest.json`.
- Write `last-run.json`:

  ```json
  {
    "generated": false,
    "version": "<current version from manifest.json>",
    "changes": "none",
    "message": "Cheatsheet — no changes today (v<version> current)."
  }
  ```

- Stop here.

### Step 3: Bump Version

Read `manifest.json` (e.g. `{ "version": "1.17", ... }`). Bump the minor
version: `1.17 → 1.18`. Write back `manifest.json` with the new version, an
ISO-8601 `lastGenerated` timestamp, and a short `note` describing the
change.

### Step 4: Generate HTML

Use the existing `current.html` as a layout template. **Do not redesign the
layout** — match it exactly.

**Critical: clear stale highlights before re-applying.** This is the
historical bug-class. Before you re-apply any `new` classes:

1. Strip every `class="sk new"`, `class="kb new"`, `class="cli-item new"`,
   and `class="note new"` from the template, replacing with the corresponding
   non-`new` class.
2. THEN add `new` to exactly the rows that changed in this version.
3. After writing the file, grep for `class="(sk|kb|cli-item|note) new"`. The
   count must equal the number of new/changed items you detected. If it
   doesn't, regenerate.

**Layout reference** (do not change without coordinating with the workflow):

- Letter size, 0.25in margins, CSS grid 3 columns, 8px gap, body 7pt.
- Title block in column 1: "Claude Code" 12pt, "Complete Reference" 9pt,
  legend dots, GitHub link `https://github.com/wdunlevy/claude-cheatsheet`
  styled small (5.5pt) gray.
- Color classification (the dot color on each skill row):
    - **Gray (noncode)**: session/config/info, no code touched
    - **Red (create)**: plans, designs, generates new code
    - **Green (validate)**: reviews, tests, debugs
    - **Blue (ship)**: commits, delivers, executes plans
- Sort within each category: gray, red, green, blue; alphabetical within
  each color group.
- Highlight CSS rule (already in template):
  `.sk.new, .kb.new, .cli-item.new, .note.new { background: #fff3cd; ... }`

### Step 5: Update Snapshot

Write `snapshot.json` with the full current inventory: `skills`, `commands`,
`cliFlags`, `cliSubcommands`, `shortcuts`. Match the existing schema — the
workflow doesn't introspect it but downstream tooling does.

### Step 6: Write the Run Result

Write `last-run.json`. The workflow uses every field:

```json
{
  "generated": true,
  "version": "<new version, e.g. 1.18>",
  "changes": "<one-line summary, e.g. 'added /foo skill, removed /bar'>",
  "message": "Cheatsheet v<new> — <N> changes: <list>. https://wdunlevy.github.io/claude-cheatsheet/latest.pdf"
}
```

If you skipped at Step 2 (no changes), use the no-change shape from there.

### Step 7: Stop

Do not commit. Do not push. Do not render PDF. Do not copy files. The
workflow continues from here.
