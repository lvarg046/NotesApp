//
//  AuthenticationService.swift
//  NotesApp
//
//  Created by Luis Vargas on 11/25/20.
//

import Foundation
import Firebase

class AuthenticationService: ObservableObject {
    @Published var user: User?
    var cancellable: AuthStateDidChangeListenerHandle?
    
    init() {
        cancellable = Auth.auth().addStateDidChangeListener {(_, user) in
            if let user = user {
                self.user = user
            } else {
                self.user = nil
            }
        }
    }
    
    func signUp(
        email: String,
        password: String,
        handler: @escaping AuthDataResultCallback
    ){
        Auth.auth().createUser(withEmail: email, password: password, completion: handler)
    }
    
    func signIn(
        email: String,
        password: String,
        handler: @escaping AuthDataResultCallback
    ){
        Auth.auth().signIn(withEmail: email, password: password, completion: handler)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
    }
}
