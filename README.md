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
