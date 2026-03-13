# MYMACS

## Requirements

* Emacs >= 30.0

## Updates

I use straight for package management.

```
M-x straight-thaw-versions
M-x straight-pull-all
M-x straight-freeze-versions
```

## Dependencies

**Required**
- ripgrep (search)
- curl (HTTP for gptel/org-caldav; streaming)
- libvterm toolchain (libvterm, cmake, pkg-config) for vterm
- enchant2 (+ enchant2-devel) for jinx spell-checking

**Optional / feature-specific**
- aspell or hunspell (fallback spell backend if enchant is unavailable)

