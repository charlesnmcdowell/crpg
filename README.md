# CRPG Demo (Godot 4.2)

Playable top-down 2D CRPG prototype targeting mobile-friendly Web export.

- Live (after export): https://charlesnmcdowell.github.io/crpg/
- Changelog: ./CHANGELOG.md

## Export (Windows)
1. Open project in Godot 4.2
2. Editor → Manage Export Templates → install for 4.2
3. Project → Export → Add → Web
4. Export to `docs/index.html`
5. Commit + push `docs/`
6. GitHub Pages: Settings → Pages → Deploy from branch → `main` / `docs`

## Notes
- Web preset uses single-threaded mode to work on GitHub Pages
- Touch-first controls + desktop mouse supported
