# Hyprland dotfiles

GNU Stow repo for my Hyprland + Quickshell setup. Everything lives under one
folder so editors and Wakatime see a single project (`hyprland-dotfiles`).

## Layout

```
dotfiles/
├── bootstrap.sh              # install / unlink / restow helper
├── fastfetch/                 # Stow package: fastfetch config
│   └── .config/
│       └── fastfetch/
│           └── config.jsonc  # generated with fastfetch --gen-config
└── hyprland/                  # Stow package: Hyprland + Quickshell
    └── .config/
        ├── hypr/
        │   └── hyprland.lua   # upstream v0.57.2 example + Quickshell autostart
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

- `hyprland.lua` is the stock example from Hyprland `v0.57.2`, with one added
  block that starts Quickshell on `hyprland.start`. To refresh it on upgrade:

  ```sh
  curl -fsSL https://raw.githubusercontent.com/hyprwm/Hyprland/v0.57.2/example/hyprland.lua \
    -o ~/dotfiles/hyprland/.config/hypr/hyprland.lua
  ```

  then re-add the autostart block if you still want it.
- `~/.config/quickshell/hyprquickshot/` is a separate upstream git repo and is
  deliberately not vendored here.
- Old experimental `~/.config/my_quickshell/` was removed. VSCodium may still
  show stale entries in its recent-workspaces/history; those are harmless
  editor metadata, not configs.
- To refresh the fastfetch config for a new fastfetch version:

  ```sh
  fastfetch --gen-config ~/dotfiles/fastfetch/.config/fastfetch/config.jsonc
  ```

- Other configs (foot, rofi, GTK, etc.) can be added later as more files in
  an existing package or as separate packages such as `terminal/`.
