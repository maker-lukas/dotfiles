# Hyprland dotfiles

GNU Stow repo for my Hyprland + Quickshell setup. Everything lives under one
folder so editors and Wakatime see a single project (`hyprland-dotfiles`).

## Layout

```
dotfiles/
├── bootstrap.sh              # install / unlink / restow helper
└── hyprland/                  # the Stow package
    └── .config/
        ├── hypr/              # hyprland.conf, hyprland.lua
        ├── quickshell/        # shell.qml, workspaces.json
        ├── my_quickshell/     # experimental QML panels
        └── Unknown Organization/
            └── quickshell.conf
```

The `hyprland/` package mirrors `$HOME/.config`, so a file at
`hyprland/.config/hypr/hyprland.conf` is linked to
`~/.config/hypr/hyprland.conf`.

## Install

```sh
cd ~/dotfiles
./bootstrap.sh            # stow --verbose --target=$HOME hyprland
```

Other modes:

```sh
./bootstrap.sh dry-run    # preview, change nothing
./bootstrap.sh restow     # re-link after adding/removing files
./bootstrap.sh unlink     # remove the symlinks, keep this repo
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

## Wakatime

`.wakatime-project` pins every file in this repo to the `hyprland-dotfiles`
project. Open files via their real path under `~/dotfiles` (editors usually
resolve symlinks to it automatically) so tracking stays consistent.

## Notes

- `~/.config/quickshell/hyprquickshot/` is a separate upstream git repo and is
  deliberately **not** vendored here; only the files I actually edit are
  tracked.
- `hyprland.conf` has `exec-once = quickshell`. `hyprland.lua` also starts
  Quickshell via `hl.exec_cmd("qs")` on `hyprland.start`. Keep only one of the
  two, depending on which config file Hyprland loads.
- Third-party configs (foot, rofi, GTK, etc.) can be added later either as
  more files in this package or as separate packages such as `terminal/`.
