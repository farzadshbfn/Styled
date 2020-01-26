//
//  StyleDescriptor+Color.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/2/19.
//

import Foundation

/// Used as reference for object poisoning
private var associatedConfig: Int8 = 0

extension StyleDescriptor {

	/// Custom `ColorScheme` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.colorSchemeNeedsUpdate`
	/// - Note: Setting custom `ColorScheme` will stop listening to `Config.colorSchemeNeedsUpdate` and
	/// updates colors with given `ColorScheme`
	public var customColorScheme: ColorScheme? {
		get { color.customScheme }
		set { color.customScheme = newValue }
	}

	/// Calling this method, will update all colors associated with `styled`
	public func synchronizeColors() { color.synchronize() }

	/// Will get called when  `Config.colorSchemeNeedsUpdate` is raised or `synchronizeColors()` is called or `customColorScheme` is set
	///
	/// - Note: Use this method in cases that a specific variable can not be set with `Color` but you need to be aware about it's changes. **Object** will
	/// be provided in `update` closure to omit retain-cycles
	///
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onColorSchemeUpdate(withId id: String = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return color.updates[id] = nil }
		color.updates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}

	/// Using this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIColor>) -> Color? {
		get { color.updates[keyPath]?.item }
		set { color.updates[keyPath] = update(newValue) { $1.write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, UIColor?>) -> Color? {
		get { color.updates[keyPath]?.item }
		set { color.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}

	/// Using this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGColor>) -> Color? {
		get { color.updates[keyPath]?.item }
		set { color.updates[keyPath] = update(newValue) { ($1?.cgColor).write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CGColor?>) -> Color? {
		get { color.updates[keyPath]?.item }
		set { color.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.cgColor } }
	}

	/// Using this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIColor>) -> Color? {
		get { color.updates[keyPath]?.item }
		set { color.updates[keyPath] = update(newValue) { ($1?.ciColor).write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with color defined in `colorScheme` for given `Color`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `colorScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, CIColor?>) -> Color? {
		get { color.updates[keyPath]?.item }
		set { color.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1?.ciColor } }
	}

	private typealias ColorConfig = Config.Item<Color>

	/// Holds Configurations done to Color instances inside `base`
	private var color: ColorConfig {
		objc_sync_enter(base); defer { objc_sync_exit(base) }

		guard let obj = objc_getAssociatedObject(base, &associatedConfig) as? ColorConfig else {
			let obj = ColorConfig(notifName: Config.colorSchemeNeedsUpdate, defaultScheme: Config.colorScheme)
			objc_setAssociatedObject(base, &associatedConfig, obj, .OBJC_ASSOCIATION_RETAIN)
			return obj
		}
		return obj
	}

	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ color: Color?, _ apply: @escaping (Base, UIColor?) -> Void) -> ColorConfig.Update? {
		guard let color = color else { return nil }
		let styledUpdate = ColorConfig.Update(color) { [weak base] scheme in
			guard let base = base else { return () }
			apply(base, color.resolve(from: scheme))
		}
		styledUpdate.synchronize(withScheme: self.color.scheme)
		return styledUpdate
	}
}
