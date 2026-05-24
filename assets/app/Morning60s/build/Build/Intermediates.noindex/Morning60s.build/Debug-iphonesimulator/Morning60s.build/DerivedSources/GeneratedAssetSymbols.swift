import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Group28" asset catalog image resource.
    static let group28 = DeveloperToolsSupport.ImageResource(name: "Group28", bundle: resourceBundle)

    /// The "Rectangle" asset catalog image resource.
    static let rectangle = DeveloperToolsSupport.ImageResource(name: "Rectangle", bundle: resourceBundle)

    /// The "bg-guang" asset catalog image resource.
    static let bgGuang = DeveloperToolsSupport.ImageResource(name: "bg-guang", bundle: resourceBundle)

    /// The "board" asset catalog image resource.
    static let board = DeveloperToolsSupport.ImageResource(name: "board", bundle: resourceBundle)

    /// The "cake1" asset catalog image resource.
    static let cake1 = DeveloperToolsSupport.ImageResource(name: "cake1", bundle: resourceBundle)

    /// The "cake2" asset catalog image resource.
    static let cake2 = DeveloperToolsSupport.ImageResource(name: "cake2", bundle: resourceBundle)

    /// The "cake3" asset catalog image resource.
    static let cake3 = DeveloperToolsSupport.ImageResource(name: "cake3", bundle: resourceBundle)

    /// The "cake4" asset catalog image resource.
    static let cake4 = DeveloperToolsSupport.ImageResource(name: "cake4", bundle: resourceBundle)

    /// The "cake5" asset catalog image resource.
    static let cake5 = DeveloperToolsSupport.ImageResource(name: "cake5", bundle: resourceBundle)

    /// The "cake6" asset catalog image resource.
    static let cake6 = DeveloperToolsSupport.ImageResource(name: "cake6", bundle: resourceBundle)

    /// The "ch1" asset catalog image resource.
    static let ch1 = DeveloperToolsSupport.ImageResource(name: "ch1", bundle: resourceBundle)

    /// The "ch2" asset catalog image resource.
    static let ch2 = DeveloperToolsSupport.ImageResource(name: "ch2", bundle: resourceBundle)

    /// The "ch3" asset catalog image resource.
    static let ch3 = DeveloperToolsSupport.ImageResource(name: "ch3", bundle: resourceBundle)

    /// The "ch4" asset catalog image resource.
    static let ch4 = DeveloperToolsSupport.ImageResource(name: "ch4", bundle: resourceBundle)

    /// The "ch5" asset catalog image resource.
    static let ch5 = DeveloperToolsSupport.ImageResource(name: "ch5", bundle: resourceBundle)

    /// The "example" asset catalog image resource.
    static let example = DeveloperToolsSupport.ImageResource(name: "example", bundle: resourceBundle)

    /// The "hg1" asset catalog image resource.
    static let hg1 = DeveloperToolsSupport.ImageResource(name: "hg1", bundle: resourceBundle)

    /// The "hg2" asset catalog image resource.
    static let hg2 = DeveloperToolsSupport.ImageResource(name: "hg2", bundle: resourceBundle)

    /// The "hg3" asset catalog image resource.
    static let hg3 = DeveloperToolsSupport.ImageResource(name: "hg3", bundle: resourceBundle)

    /// The "hg4" asset catalog image resource.
    static let hg4 = DeveloperToolsSupport.ImageResource(name: "hg4", bundle: resourceBundle)

    /// The "hg5" asset catalog image resource.
    static let hg5 = DeveloperToolsSupport.ImageResource(name: "hg5", bundle: resourceBundle)

    /// The "hg6" asset catalog image resource.
    static let hg6 = DeveloperToolsSupport.ImageResource(name: "hg6", bundle: resourceBundle)

    /// The "latte" asset catalog image resource.
    static let latte = DeveloperToolsSupport.ImageResource(name: "latte", bundle: resourceBundle)

    /// The "pencil" asset catalog image resource.
    static let pencil = DeveloperToolsSupport.ImageResource(name: "pencil", bundle: resourceBundle)

    /// The "plate" asset catalog image resource.
    static let plate = DeveloperToolsSupport.ImageResource(name: "plate", bundle: resourceBundle)

    /// The "rice1" asset catalog image resource.
    static let rice1 = DeveloperToolsSupport.ImageResource(name: "rice1", bundle: resourceBundle)

    /// The "rice2" asset catalog image resource.
    static let rice2 = DeveloperToolsSupport.ImageResource(name: "rice2", bundle: resourceBundle)

    /// The "rice3" asset catalog image resource.
    static let rice3 = DeveloperToolsSupport.ImageResource(name: "rice3", bundle: resourceBundle)

    /// The "rice4" asset catalog image resource.
    static let rice4 = DeveloperToolsSupport.ImageResource(name: "rice4", bundle: resourceBundle)

    /// The "rice5" asset catalog image resource.
    static let rice5 = DeveloperToolsSupport.ImageResource(name: "rice5", bundle: resourceBundle)

    /// The "rice6" asset catalog image resource.
    static let rice6 = DeveloperToolsSupport.ImageResource(name: "rice6", bundle: resourceBundle)

    /// The "san1" asset catalog image resource.
    static let san1 = DeveloperToolsSupport.ImageResource(name: "san1", bundle: resourceBundle)

    /// The "san2" asset catalog image resource.
    static let san2 = DeveloperToolsSupport.ImageResource(name: "san2", bundle: resourceBundle)

    /// The "san3" asset catalog image resource.
    static let san3 = DeveloperToolsSupport.ImageResource(name: "san3", bundle: resourceBundle)

    /// The "san4" asset catalog image resource.
    static let san4 = DeveloperToolsSupport.ImageResource(name: "san4", bundle: resourceBundle)

    /// The "san5" asset catalog image resource.
    static let san5 = DeveloperToolsSupport.ImageResource(name: "san5", bundle: resourceBundle)

    /// The "san6" asset catalog image resource.
    static let san6 = DeveloperToolsSupport.ImageResource(name: "san6", bundle: resourceBundle)

    /// The "sand1" asset catalog image resource.
    static let sand1 = DeveloperToolsSupport.ImageResource(name: "sand1", bundle: resourceBundle)

    /// The "stamp" asset catalog image resource.
    static let stamp = DeveloperToolsSupport.ImageResource(name: "stamp", bundle: resourceBundle)

    /// The "stamp1" asset catalog image resource.
    static let stamp1 = DeveloperToolsSupport.ImageResource(name: "stamp1", bundle: resourceBundle)

    /// The "star" asset catalog image resource.
    static let star = DeveloperToolsSupport.ImageResource(name: "star", bundle: resourceBundle)

    /// The "word" asset catalog image resource.
    static let word = DeveloperToolsSupport.ImageResource(name: "word", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Group28" asset catalog image.
    static var group28: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .group28)
