CHANGELOG
---
qbs-autoproject

**2.1.0**

- Fix probes stuck in infinite loop when changing configuration

**2.0.1**

- Fix issue with autodetected Qt path is not sometimes propagated to other probes.

**2.0.0**

New features:

- Front end file is now separate from probes and logic and contains only configuration properties
- Rewritten default set of custom items (now supports profiling, static building etc.)
- Added Qt auto-detection
- Added C++ Standard Headers auto-detection
- Improved "Tree" output format (now default)
- Added new output format "Shallow" that limits the "Tree" format to one sub-project level
- Works with Qbs 1.12 and Qt 5.11.1

Other changes:

- Fixed few subtle bugs in Probes
- Fixed few missing log messages
- Removed tests from Probes
- Unified formatting

**1.1.1**

- Updated example path to use Qt 5.10.1
- Fixed missing functions prefix in a print of 4/11 Probe
- Changed remaining console.info to functions.print for consistency

**1.1.0**

- Updated to work with Qbs 1.1
- Supressed warnings about missing .moc files from includes
- Dozens of fixes from static analysis

**1.0.1**

New features:

- cppStandardHeadersPath configuration option to correctly recognize standard headers when resolving dependencies.
Resolved Issues:

Other changes:

- Fixed an issue with product in root project was not written out to the output project file.
- Fixed an issue with file handles left open that could lead to too many files open on some systems.
- Fixed an issue with project not being written when dependencies were disabled.
- Fixed various inconsistencies with example patterns.

**1.0.0**

- Initial release
