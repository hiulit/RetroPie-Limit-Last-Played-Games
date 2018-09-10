# Retropie Limit Last Played Games
A tool for RetroPie to limit the number of 'last played' games.

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/Retropie-Limit-Last-Played-Games
cd Retropie-Limit-Last-Played-Games/
sudo chmod +x retropie-limit-last-played-games.sh
```

## Updating

```
cd /home/pi/Retropie-Limit-Last-Played-Games/
git pull
```

## Usage

```
./retropie-limit-last-played-games.sh [OPTIONS]
```

### Examples

`./retropie-limit-last-played-games.sh --nth 25 --systems`

This will set the number of 'last played' games to limit at 25 and then it will show a dialog from where it can be selected as many systems as needed.

`./retropie-limit-last-played-games.sh --nth 25 --systems --debug`

This will set the debug mode on. It's perfect for testing the script before actually 'harming' the gamelists.

`./retropie-limit-last-played-games.sh --gui`

This will start the GUI. It will ask you to enter a number to limit the number of 'last played' the games shown. Then it will ask you to choose the desired systems to apply that limit.

If no options are passed, you will be prompted with a usage example:

```
USAGE: ./retropie-limit-last-played-games.sh.sh [OPTIONS]

Use './retropie-limit-last-played-games.sh --help' to see all the options.
```

## Options

* `--help`: Print the help message and exit.
* `--install`: Install the script in EmulationStation's RetroPie menu.
* `--uninstall`: Uninstall the script in EmulationStation's RetroPie menu.
* `--nth`: Set number of 'last played' games to limit per system (10 by default).
* `--systems`: Show dialog to select systems to limit.
* `--gui`: Start the GUI.
* `--debug`: Set debug mode to test the script.
* `--version`: Show script version.

## Examples

### `--help`

Print the help message and exit.

#### Example

`./retropie-limit-last-played-games.sh --help`

### `--install`

Install the script in EmulationStation's RetroPie menu.

You'll find it as 'Limit Last Played Games'.

#### Example

`./retropie-limit-last-played-games.sh --install`

### `--uninstall`

Uninstall the script from EmulationStation's RetroPie menu.

#### Example

`./retropie-limit-last-played-games.sh --uninstall`

### `--nth [OPTIONS]`

Set number of 'last played' games to limit per system (10 by default).

#### Options

* `[number]`: Number to limit 'last played' games per system.

#### Example

`./retropie-limit-last-played-games.sh --nth 25`

The '--nth' option won't do anything ny itself. It always has to be accompanied, at least, by `--systems`.

### `--systems`

Show a dialog to select systems to limit.

#### Example

`./retropie-limit-last-played-games.sh --systems`

### `--gui`

Start the GUI.

It lets you use the script in a more friendly way.

#### Example

`./retropie-limit-last-played-games.sh --gui`

### `--debug`

Set debug mode to test the script.

No harm will done to the gamelists ;)

#### Example

`./retropie-limit-last-played-games.sh --debug`

### `--version`

Show script version.

#### Example

`./retropie-limit-last-played-games.sh --version`

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Contributing

See [CONTRIBUTING](/CONTRIBUTING.md).

## Authors

* Me 😛 [@hiulit](https://github.com/hiulit)

## Credits

Thanks to:

* All the people at the [RetroPie Forum](https://retropie.org.uk/forum/).

## License

[[LICENSE]](/LICENSE).
