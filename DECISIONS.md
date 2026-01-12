# Decisions

## Keybindings
- Classify the command’s primary intent first: Navigate (deterministic jump), Discover (search/narrow/query), Activate (start a tool/mode/process), or Operate (act on an existing object). If unsure, default to Discover.
- Map intent to the top-level prefix: Navigate → `SPC g`, Discover → `SPC s`, Execute/activate → `SPC x`, Operate → object prefix (`SPC b`, `SPC f`, `SPC p`, etc.).
- Use an object prefix only when the object is the focus, not just a parameter. Example: `kill-this-buffer` is buffer-focused → `SPC b k`.
- Prefix meanings are strict:
  - `SPC g` deterministic navigation only (no narrowing/tools)
  - `SPC s` discovery via search, narrowing, or querying (Consult lives here)
  - `SPC x` execute/activate tools, modes, processes
  - `SPC a` ai domain (self-contained)
  - `SPC o` org/gtd domain (self-contained)
  - `SPC n` notes domain (self-contained)
  - `SPC b` buffer lifecycle/mutation/buffer-local state
  - `SPC f` file mutation/metadata/external actions
  - `SPC p` project-scoped variants of existing intents
  - `SPC t` toggles only (idempotent state flips)
  - `SPC w` window layout and movement only
  - `SPC v` version control domain (self-contained)
  - `SPC TAB` workspace management
  - `SPC u` universal argument
- Core rule: intent always wins over scope. Top level = why, second level = where. Only invert this inside a deliberate domain workflow.
- Documentation/help commands are Discover, even if they open help buffers. Examples: language docs → `SPC s d`, symbol docs → `SPC s s`, help system → `SPC s h` (e.g., `eldoc`, `describe-symbol`, `consult-info`, `sly-describe-symbol`).
