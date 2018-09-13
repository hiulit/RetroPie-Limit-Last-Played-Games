# Changelog

## [Unreleased]

* Up to date

## [2.1.1] - 2018-09-13

## Fixed

* Issue with duplicate game names but different `<lastplayed>` tags in `gamelist.xml'`. Now the script takes both the game name and its `<lastplayed>` tag to avoid duplicates. **If there are more than one game with same name and `<lastplayed>` tag, the script won't work.**
* Escape game names with single quotes in `gamelist.xml'`.
* Escape ampersands (`&`) in `gamelist.xml'`.

## [2.1.0] - 2018-09-12

### Added

* Dialog asking if the user wants to restart EmulationStation when the script is done.
* Output message for the games that will be shown in the 'last played' section.

### Fixed

* When there are duplicated <lastplayed> tags in different games the script crashes. Now, if the scripts find duplicates, it looks for the game's name (it should be different).

## [2.0.0] - 2018-09-07

### Added

* Option to install/Uninstall the script from EmulationStation's RetroPie menu.
* GUI mode.
* Debug mode - To test the script. No harm will done to the gamelists ;)
* Log files - Found in `/home/pi/Retropie-Limit-Last-Played-Games/logs`).

### Fixed

* Uncommented code preventing to actually remove 'last played' games.
* Fixed [#1 - Only show systems that have a gamelist.xml](https://github.com/hiulit/RetroPie-Limit-Last-Played-Games/issues/1).

### Changed

* Refactored the code to create backups. Now the folder is called `gamelist-backups` (inside the `$SYSTEM_ROMS` folder) and contains all the game lists backups, named `[DATE]-gamelist-backup.xml`.
* Added more `error/success` output messages.
* Better control of what games have to be processed.


## [1.0.0] - 2018-03-01

* Released version [1.0.0](https://github.com/hiulit/RetroPie-Limit-Last-Played-Games/releases/tag/1.0.0).
