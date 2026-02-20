# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
- Wire CommonRoom trigger → WaveManager.start_encounter()
- Hook Combat outcome → EndScreen.setup(victory, reason)
- Web export to `docs/` + enable GitHub Pages
- Basic placeholder tileset and audio

## [0.1.1] - 2026-02-20
- Fixed node path mismatches across scenes (Title, Options, CharacterCreation, Credits, EndScreen, HUD, GameWorld)
- Added missing GameWorld children (HUD instance, WaveManager, TileMap, Camera2D)
- Made GameWorldController editor-safe in `_ready()`
- Fixed GameManager parse error (explicit return type on `create_player_character`)
- Added single-threaded Web export preset (avoids COOP/COEP issues on GitHub Pages)
- Added version label to TitleScreen and `application/config/version` = `0.1-dev`

## [0.1.0] - 2026-02-19
- Initial Godot 4.2 project skeleton
- Core scripts: GameManager, CombatManager, WaveManager, Unit, HUD, CompanionAI
- Data-driven JSON: character classes, abilities, enemies, items
- Scenes: Title, Options, Credits, CharacterCreation, GameWorld, HUD, EndScreen, Unit