#else
        .init()
#endif
    }

    /// The "Rectangle" asset catalog image.
    static var rectangle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rectangle)
#else
        .init()
#endif
    }

    /// The "bg-guang" asset catalog image.
    static var bgGuang: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bgGuang)
#else
        .init()
#endif
    }

    /// The "board" asset catalog image.
    static var board: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .board)
#else
        .init()
#endif
    }

    /// The "cake1" asset catalog image.
    static var cake1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cake1)
#else
        .init()
#endif
    }

    /// The "cake2" asset catalog image.
    static var cake2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cake2)
#else
        .init()
#endif
    }

    /// The "cake3" asset catalog image.
    static var cake3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cake3)
#else
        .init()
#endif
    }

    /// The "cake4" asset catalog image.
    static var cake4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cake4)
#else
        .init()
#endif
    }

    /// The "cake5" asset catalog image.
    static var cake5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cake5)
#else
        .init()
#endif
    }

    /// The "cake6" asset catalog image.
    static var cake6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cake6)
#else
        .init()
#endif
    }

    /// The "ch1" asset catalog image.
    static var ch1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ch1)
#else
        .init()
#endif
    }

    /// The "ch2" asset catalog image.
    static var ch2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ch2)
#else
        .init()
#endif
    }

    /// The "ch3" asset catalog image.
    static var ch3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ch3)
