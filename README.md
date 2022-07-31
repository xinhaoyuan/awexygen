# <img src="icon.svg" alt="Awexygen icon" width="64"/>Awexygen

Standalone desktop application with the UI framework decoupled from awesome window manager (AwesomeWM for short), runnable in other window managers and desktop environments.

## Disclaimer

Awexygen is a hobby project, and it is not part of AwesomeWM.

Awexygen leverages LGI to simulate a subset of AwesomeWM native runtime to run the UI framework without becoming another window manager.
It might behave differently to the actual AwesomeWM runtime on certain aspects (see below).
Also, performance may suffer from the simulation.

## Usage

Before running Awexygen, you need to install Lua and LGI with Gtk 3 (and optionally `librsvg`).
Awexygen also needs AwseomeWM's assets, but you don't have to install it:
You can clone it from http://github.com/awesomewm/awesome and set env var `AWESOMEWM_ASSETS_DIR` to the cloned directory when running Awexygen.

To run Awexygen in command line, execute:
```
[path to awexygen] [entry] [other arguments...]
```

Entry can be a Lua script path or a module name, depending on whether it contains a `/` character or not.
If the entry is not specified, module `awexygen_rc` will be loaded. If the module/script failed to load, an error message would be printed.

Awexygen will search modules in various paths (see the `awexygen` script), but the recommended place is the directory of your AwesomeWM config (i.e. `$HOME/.config/awesome`).

For exmaples, check the modules in the examples directory, and run them with e.g.
```
./awexygen examples/theme.lua
```

You can also install the desktop entry using `utils/install_desktop.sh`, which would generate `awexygen.desktop` in your local application directory.

## Compatibility

I developed Awexygen with AwesomeWM 4.3-git, LGI 0.9.2 with Gtk 3, and Lua 5.1; No testing has been done with other versions.

### What are supposed to work

  - `lgi`
  - `gears`
  - `drawin` and `wibox` (mostly)

    - Supported attributes:
      `x`, `y`, `width`, `height`, `type`,
      `bg`, `fg`, `ontop`, `widget`, `visible`,
      `shape_clip`, `shape_bounding`, `shape_input`
    - Extra attributes: `title`, `icon_name`, `icon_pixbuf`, `resizable`, `decorated`, `gtk_layout`
    - Setting attributes `border_width`, `border_color`, `opacity` is ignored.
      Use `wibox.container.background` on the main widget instead.

  - `beautiful`
  - `naughty`
  - `awful.spawn` except StartupNotification.
  - `screen`: Screen listing and configuration monitoring with the `list` signal.
  - `keygrabber`/`mousegrabber` will capture only key/mouse events to any windows of the application.

### What are not supposed to work

  - Window managing and desktop environment related functionalities (e.g. `root`, `client`, `tag`).
  - Global key/mouse binding; grabbing is limited (see `keygrabber`/`mousegrabber` above).
  - `systray`
  - `selection`

Note that you may be able to do some of the above using external programs (with `awful.spawn`), external libraries (with LGI), and/or native Gtk widgets (see below).

### Using Gtk widgets

For adventures, Awexygen provides two widget classes `awexygen.wrapped_gtk_widget.direct` and `awexygen.wrapped_gtk_widget.offscreen` to embed Gtk widgets into the AwesomeWM UI hierarchy.
Each class has capability and limitation. See `examples/wrappped_gtk_widget.lua` for example.

## License

This project is licensed under GNU General Public License v3.
