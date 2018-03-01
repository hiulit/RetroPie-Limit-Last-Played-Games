# Retropie Limit Last Played Games
A tool for RetroPie to limit the number of 'last played' games.

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/Retropie-Limit-Last-Played-Games
cd Retropie-Limit-Last-Played-Games/
sudo chmod +x retropie-limit-last-played-games.sh
```

## Usage

```
./retropie-limit-last-played-games.sh [OPTIONS]
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: ./retropie-limit-last-played-games.sh.sh [OPTIONS]

Use './retropie-limit-last-played-games.sh --help' to see all the options.
```

## Options

* `--help`: Print the help message and exit.
* `--nth`: Set number of 'last played' games to limit per system (10 by default).
* `--systems`: Show dialog to select systems to limit.
* `--version`: Show script version.

## Examples

### `--help`

Print the help message and exit.

#### Example

`./retropie-limit-last-played-games.sh --help`

### `--nth [OPTIONS]`

Set number of 'last played' games to limit per system (10 by default).

#### Options

* `[number]`: Number to limit 'last played' games per system.

#### Example

`./retropie-limit-last-played-games.sh --nth 25`

### `--systems`

Show dialog to select systems to limit.

#### Example

`./retropie-limit-last-played-games.sh --systems`

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
