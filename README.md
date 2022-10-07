# IDEInstall
An application to install components in Delphi/C++Builder IDE
Requirements: modified version of Jcl.
Website: <https://www.trichview.com/ideinstall/>

## Description

This application can install packages (containing source code or trial units of VCL and FireMonkey components) in Delphi and C++Builder IDE.

Supported version of Delphi: from 5 to 11 Alexandria.

Supported version of C++Builder: from 6 to 11 Alexandria.

Exception: C++Builder-only packages for BDS 2006 are not supported.

Supported platforms: Windows (32-bit and 64-bit), macOS (64-bit Intel and ARM), Android (32-bit and 64-bit)

## Features

* the installer installs a set of multiple packages
* a set may contain either Delphi or C++Builder packages
* a set of Delphi packages can be installed in C++Builder as well (so it recommended)
* some or all packages in a set may be trial packages
* all options are set in a configuration file, end users do not need to make any unnecessary choices in UI
* minimal output on success, full log on compilation errors
* removing paths to alternative versions of packages from IDE library (to avoid version conflict); the user can view deleted paths when the installer completes its work
* creating compiled files in the same locations as IDE would create them (exceptions: BDS 2006 and Delphi package for RAD Studio 2007) so the user can recompile these packages in IDE later
* installing packages requiring third-party packages; even if third-party package's DCP files are not in the standard location; even if third-party package's DCP file names include version numbers of third-party product
* integrating CHM help files in RAD Studio IDE (for XE8 and newer)
* option for Windows 32-bit platform: adding paths either to source code or to pre-compiled units

## Screenshots

![Choosing IDE](https://www.trichview.com/shots/ideinstall/choose-ide.png)

![Installing](https://www.trichview.com/shots/ideinstall/installing.png)
