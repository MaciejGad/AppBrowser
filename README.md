# AppBrowser

AppBrowser is a simple and efficient web browser application for iOS. This README will guide you through the usage of `Configurator.swift` to configure AppBrowser.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)

## Installation

To install AppBrowser, clone the repository and open the project in Xcode:

```sh
git clone https://github.com/MaciejGad/AppBrowser.git
cd AppBrowser
open AppBrowser.xcodeproj
```

## Usage

To run the application, select the target device or simulator in Xcode and press the `Run` button or use the shortcut `Cmd + R`.

## Configuration

To configure AppBrowser, you need to update the `config.json` file with the following values:

```json
{
    "display_name": "AppBrowser",
    "app_url": "https://github.com/MaciejGad/AppBrowser",
    "bundle_id": "pl.maciejgad.AppBrowser",
    "biometric_authentication": true,
    "icon_name": "f096",
    "icon_background_color": "#3498db",
    "exception_list_url": "https://raw.githubusercontent.com/MaciejGad/AppBrowser/refs/heads/main/AppBrowser/url_exceptions.json" 
}
```

After updating the `config.json` file, run the `configurator.swift` script from the command line to apply the configuration:

```sh
./configurator.swift
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Author

AppBrowser was built by Maciej Gad. For more information, visit [maciejgad.pl](https://maciejgad.pl).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.