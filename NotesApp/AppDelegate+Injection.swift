//
//  AppDelegate+Injection.swift
//  NotesApp
//
//  Created by Luis Vargas on 11/25/20.
//

import Foundation
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register{ AuthenticationService() }.scope(application)
    }
}
