//
//  StyleDescriptor+Font.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

/// Used as reference for object poisoning
private var associatedFontConfig: Int8 = 0

extension StyleDescriptor {

	/// Cusotm `FontScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.fontSchemeNeedsUpdate`
	/// - Note: Setting custom `FontScheme` will stop listening to `Config.fontSchemeNeedsUpdate` and
	/// updates fonts with given `FontScheme`
	public var customFontScheme: FontScheme? {
		get { config.customScheme }
		set { config.customScheme = newValue }
	}

	/// Calling this method, will update all fonts associated with `styled`
	public func synchronizeFonts() { config.synchronize() }

	/// Will get called when  `Config.fontSchemeNeedsUpdate` is raised or `synchronizeFonts()` is called or `customFontScheme` is set
	///
	/// - Note: Use this method in cases that a specific variable can not be set with `Font` but you need to be aware about it's changes. **Object** will
	/// be provided in `update` closure to omit retain-cycles
	///
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onFontSchemeUpdate(withId id: String = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return config.updates[id] = nil }
		config.updates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}

	/// Using this method, given `KeyPath` will keep in sync with font defined in `fontScheme` for given `Font`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `fontScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIFont>) -> Font? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $1 != nil ? $0[keyPath: keyPath] = $1! : () } }
	}

	/// Using this method, given `KeyPath` will keep in sync with font defined in `fontScheme` for given `Font`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `fontScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIFont?>) -> Font? {
		get { config.updates[keyPath]?.item }
		set { config.updates.keyPaths[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}

	private typealias FontConfig = Config.Item<Font>

	/// Holds Configurations done to Font instances inside `base`
	private var config: FontConfig {
		objc_sync_enter(base); defer { objc_sync_exit(base) }

		guard let obj = objc_getAssociatedObject(base, &associatedFontConfig) as? FontConfig else {
			let obj = FontConfig(notifName: Config.fontSchemeNeedsUpdate, defaultScheme: Config.fontScheme)
			objc_setAssociatedObject(base, &associatedFontConfig, obj, .OBJC_ASSOCIATION_RETAIN)
			return obj
		}
		return obj
	}

	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ font: Font?, _ apply: @escaping (Base, UIFont?) -> Void) -> FontConfig.Update? {
		guard let font = font else { return nil }
		let styledUpdate = FontConfig.Update(font) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, font.resolve(from: scheme))
		}
		styledUpdate.synchronize(withScheme: self.config.scheme)
		return styledUpdate
	}
}
