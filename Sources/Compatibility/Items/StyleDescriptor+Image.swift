//
//  StyleDescriptor+Image.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

/// Used as reference for object poisoning
private var associatedConfig: Int8 = 0

extension StyleDescriptor {

	/// Custom `ImageScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.imageSchemeNeedsUpdate`
	/// - Note: Setting custom `ImageScheme` will stop listening to `Config.imageSchemeNeedsUpdate` and
	/// updates images with given `ImageScheme`
	public var customImageScheme: ImageScheme? {
		get { config.customScheme }
		set { config.customScheme = newValue }
	}

	/// Calling this method, will update all images associated with `styled`
	public func synchronizeImages() { config.synchronize() }

	/// Will get called when  `Config.imageSchemeNeedsUpdate` is raised or `synchronizeImages()` is called or `customImageScheme` is set
	///
	/// - Note: Use this method in cases that a specific variable can not be set with `Image` but you need to be aware about it's changes. **Object** will
	/// be provided in `update` closure to omit retain-cycles
	///
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onImageSchemeUpdate(withId id: String = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return config.updates[id] = nil }
		config.updates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}

	/// Using this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIImage>) -> Image? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $1.write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIImage?>) -> Image? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}

	/// Using this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGImage>) -> Image? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { ($1?.cgImage).write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGImage?>) -> Image? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.cgImage } }
	}

	/// Using this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIImage>) -> Image? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { ($1?.ciImage).write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with image defined in `imageScheme` for given `Image`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `imageScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIImage?>) -> Image? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.ciImage } }
	}

	private typealias ImageConfig = Config.Item<Image>

	/// Holds Configurations done to Image instances inside `base`
	private var config: ImageConfig {
		objc_sync_enter(base); defer { objc_sync_exit(base) }

		guard let obj = objc_getAssociatedObject(base, &associatedConfig) as? ImageConfig else {
			let obj = ImageConfig(notifName: Config.imageSchemeNeedsUpdate, defaultScheme: Config.imageScheme)
			objc_setAssociatedObject(base, &associatedConfig, obj, .OBJC_ASSOCIATION_RETAIN)
			return obj
		}
		return obj
	}

	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ image: Image?, _ apply: @escaping (Base, UIImage?) -> Void) -> ImageConfig.Update? {
		guard let image = image else { return nil }
		let styledUpdate = ImageConfig.Update(image) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, image.resolve(from: scheme))
		}
		styledUpdate.synchronize(withScheme: self.config.scheme)
		return styledUpdate
	}
}
