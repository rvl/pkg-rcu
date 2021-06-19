{ pkgs ? import <nixpkgs> {}
# Choose one of "pyproject" or "poetry"
, format ? "pyproject"
# Build LaTeX manual -- will download the full texlive if enabled
, buildUserManual ? false
# Supply --argstr productKey CODE to download
, productKey ? null
}:

let
  pname = "rcu";
  version = "r2021.001";
  name = "${pname}-${version}";
  downloadUrl = code: "https://files.davisr.me/projects/rcu/download-${code}/release/${name}-source.tar.gz";

  pkg =
    { lib, fetchzip, pkgconfig, makeDesktopItem
    , xorg, qt5, libXinerama, libxkbcommon, xkeyboardconfig
    , libsForQt5
    , buildPythonApplication, pytest, pyside2, pyside2-tools
    , paramiko, pdfrw, qtpy, pillow
    , texlive, pygments, which }:

    buildPythonApplication rec {
      inherit pname name version format;

      src = if productKey != null
        then
          fetchzip {
            name = "${pname}-source";
            url = downloadUrl productKey;
            sha256 = "1b8j41hz9k13dbs9hmmbif5w7m849wi3lk5hz3cjpcqcw6nj2sp0";
          }
        else
          throw ''
            You need to provide "--argstr productKey CODE" to the nix-build command-line.
          '';

      postPatch = ''
        # apply recommended directory naming conventions
        mv src rcu

        # make an entrypoint
        sed -i -e "s/if __name__ == '__main__'/def main()/" rcu/main.py

        # create packages
        touch rcu/__init__.py rcu/panes/deviceinfo/__init__.py

        # make imports relative to the top-level rcu package
        sed -i -e "s/^\([[:space:]]*\)import \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from . import \2/g" rcu/*.py
        sed -i -e "s/^\([[:space:]]*\)import \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from .. import \2/g" rcu/*/*.py
        sed -i -e "s/^\([[:space:]]*\)import \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from ... import \2/g" rcu/*/*/*.py
        sed -i -e "s/^\([[:space:]]*\)import \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from .... import \2/g" rcu/*/*/*/*.py
        sed -i -e "s/^\([[:space:]]*\)from \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from .\2/g" rcu/*.py
        sed -i -e "s/^\([[:space:]]*\)from \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from ..\2/g" rcu/*/*.py
        sed -i -e "s/^\([[:space:]]*\)from \(log\|svgtools\|worker\|model\|controllers\|panes\)/\1from ...\2/g" rcu/*/*/*.py
        sed -i -e "s/^\([[:space:]]*\)from \.rcu/\1from rcu.model.rcu/g" rcu/*/*.py
        sed -i -e "s/^\([[:space:]]*\)from \./\1from ..panes/g" rcu/panes/__init__.py

        cp --no-preserve=all ${./setup.cfg} setup.cfg
        cp --no-preserve=all ${./pyproject.toml} pyproject.toml

        sed -i 's|src/|rcu/|g' Makefile
      '';

      nativeBuildInputs = [
        pkgconfig
        pyside2-tools
        qt5.wrapQtAppsHook
      ] ++ lib.optionals buildUserManual [
        texlive.combined.scheme-full
        pygments
        which
      ];

      buildInputs = [ pyside2-tools ]
          ++ [ xorg.libxcb ]
          ++ (with libsForQt5; [ qtx11extras ]);

      LD_LIBRARY_PATH = lib.makeLibraryPath xlibs;
 
      xlibs = [
        xorg.libxcb
        xorg.xcbproto
        xorg.xcbutil
        xorg.xcbutilwm
        xorg.libXinerama
        libxkbcommon
        libXinerama
      ];

      propagatedBuildInputs = xlibs ++ [
        pyside2
        paramiko
        pdfrw
        qtpy
        pillow
      ];

      checkInputs = [ pytest ];
      doCheck = false;
      
      # Prevent double-wrapping with python and qt
      # https://nixos.org/manual/nixpkgs/stable/#ssec-gnome-common-issues-double-wrapped
      dontWrapQtApps = true;
      preFixup = ''
        # Wayland support is broken.
        qtWrapperArgs+=(--set QT_QPA_PLATFORM xcb)
        qtWrapperArgs+=(--set QT_XKB_CONFIG_ROOT "${xkeyboardconfig}/share/X11/xkb")

        # Add QT wrapper args to Python wrapper args
        makeWrapperArgs+=("''${qtWrapperArgs[@]}")
      '';
      QT_QPA_PLATFORM_PLUGIN_PATH = "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins";

      postBuild = lib.optionalString buildUserManual ''
        make doc
      '';

      postInstall = ''
        mkdir -p $out/share/applications
        cp -v $desktopItem/share/applications/* $out/share/applications
        
        for size in 64 128 256 512; do
          name="''${size}x$size"
          target=$out/share/icons/hicolor/$name/apps
          prefix=$src/icons/$name/rcu-icon-$name
          for fmt in png svg; do
            install -D $prefix.$fmt $target/rcu.$fmt
            test -f $prefix-withpen.$fmt && install -D $prefix-withpen.$fmt $target/rcu-withpen.$fmt || true
          done
        done
      '' + lib.optionalString buildUserManual ''
        install -D manual/manual.pdf $out/share/doc/rcu/manual.pdf
      '';

      desktopItem = makeDesktopItem {
        name = "rcu";
        exec = "rcu";
        icon = "rcu";
        desktopName = "RCU";
        genericName = "reMarkable Tablet Tool";
        categories = "Graphics;Viewer;Utility;";
      };

      meta = with lib; {
        homepage = "http://www.davisr.me/projects/rcu/";
        description = "RCU tool for reMarkable";
        platforms = platforms.linux;
        maintainers = with maintainers; [ rvl ];
      };
    };
in
  pkgs.python38.pkgs.callPackage pkg { }