#else
        .init()
#endif
    }

    /// The "ch4" asset catalog image.
    static var ch4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ch4)
#else
        .init()
#endif
    }

    /// The "ch5" asset catalog image.
    static var ch5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ch5)
#else
        .init()
#endif
    }

    /// The "example" asset catalog image.
    static var example: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .example)
#else
        .init()
#endif
    }

    /// The "hg1" asset catalog image.
    static var hg1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hg1)
#else
        .init()
#endif
    }

    /// The "hg2" asset catalog image.
    static var hg2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hg2)
#else
        .init()
#endif
    }

    /// The "hg3" asset catalog image.
    static var hg3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hg3)
#else
        .init()
#endif
    }

    /// The "hg4" asset catalog image.
    static var hg4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hg4)
#else
        .init()
#endif
    }

    /// The "hg5" asset catalog image.
    static var hg5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hg5)
#else
        .init()
#endif
    }

    /// The "hg6" asset catalog image.
    static var hg6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hg6)
#else
        .init()
#endif
    }

    /// The "latte" asset catalog image.
    static var latte: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .latte)
#else
        .init()
#endif
    }

    /// The "pencil" asset catalog image.
    static var pencil: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .pencil)
#else
        .init()
#endif
    }

    /// The "plate" asset catalog image.
    static var plate: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .plate)
#else
        .init()
#endif
    }

    /// The "rice1" asset catalog image.
    static var rice1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rice1)
#else
        .init()
#endif
    }

    /// The "rice2" asset catalog image.
    static var rice2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rice2)
#else
        .init()
#endif
    }

    /// The "rice3" asset catalog image.
    static var rice3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rice3)
#else
        .init()
#endif
    }

    /// The "rice4" asset catalog image.
    static var rice4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rice4)
#else
        .init()
#endif
    }

    /// The "rice5" asset catalog image.
    static var rice5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rice5)
#else
        .init()
#endif
    }

    /// The "rice6" asset catalog image.
    static var rice6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .rice6)
#else
        .init()
#endif
    }

    /// The "san1" asset catalog image.
    static var san1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .san1)
#else
        .init()
#endif
    }

    /// The "san2" asset catalog image.
    static var san2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .san2)
#else
        .init()
#endif
    }

    /// The "san3" asset catalog image.
    static var san3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .san3)
#else
        .init()
#endif
    }

    /// The "san4" asset catalog image.
    static var san4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .san4)
#else
        .init()
#endif
    }

    /// The "san5" asset catalog image.
    static var san5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .san5)
#else
        .init()
#endif
    }

    /// The "san6" asset catalog image.
    static var san6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .san6)
#else
        .init()
#endif
    }

    /// The "sand1" asset catalog image.
    static var sand1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .sand1)
#else
        .init()
#endif
    }

    /// The "stamp" asset catalog image.
    static var stamp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stamp)
#else
        .init()
#endif
    }

    /// The "stamp1" asset catalog image.
    static var stamp1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .stamp1)
#else
        .init()
#endif
    }

    /// The "star" asset catalog image.
    static var star: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .star)
#else
        .init()
#endif
    }

    /// The "word" asset catalog image.
    static var word: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .word)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Group28" asset catalog image.
    static var group28: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .group28)
#else
        .init()
#endif
    }

    /// The "Rectangle" asset catalog image.
    static var rectangle: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rectangle)
#else
        .init()
#endif
    }

    /// The "bg-guang" asset catalog image.
    static var bgGuang: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bgGuang)
#else
        .init()
#endif
    }

    /// The "board" asset catalog image.
    static var board: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .board)
#else
        .init()
#endif
    }

    /// The "cake1" asset catalog image.
    static var cake1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cake1)
#else
        .init()
