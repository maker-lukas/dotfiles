## Stuff i want:

current open apps
media player with mrpis (Mainly for spotify) with shuffle and repeat buttons, and links for the artist/song/album basically a copy of my spotify overlay app
desktop switcher (mouse scroll changes desktop)
clock - shows date and hour like "June 4 - 8:22pm", click it to show a little calendar
easy screenshots and screen recording no OBS - want a little ui to choose: save to file or just save to clipboard
system tray icons (if right clicked you can see the menus)
hyprland in monocle mode
clean and consistent
cool animations / everything is smooth
good login screen (greeter) AND lock screen AND idle handling (auto lock / sleep / dim after a while)
good power settings eg: logout, shutdown, sleep.
app launcher (built in quickshell, for consistency + versatility)
dekstop overview?
open links in apps opens the tab and fucuses on the browser (Ive had an issue that if i open a link like in slack in opens in the browser but asits in another desktop i dont see the website i have to go to the other desktop and see the tab i want that it auto focuses on the browser)
good notifications (with do not disturb toggle)
sound controll - just an icon, then on click/hover the full settings: per-app volume + mic + output device switching
wifi picker - simple like kde (status icon + click to scan/connect)
OSD popups - little floating indicator when changing volume/brightness. styling undecided: either kde-style center of screen, or floating on the left/right edge

## maybe / not sure where to put:

clipboard history - i use it really often, but maybe not on the main panel/rail. could live in a flyout or a settings flyout
keyboard layout switch - not really necessary, i only use Dvorak and US for very small things. could just be a keybind or a minimal setting
bluetooth - not that important, can live in a flyout "settings" panel instead of the main rail

## notes:

setup: single monitor, laptop, but almost always stationary so i dont really use the battery (planning to buy a new laptop in the mid-near future, so keep battery indicator in mind but its not a priority right now)

apps i bassically always have open:
- zen browser
- file browser
- slack
- spotify

apps i have when i'm working on projects (which is almost everyday):
- kicad
- vscodium
- obsidian
- ghostty

this ↑ is just to understand my normal workflow

I want hyprland on monocle which i alredy said above. I want it like that because i basically almost always have a window on its max size and sometimes split screen so i want something that is like a normal kde window manager (my reasons to use hyprland are not the same as almost every hyprland user) so i want basically every window max with and height but i still want to be able to like split screen and resize them.

## which layer each thing lives in:

so i keep track of where stuff actually goes (it's not all quickshell):

- quickshell ui: bar/sidebar, flyouts, app launcher, OSD, notifications, lock screen, clock/calendar, sound + wifi pickers, clipboard ui
- hyprland config: monocle behavior, keybinds, window rules, the "open links auto-focus the browser" thing (#16) - this is a window rule / dispatcher, not quickshell
- external helpers (quickshell just triggers them): screenshots (grim/slurp), screen recording (wf-recorder), greeter (greetd), power (loginctl/systemctl), brightness (brightnessctl)

## Current style ideas:

**side bar with flyout open apps + top flyout for stuff**:
A always on side bar with switch desktops and status icons then a flyout in the center with a open animation with all the current open apps. Then another flyout in the top center with like mpris media player and recent notifications (simial to the gnome only the center flyout)

**top bar with side open apps**:

a top bar with desktop switcher in the top left center a clock and click and its a flyout same as above then stats on top right similar to gnome everything besides there is a app dock on the left that is hidden until hover.

plan: don't decide on paper - prototype the sidebar rail + one flyout first (idea #1) since it's the harder layout. once the flyout animation feels right i'll know if i love it.

declutter note: keep the always-visible rail to ~4-5 essentials (workspaces, sound, network, clock). push secondary stuff (bluetooth, keyboard layout, clipboard) into a settings flyout so it's not cluttered like the kde bar below.

Image of my current kde bar looks like its a bit too cluttered mainly on the status's and stuff
![current kde](Screenshot_20260604_194447.png)
