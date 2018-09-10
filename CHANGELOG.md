# Changelog

## [Unreleased]

* Up to date

## [2.0.0] - 2018-09-07

### Added

* Option to install/Uninstall the script from EmulationStation's RetroPie menu.
* GUI mode.
* Debug mode.
* Log files.

### Fixed

* Uncommented code preventing to actually remove 'last played' games.
* Fixed [#1 - Only show systems that have a gamelist.xml](https://github.com/hiulit/RetroPie-Limit-Last-Played-Games/issues/1).

### Changed

* Refactored the code to create backups. Now the folder is called `gamelist-backups` (inside the `$SYSTEM_ROMS` folder) and contains all the game lists backups, named `[DATE]-gamelist-backup.xml`.
* Added more `error/success` output messages.
* Better control of what games have to be processed.


## [1.0.0] - 2018-03-01

* Released version [1.0.0](https://github.com/hiulit/RetroPie-Limit-Last-Played-Games/releases/tag/1.0.0).
