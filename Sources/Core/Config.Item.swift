//
//  Config.Item.swift
//  Styled
//
//  Created by Farzad Sharbafian on 11/1/19.
//

import Foundation

extension Config {
	/// Holds configuration for each of `StyledItem`s stored in `Styled` instance of each `StyledCompatible` object
	final class Item<Item: Styled.Item> {
		
		typealias Scheme = Item.Scheme
		
		/// `Notification.Name` that this `ItemConfig` is sensitive to.
		let notifName: Notification.Name
		
		/// A Closure to provide `defaultScheme` for given `Scheme`
		private let defaultScheme: () -> Scheme
		
		/// The `Scheme` that this instance will use
		var scheme: Scheme { customScheme ?? defaultScheme() }
		
		/// Determines if current `ItemConfig` should use a scheme other than `defaultScheme`
		///
		/// - Note: Setting this variable will stop listening to `notifName` Notification and update associated object
		/// - Note: Setting `nil` will check if `ItemConfig` needs to listen to `notifName` or not
		var customScheme: Scheme? = nil {
			didSet {
				synchronize()
				updateNotifObserver()
			}
		}
		
		/// This variable provides control over NotificationListener over `notifName`
		private(set) var notifObserver: NSObjectProtocol? = nil
		
		/// Holds a reference to all `KeyPath` and `ClosureIdentifier` updates
		///
		/// - Note: When there are no `Updates` registered, `ItemConfig` will not listen to `notifName` anymore.
		var updates = Updates() {
			didSet { updateNotifObserver() }
		}
		
		/// - Parameter notifName: `Notification.Name` that this `ItemConfig` is sensitive to.
		/// - Parameter defaultScheme: Default `Scheme` to back ItemConfig when no `customScheme` is defined
		init(notifName: Notification.Name, defaultScheme: @escaping @autoclosure () -> Scheme) {
			self.notifName = notifName
			self.defaultScheme = defaultScheme
		}
		
		deinit {
			guard let notifObserver = self.notifObserver else { return }
			
			NotificationCenter.default.removeObserver(notifObserver)
		}
		
		/// Will update all associated updates
		func synchronize() { updates.synchronize(withScheme: scheme) }
		
		/// Will listen to `notifName` notification, when needed
		private func updateNotifObserver() {
			if customScheme == nil && !updates.isEmpty {
				guard notifObserver == nil else { return }
				
				notifObserver = NotificationCenter.default.addObserver(
					forName: notifName,
					object: nil,
					queue: .main,
					using: { _ in self.synchronize() }
				)
			} else {
				guard let notifObserver = self.notifObserver else { return }
				
				NotificationCenter.default.removeObserver(notifObserver)
			}
		}
	}
}

// MARK:- Updates
extension Config.Item {
	
	/// Contains list of `Item`s (i.e `Color`, `Font`, `Image`, ...) and a `closures` to act upon `Scheme` change
	struct Updates {
		
		/// Holds `KeyPath` based variables and their `Update`
		var keyPaths: [AnyKeyPath: Update] = [:]
		
		/// Holds `Id` of closures passed to `Styled` to get called when `Scheme` changes
		var closures: [String: () -> ()] = [:]
		
		/// Will return `true` if there are no `Update`s registered and `false` otherwise.
		var isEmpty: Bool { keyPaths.isEmpty && closures.isEmpty }
		
		/// Will call all `Update`.`update`s and Closures
		/// - Parameter scheme: Suitable `Scheme`
		func synchronize(withScheme scheme: Scheme) {
			DispatchQueue.main.async {
				self.keyPaths.values.forEach { $0.synchronize(withScheme: scheme) }
				self.closures.values.forEach { $0() }
			}
		}
		
		/// Will query through `keyPaths`
		subscript(_ keyPath: AnyKeyPath) -> Update? {
			get { keyPaths[keyPath] }
			set { keyPaths[keyPath] = newValue }
		}
		
		/// Will query through `closures`
		subscript(_ id: String) -> (() -> Void)? {
			get { closures[id] }
			set { closures[id] = newValue }
		}
	}
	
	/// Contains an `Item` (i.e `Color`, `Font`, `Image`, ...) and a closure to Update the `KeyPath` with given `Item`
	struct Update {
		/// Holding original `Item` for returning and comparing purposes of the user
		let item: Item
		
		/// Combines `Styled` to Object
		private let synchronizer: (Scheme) -> Void
		
		/// Will run inner closure to update object with `Item` and `Scheme`
		/// - Parameter scheme: `Scheme` to update object with
		func synchronize(withScheme scheme: Scheme) { synchronizer(scheme) }
		
		init(_ item: Item, _ synchronizer: @escaping (Scheme) -> Void) {
			self.item = item
			self.synchronizer = synchronizer
		}
	}
}
