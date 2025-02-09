<img src="output.png" alt="AppBrowser Icon" width="200px">

# AppBrowser
AppBrowser is a simple and efficient web browser application for iOS. This README will guide you through the usage of <code>configurator.swift</code> to configure AppBrowser.

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
    "exception_list_url": "https://raw.githubusercontent.com/MaciejGad/AppBrowser/refs/heads/main/AppBrowser/url_exceptions.json",
    "exception_list": [
        "https://maciejgad.pl"
    ]
}
```

Here are the details for each configuration option in the `config.json` file:

- `display_name`: The name of the application as it will appear on the home screen and within the app.
- `app_url`: The URL that will be loaded on start
- `bundle_id`: The unique identifier for the application, typically in reverse domain name notation.
- `biometric_authentication`: A boolean value (`true` or `false`) indicating whether biometric authentication (such as Face ID or Touch ID) is enabled.
- `icon_name`: The name of the icon to be used for the application. This should be a valid icon name from Font Awesome.
- `icon_background_color`: The background color of the application icon, specified in hexadecimal format.
- `exception_list_url`: The URL to a JSON file containing a list of URL exceptions that the browser should open internally 
- `exception_list`: An internal list of exceptions that the browser should handle differently. This can include URLs that should be opened within the app instead of an external browser.

These options allow you to customize the behavior and appearance of AppBrowser to suit your needs.

After updating the `config.json` file, run the `configurator.swift` script from the command line to apply the configuration:

```sh
./configurator.swift
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Author

AppBrowser was built by Maciej Gad. Maciej is a software developer with a passion for creating efficient and user-friendly applications. With a background in iOS development, Maciej has worked on various projects ranging from small utilities to large-scale applications. For more information, visit [maciejgad.pl](https://maciejgad.pl) or follow him on [GitHub](https://github.com/MaciejGad) and [LinkedIn](https://www.linkedin.com/in/gadmaciej/).


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.