#endif
    }

    /// The "cake2" asset catalog image.
    static var cake2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cake2)
#else
        .init()
#endif
    }

    /// The "cake3" asset catalog image.
    static var cake3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cake3)
#else
        .init()
#endif
    }

    /// The "cake4" asset catalog image.
    static var cake4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cake4)
#else
        .init()
#endif
    }

    /// The "cake5" asset catalog image.
    static var cake5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cake5)
#else
        .init()
#endif
    }

    /// The "cake6" asset catalog image.
    static var cake6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cake6)
#else
        .init()
#endif
    }

    /// The "ch1" asset catalog image.
    static var ch1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ch1)
#else
        .init()
#endif
    }

    /// The "ch2" asset catalog image.
    static var ch2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ch2)
#else
        .init()
#endif
    }

    /// The "ch3" asset catalog image.
    static var ch3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ch3)
#else
        .init()
#endif
    }

    /// The "ch4" asset catalog image.
    static var ch4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ch4)
#else
        .init()
#endif
    }

    /// The "ch5" asset catalog image.
    static var ch5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .ch5)
#else
        .init()
#endif
    }

    /// The "example" asset catalog image.
    static var example: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .example)
#else
        .init()
#endif
    }

    /// The "hg1" asset catalog image.
    static var hg1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hg1)
#else
        .init()
#endif
    }

    /// The "hg2" asset catalog image.
    static var hg2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hg2)
#else
        .init()
#endif
    }

    /// The "hg3" asset catalog image.
    static var hg3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hg3)
#else
        .init()
#endif
    }

    /// The "hg4" asset catalog image.
    static var hg4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hg4)
#else
        .init()
#endif
    }

    /// The "hg5" asset catalog image.
    static var hg5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hg5)
#else
        .init()
#endif
    }

    /// The "hg6" asset catalog image.
    static var hg6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hg6)
#else
        .init()
#endif
    }

    /// The "latte" asset catalog image.
    static var latte: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .latte)
#else
        .init()
#endif
    }

    /// The "pencil" asset catalog image.
    static var pencil: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .pencil)
#else
        .init()
#endif
    }

    /// The "plate" asset catalog image.
    static var plate: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .plate)
#else
        .init()
#endif
    }

    /// The "rice1" asset catalog image.
    static var rice1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rice1)
#else
        .init()
#endif
    }

    /// The "rice2" asset catalog image.
    static var rice2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rice2)
#else
        .init()
#endif
    }

    /// The "rice3" asset catalog image.
    static var rice3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rice3)
#else
        .init()
#endif
    }

    /// The "rice4" asset catalog image.
    static var rice4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rice4)
#else
        .init()
#endif
    }

    /// The "rice5" asset catalog image.
    static var rice5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rice5)
#else
        .init()
#endif
    }

    /// The "rice6" asset catalog image.
    static var rice6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .rice6)
#else
        .init()
#endif
    }

    /// The "san1" asset catalog image.
    static var san1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .san1)
#else
        .init()
#endif
    }

    /// The "san2" asset catalog image.
    static var san2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .san2)
#else
        .init()
#endif
    }

    /// The "san3" asset catalog image.
    static var san3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .san3)
#else
        .init()
#endif
    }

    /// The "san4" asset catalog image.
    static var san4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .san4)
#else
        .init()
#endif
    }

    /// The "san5" asset catalog image.
    static var san5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .san5)
#else
        .init()
#endif
    }

    /// The "san6" asset catalog image.
    static var san6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .san6)
#else
        .init()
#endif
    }

    /// The "sand1" asset catalog image.
    static var sand1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .sand1)
#else
        .init()
#endif
    }

    /// The "stamp" asset catalog image.
    static var stamp: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stamp)
#else
        .init()
#endif
    }

    /// The "stamp1" asset catalog image.
    static var stamp1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .stamp1)
#else
        .init()
#endif
    }

    /// The "star" asset catalog image.
    static var star: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .star)
#else
        .init()
#endif
    }

    /// The "word" asset catalog image.
    static var word: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .word)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

