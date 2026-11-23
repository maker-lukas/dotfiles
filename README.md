# Hyprland dotfiles

Stow repo for my Hyprland + Quickshell dotfiles Everything is under one folder so editors and Wakatime see a single project.

Demo: https://www.youtube.com/watch?v=FUDzExruJNg

## filebase

```
dotfiles/
├── bootstrap.sh
├── fastfetch/
│   └── .config/
│       └── fastfetch/
│           └── config.jsonc
└── hyprland/
    └── .config/
        ├── hypr/
        │   └── hyprland.lua
        ├── quickshell/
        │   ├── shell.qml
        │   └── workspaces.json
        └── Unknown Organization/
            └── quickshell.conf
```

Each package mirrors `$HOME/.config`, so a file at
`hyprland/.config/hypr/hyprland.lua` is linked to `~/.config/hypr/hyprland.lua`,
and `fastfetch/.config/fastfetch/config.jsonc` is linked to
`~/.config/fastfetch/config.jsonc`.

Hyprland 0.57+ reads `hyprland.lua` and ignores `hyprland.conf`, so there is
intentionally no `.conf` in this repo.

## Install

```sh
cd ~/dotfiles
./bootstrap.sh
```

Other modes:

```sh
./bootstrap.sh restow
./bootstrap.sh unlink
```

Or run Stow directly:

```sh
cd ~/dotfiles
stow --target="$HOME" --verbose hyprland
```

## Adding a config

1. Move the real file from `~/.config/...` into the matching path inside
   `hyprland/.config/...` (don't copy it — Stow needs the original gone).
2. Run `./bootstrap.sh restow`.
3. Commit.

If Stow complains about an existing file, that file wasn't moved out of the
way. Move it into the repo first.

---

Made by Lukas with <3