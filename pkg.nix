{ lib, fetchzip, pkgconfig, makeDesktopItem
, xorg, qt5, libXinerama, libxkbcommon
, buildPythonApplication, pytest, pyside2, pyside2-tools
, paramiko, pdfrw, qtpy, pillow
, texlive, pygments, which
# Build LaTeX manual -- will download the full texlive if enabled
, buildUserManual ? false
# Supply --argstr productKey CODE to download
, productKey ? null
}:

buildPythonApplication rec {
  pname = "rcu";
  version = "r2021.001";
  name = "${pname}-${version}";

  src = if productKey != null
    then
      fetchzip {
        name = "${pname}-source";
        url = "https://files.davisr.me/projects/rcu/download-${productKey}/release/${name}-source.tar.gz";
        sha256 = "1b8j41hz9k13dbs9hmmbif5w7m849wi3lk5hz3cjpcqcw6nj2sp0";
      }
    else
      throw ''
        You need to provide "--argstr productKey CODE" to the nix-build command-line.
      '';

  format = "pyproject";

  patches = [ ./packages.patch ];
  postPatch = ''
    # Apply recommended directory naming conventions
    mv src rcu
    sed -i 's|src|rcu|g' Makefile rcu.py

    # Add setuptools
    cp --no-preserve=all ${./setup.cfg} setup.cfg
    cp --no-preserve=all ${./pyproject.toml} pyproject.toml
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

  buildInputs = [ pyside2-tools ];

  propagatedBuildInputs = [
    xorg.libxcb
    xorg.xcbproto
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.libXinerama
    libxkbcommon
    libXinerama

    pyside2
    paramiko
    pdfrw
    qtpy
    pillow
  ];

  postBuild = lib.optionalString buildUserManual ''
    make doc
  '';

  checkInputs = [ pytest ];
  doCheck = false;

  # Prevents this error in the nix-shell:
  #   qt.qpa.plugin: Could not find the Qt platform plugin "xcb" in ""
  QT_QPA_PLATFORM_PLUGIN_PATH = "${qt5.qtbase.bin}/lib/qt-${qt5.qtbase.version}/plugins";

  # Prevent double-wrapping with python and qt
  # https://nixos.org/manual/nixpkgs/stable/#ssec-gnome-common-issues-double-wrapped
  dontWrapQtApps = true;
  preFixup = ''
    # Add QT wrapper args to Python wrapper args
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  desktopItem = makeDesktopItem {
    name = "rcu";
    exec = "rcu";
    icon = "rcu";
    desktopName = "RCU";
    genericName = "reMarkable Tablet Tool";
    categories = "Graphics;Viewer;Utility;";
  };

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

  meta = with lib; {
    homepage = "http://www.davisr.me/projects/rcu/";
    description = "RCU tool for reMarkable";
    platforms = platforms.linux;
    maintainers = with maintainers; [ rvl ];
  };
}
