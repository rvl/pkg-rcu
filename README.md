This is a Nix package for [RCU](http://www.davisr.me/projects/rcu/).

## Product key

Your product key is part of the URL which you get redirected to after
purchasing RCU. It's the bit just after `download-`.

## Build, run, install

To build it, run:

```shell
$ cd ~/src/pkg-rcu
$ nix-build --argstr productKey CODE
```

To run the tool:

```shell
$ ./result/bin/rcu
```

To install it to your profile:

```shell
$ ./nix-env -i ./result
```

## Also build the user manual PDF

Building of the user manual is disabled by default because it will
pull in the rather large TexLive distribution as a dependency ...
and the RCU author provides a PDF anyway.

But you can enable `buildUserManual` if you like with:

```shell
$ nix-build --argstr productKey CODE --arg buildUserManual true
```

The manual PDF will be installed at `$prefix/share/doc/rcu`.

## Run from source with `nix-shell`

To get a Python development environment with all necessary
dependencies:

```shell
$ nix-shell --argstr productKey ""
[nix-shell:~/src/pkg-rcu]$ cd ~/rcu-r2021-001/rcu/src
[nix-shell:~/rcu-r2021-001/rcu/src]$ python main.py
```

## Troubleshooting

If the `rcu` executable from this package crashes, you may need to set
up environment variables for QT5. Googling the error message from QT
can often give some clues, or try the following tips.

### QT Platform Plugins

For this error message:

```
qt.qpa.plugin: Could not find the Qt platform plugin "xcb" in ""
This application failed to start because no Qt platform plugin could be initialized. Reinstalling the application may fix this problem.

Fatal Python error: Aborted
```

Try setting:

```bash
export QT_QPA_PLATFORM=xcb
```

### XCB GL Integration

For this error message:
```
qt.glx: qglx_findConfig: Failed to finding matching FBConfig for QSurfaceFormat(version 2.0, options QFlags<QSurfaceFormat::FormatOption>(), depthBufferSize -1, redBufferSize 1, greenBufferSize 1, blueBufferSize 1, alphaBufferSize -1, stencilBufferSize -1, samples -1, swapBehavior QSurfaceFormat::SingleBuffer, swapInterval 1, colorSpace QSurfaceFormat::DefaultColorSpace, profile  QSurfaceFormat::NoProfile)
Could not initialize GLX
Fatal Python error: Aborted
```

Try setting:

```bash
export QT_XCB_GL_INTEGRATION=none
```
