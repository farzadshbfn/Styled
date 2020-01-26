# Styled

[![Version](https://img.shields.io/cocoapods/v/Styled.svg?style=flat)](https://cocoapods.org/pods/Styled)
[![License](https://img.shields.io/cocoapods/l/Styled.svg?style=flat)](https://cocoapods.org/pods/Styled)
[![Platform](https://img.shields.io/cocoapods/p/Styled.svg?style=flat)](https://cocoapods.org/pods/Styled)

Styled is a Type-Safe accessibility & theme management library in Swift.

* [Features](#Features)
* [Requirements](#Requirements)
* [Installation](#Installation)
  * [CocoaPods](#Cocoapods)
* [Example](#Example)
* [Usage](#Usage)
  * [Colors](#Colors)
  * [Fonts](#Fonts)
  * [Images](#Images)
  * [LocalizedString](#LocalizedString)

## Features

* Color management & synchronization with OS
* Font management & synchronization with OS
* String-Interpolation Localization
* Image management (per Localization or provided lazily by an external resource)

## Requirements

* iOS 10.0+
* XCode 11+
* Swift 5.1+ (Swift 5.0 compatible)

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate **Styled**
into your XCode project, simply add the Styled dependency to your Podfile.

```ruby
pod 'Styled'
```

### Carthage

Coming soon

### Swift Package Manager

Coming soon

## Example

To run the example project, clone the repo, and run `pod install` from the root directory.

> Don't forget to play with XCode accessibilities to see the results

## Usage

### Colors

This is how you'll be using Styled in a nutshell:

```swift
class CustomView: UIView {
    var customColor: UIColor { didSet { ... } }
}

let view = CustomView()

/// This is where all the magic happens
view.sd.backgroundColor = .background

/// It even works with custom defined variables 🤩
view.sd.customColor = .red

/// It also supports transformations 👽
view.sd.customColor = .blending(.red, with: .black) // Darkened red
```

Just by writing `view.sd.someColor` Styled will gaurantee that everytime the `ColorScheme` changes, your `someColor` variable will get updated with the latest value associated to the `Color` assigned.

This is how you define `Color`s:

```swift
extension Color {
    /// Color suitable for first-level labels
    static let label: Self = "label"

    /// Color suitable for second-level labels (i.e subtitle/description)
    static let secondaryLabel: Self = "label.secondary"

    /// Or custimized **red** for different schemes?
    static let red: Color = "red"
}

```

And this is how you define `ColorScheme`s:

```swift
extension Color {
    struct LightScheme: ColorScheme {
        func color(for color: Color) -> UIColor? {
            switch color {
            case .label: return UIColor.black
            case .secondaryLabel: return UIColor.gray
            default: fatalError("Uknown color \(color)")
            }
        }
    }

    struct DarkColorScheme: ColorScheme { ... }
}
```

And this is how you control which `ColorScheme` the app should use:

```swift
// You can manually control the ColorScheme
Styled.Config.colorScheme = Color.LightScheme()

// Or You can update it with system's theme
Styled.Config.onUserInterfaceStyleDidChange {
    switch $0 {
    case .dark: return .replace(with: Color.DarkScheme())
    default: return .replace(with: Color.LightScheme())
    }
}

// Or if you defined your colors in AssetsCatalog:
Styled.Config.colorScheme = Color.DefaultScheme()
```

And That's it! You can also take the same approach to define `Image`s, `Font`s and `LocalizedString`s.

### Fonts

Defining `Font`s and `FontScheme`s is almost the same as defining [Colors](#Colors).
For keeping the application in sync with device's font size, you can use the following method:

```swift
Styled.Config.onContentSizeCategoryDidChange { _ in .update }
```

`.update` will not change the current `FontScheme`, but will trigger a font update on all Styled elements.

### Images

Defining `Image`s and `ImageScheme`s is the same as defining [Colors](#Colors).

### LocalizedString

`LocalizedString` by default will look inside `Localizable.strings` & `Localizable.stringsdict`, but you can take ownership of Localization management just like `Color`s/`Font`s/`Image`s by defining your own `LocalizedStringScheme`s.

You can also define common words or sentences that you use throughout the application just like Color:

```swift
extension LocalizedString {
    static let ok: LocalizedString = "ok"
    static let cancel: LocalizedString = "cancel"
}
```

And just use it like other Styled variables:

```swift
label.sd.text = .ok
```

#### String-Interpolation

`LocalizedString` also supports string-interpolation to translate localizations.

**By default all interpolations will be replaced with `"%@"` before being queried**

For example the following interpolation:

```swift
label.sd.text = "lastIndex is \(count - 1))"
```

Will look inside `Localizable.strings` (or `Localizable.stringsdict` or your personalized `LoaclizedStringScheme`) for the key `"lastIndex is %@"`  to fetch its translation. So this is what inside `Localizable.strings` file should look like:

```swift
// English
"lastIndex is %@" = "lastIndex is %@";

// Persian
"lastIndex is %@" = "آخرین اندیس %@ است";
```

You can also customize the specifier inside the interpolation method to use something else instead of `"%@"`:

```swift
label.sd.text = "lastIndex is \(count - 1, specifier: "%d")"
```

And this will generate the key `"lastIndex is %d"`

You can always add your personalized functionalities to the `LocalizedString.StringInterpolation` to make your String-Interpolation localization suit your needs.

## Author

FarzadShbfn, farzad.shbfn@gmail.com

## License

Styled is available under the MIT license. See the LICENSE file for more info.
