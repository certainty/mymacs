# MYMACS

## Requirements

* Emacs >= 30.0

## Dependencies

**Required**
- ripgrep (search)
- curl (HTTP for gptel/org-caldav; streaming)
- libvterm toolchain (libvterm, cmake, pkg-config) for vterm
- enchant2 (+ enchant2-devel) for jinx spell-checking

**Optional / feature-specific**
- aspell or hunspell (fallback spell backend if enchant is unavailable)
- texlive-scheme-basic, texlive-koma-script, texlive-scrlttr2copy, texlive-latex-bin, texlive-fonts-recommended (Org/LaTeX export)

## Highlights

- Context-aware setup (work/private) with separated features; optimized for coding and notes. AI via gptel (OpenRouter/Ollama privately, Copilot only at work).
- Fast startup (native-comp JIT, GC tuning) and tree-sitter under `~/.config/emacs/tree-sitter`.
- Org/GTD: custom agendas (Today, Projects, Weekly Review, Decision/Event logs, Done log), CalDAV sync, datetree logging, refiling helpers, right-side agenda placement.
- Consistent keybindings: leader `SPC` with `C-c` as global alternative; intent-based prefixes (`v` VC, `o` org, `a` AI, etc.), Popper toggles on `SPC b p p` / `C-c p`.
- VC: Git via built-in VC/Agitate plus Magit (`SPC v s/b/l/L`), diff-hl, smerge helpers.
