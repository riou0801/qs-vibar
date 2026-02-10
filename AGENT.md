# AGENT.md — Project Specifications (qs-vibar)

## Project Overview
A Quickshell-based panel for Wayland/Sway with a Catppuccin Mocha aesthetic.
Layout mirrors a Waybar-style bar:
- Left: Workspace indicators (Sway/I3 IPC)
- Center: MPRIS media info (hidden when no active player)
- Right: System tray

All non-column background is transparent; each column is a rounded, bordered pill.

## Runtime Environment
- Wayland compositor: Sway
- Toolkit: Quickshell (Qt/QML)
- Icon handling: System tray items use Qt icon lookup; ensure Qt icon theme is available.
- Nerd Font glyphs are used for MPRIS status icons.

## Files
- `bar.qml`: Main bar implementation (entrypoint when launching `qs -p ~/.config/quickshell/bar.qml`)

## Visual Design
### Palette (Catppuccin Mocha)
- Base: `#1e1e2e`
- Surface0: `#313244`
- Surface1: `#45475a`
- Overlay0: `#6c7086`
- Text: `#cdd6f4`
- Subtext1: `#bac2de`
- Lavender (accent): `#b4befe`
- Red (urgent): `#f38ba8`

### Styling Rules
- Panel background: fully transparent
- Each column is a rounded rectangle:
  - `radius: 8`
  - `border.width: 1`
  - `border.color: overlay0`
  - `color: surface0`

## Layout Rules
- Workspace column pinned left
- Tray column pinned right
- MPRIS column centered, width shrinks to content
- Padding and spacing:
  - `barPadding: 6`
  - `colPaddingX: 8`
  - `colPaddingY: 4`
  - `colSpacing: 6`
  - `iconSize: 18`

## Workspace Behavior
- Uses `Quickshell.I3` integration for Sway workspaces.
- `focused` workspace uses Lavender background, dark text.
- `active` workspace uses Surface1 background.
- `urgent` workspace gets Red border.

## MPRIS Behavior
- Uses `Quickshell.Services.Mpris`.
- Picks the first `isPlaying` player; falls back to first player if none playing.
- Hidden when no player is available.
- Displays:
  - Nerd Font status icon: `` (playing) or `` (paused)
  - Track text: `"Artist - Title"`
- Column width auto-sizes using `TextMetrics`.

## System Tray Behavior
- Uses `Quickshell.Services.SystemTray`.
- Icons rendered with `IconImage`.
- Right-click opens tray menu if available.
- Left-click activates item unless it is menu-only.

## Notes / Caveats
- Qt icon themes must be available for tray icons.
- Nerd Font must be installed for MPRIS glyphs to render.
- Quickshell may warn if built against a different Qt version; rebuild if needed.

## Repo Name
- GitHub repository: `qs-vibar`
