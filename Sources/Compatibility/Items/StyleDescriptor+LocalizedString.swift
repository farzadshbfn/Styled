//
//  StyleDescriptor+LocalizedString.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/5/19.
//

import Foundation

/// Used as reference for object poisoning
private var associatedConfig: Int8 = 0

extension StyleDescriptor {

	/// Custom `LocalizedString` used for current Object.
	///
	/// - Note: Setting `nil` will make `Styled` listen to `Config.localizedStringSchemeNeedsUpdate`
	/// - Note: Setting custom `LocalizedStringScheme` will stop listening to `Config.localizedStringSchemeNeedsUpdate` and
	/// updates colors with given `LocalizedStringScheme`
	public var customLocalizedStringScheme: LocalizedStringScheme? {
		get { config.customScheme }
		set { config.customScheme = newValue }
	}

	/// Calling this method, will update all localizedStrings associated with `styled`
	public func synchronizeLocalizedStrings() { config.synchronize() }

	/// Will get called when  `Config.localizedStringSchemeNeedsUpdate` is raised or `synchronizeLocalizedString()` is called
	/// or `customLocalizedStringScheme` is set
	///
	/// - Note: Use this method in cases that a specific variable can not be set with `LocalizedStringKey` but you need to be aware about it's changes. **Object** will
	/// be provided in `update` closure to omit retain-cycles
	///
	/// - Parameter id: A unique Identifier to gain controler over closure
	/// - Parameter shouldSet: `false` means `update` will not get called when the method gets called and only triggers when `styled` decides to.
	/// - Parameter update: Setting `nil` will stop updating for given `id`
	public func onLocalizedStringSchemeUpdate(withId id: String = UUID().uuidString, shouldSet: Bool = true, do update: ((Base) -> Void)?) {
		guard let update = update else { return config.updates[id] = nil }
		config.updates[id] = { [weak base] in
			guard let base = base else { return }
			update(base)
		}
		if shouldSet { update(base) }
	}

	/// Using this method, given `KeyPath` will keep in sync with localizedString defined in `localizedStringScheme` for given `LocalizedString`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `localizedStringScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, String>) -> LocalizedString? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $1.write(to: keyPath, on: $0) } }
	}

	/// Using this method, given `KeyPath` will keep in sync with localizedString defined in `localizedStringScheme` for given `LocalizedString`.
	///
	/// - Note: Setting `nil` will stop syncing `KeyPath` with `localizedStringScheme`
	///
	public subscript(dynamicMember keyPath: ReferenceWritableKeyPath<Base, String?>) -> LocalizedString? {
		get { config.updates[keyPath]?.item }
		set { config.updates[keyPath] = update(newValue) { $0[keyPath: keyPath] = $1 } }
	}

	private typealias LocalizedStringConfig = Config.Item<LocalizedString>

	/// Holds Configurations done to LocalizedString instances inside `base`
	private var config: LocalizedStringConfig {
		objc_sync_enter(base); defer { objc_sync_exit(base) }

		guard let obj = objc_getAssociatedObject(base, &associatedConfig) as? LocalizedStringConfig else {
			let obj = LocalizedStringConfig(notifName: Config.localizedStringSchemeNeedsUpdate, defaultScheme: Config.localizedStringScheme)
			objc_setAssociatedObject(base, &associatedConfig, obj, .OBJC_ASSOCIATION_RETAIN)
			return obj
		}
		return obj
	}

	/// Internal `update` method which generates `Styled.Update` and applies the update once.
	private func update(_ localizedString: LocalizedString?, _ apply: @escaping (Base, String?) -> Void) -> LocalizedStringConfig.Update? {
		guard let localizedString = localizedString else { return nil }
		let styledUpdate = LocalizedStringConfig.Update(localizedString) { [weak base] scheme in
			guard let base = base else { return () }
			return apply(base, localizedString.resolve(from: scheme))
		}
		styledUpdate.synchronize(withScheme: self.config.scheme)
		return styledUpdate
	}
}
