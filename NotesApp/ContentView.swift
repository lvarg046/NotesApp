//
//  ContentView.swift
//  NotesApp
//  Created by Luis Vargas on 11/14/20.
//

import SwiftUI
import Firebase
import Resolver

struct ContentView: View {
    @ObservedObject var authenticationService: AuthenticationService = Resolver.resolve()
    
    var body: some View {
        Group {
            if (authenticationService.user == nil){
                LoginView()
            } else{
                Text("Private Notes")
                    .foregroundColor(.black)
                Home()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct Home: View {
    @ObservedObject var Notes = getNotes()
    @State var show = false
    @State var txt = ""
    @State var docID = ""
    @State var remove = false
    @Injected var authenticationService: AuthenticationService

    var body: some View {
        ZStack( alignment: .bottomTrailing ){
            VStack( spacing: 0 ) {
                HStack {
                    Text("Notes List").font(.title).foregroundColor(.black)
                    Spacer()
                    
                    Button(
                        action:{
                            self.remove.toggle()
                        }
                    ) {
                        Image(systemName: self.remove ? "xmark.circle": "trash").resizable().frame(width:23, height: 23).foregroundColor(.black)
                    }
                }.padding()
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                .background(Color.yellow)
                if self.Notes.data.isEmpty {
                    if self.Notes.noData {
                        Spacer()
                        Text("There are no notes to show.").foregroundColor(Color.black).background(Color.yellow)
                        Spacer()
                    } else {
                        Spacer()
                        Indicator()
                            .background(Color.black)
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false ) {
                        VStack {
                            ForEach( self.Notes.data ){ i in
                                HStack( spacing: 15 ) {
                                    Button(
                                        action: {
                                            self.docID = i.id
                                            self.txt = i.note
                                            self.show.toggle()
                                        }) {
                                        VStack( alignment: .leading, spacing:12 ) {
                                            Text(i.date)
                                            Text(i.note).lineLimit(1)
                                            Divider()
                                        }.padding()
                                        .foregroundColor(.black)
                                    }
                                    if self.remove{
                                        Button(
                                            action: {
                                                let db = Firestore.firestore()
                                                db.collection("notes").document(i.id).delete()
                                            })
                                        {
                                            Image(systemName: "minus.circle.fill")
                                                .resizable()
                                                .frame(width:20, height: 20)
                                                .foregroundColor(.yellow)
                                        } // Putting this comment here as a method of version control, 11/25/2020 2:10AM
                                    }
                                }.padding(.horizontal)
                            }
                        }
                            
                    }
                }
                
                
                
                
            }.edgesIgnoringSafeArea(.top)
            
            Button(
                action: {
                    self.txt = ""
                    self.docID = ""
                    self.show.toggle()
                }) {
                Image( systemName: "plus").resizable().frame(width:18, height: 18).foregroundColor(.black)
            }.padding()
            .background(Color.yellow)
            .clipShape(Circle() )
            .padding(.bottom, 55)
            
            Button(
                action: {
                    do{
                        try authenticationService.signOut()
                    } catch let signOutError as NSError {
                        print("Error signing out: %@", signOutError)
                    }
                }) {
                Image( systemName: "iphone.slash").resizable().frame(width: 18, height: 18).foregroundColor(.black)
    
            }.padding()
            .background(Color.yellow)
            .clipShape( Circle() )
            .padding(.leading)

        
        }
        .sheet(isPresented: self.$show ){
            EditView( txt: self.$txt, docID: self.$docID, show: self.$show)
        }
        .animation(.default)
    }
}

class Host : UIHostingController<ContentView> {
     var preferredStatusBarSyle: UIStatusBarStyle{
        return .darkContent
    }
}

class getNotes : ObservableObject {
    @Published var data = [Note]()
    @Published var noData = false
    
    init() {
        let db = Firestore.firestore()
        
        db.collection("notes").order(by: "date", descending: true).addSnapshotListener { (snap, err) in
            
            if err != nil {
                print((err?.localizedDescription)! )
                self.noData = true
                return
            }
            
            if (snap?.documentChanges.isEmpty)!{
                self.noData = true
                return
            }
            
            for i in snap!.documentChanges {
                if i.type == .added {
                    let id = i.document.documentID
                    let notes = i.document.get("notes") as! String
                    let date = i.document.get("date") as! Timestamp
                    let format = DateFormatter()
                    format.dateFormat = "MM-dd-YYYY hh:mm a"
                    let dateString = format.string(from:date.dateValue())
                    self.data.append(Note(id: id, note: notes, date: dateString))
                }
                
                if i.type == .modified {
                    let id = i.document.documentID
                    let notes = i.document.get("notes") as! String
                    for i in 0..<self.data.count {
                        if self.data[i].id == id {
                            self.data[i].note = notes
                        }
                    }
                }
                
                if i.type == .removed {
                    let id = i.document.documentID
                    for i in 0..<self.data.count{
                        if self.data[i].id == id {
                            self.data.remove(at: i)
                            if self.data.isEmpty {
                                self.noData = true
                            }
                            return
                        }
                    }
                }
            }
        }
    }
}


struct Note : Identifiable {
    var id : String
    var note : String
    var date : String
}

struct Indicator : UIViewRepresentable {
    
    func makeUIView( context: UIViewRepresentableContext<Indicator>) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .medium)
        view.startAnimating()
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Indicator>) {
        
    }
}

struct EditView : View {
    @Binding var txt : String
    @Binding var docID : String
    @Binding var show : Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing ){
            MultiLineTF( txt: self.$txt )
                .padding()
                .background(Color.black.opacity(0.66))
            Button( action:{
                self.show.toggle()
                self.SaveData()
            }) {
                Text("Save").padding(.vertical).padding(.horizontal, 25).foregroundColor(.black)
            }
            .background(Color.yellow)
            .clipShape(Circle())
            .padding()
        }.edgesIgnoringSafeArea(.bottom)
        }
    
    func SaveData() {
        let db = Firestore.firestore()
        if self.docID != ""{
            db.collection("notes").document(self.docID).updateData(["notes":self.txt]) { (err) in
                if err != nil {
                    print((err?.localizedDescription)!)
                    return
                }
            }
        } else {
            db.collection("notes").document().setData(["notes":self.txt, "date":Date()]) { (err) in
                if err != nil{
                    print((err?.localizedDescription)!)
                    return
                }
            }
        }
    }
} // End EditView

struct MultiLineTF : UIViewRepresentable {
    
    func makeCoordinator() -> MultiLineTF.Coordinator {
        return MultiLineTF.Coordinator(parent1: self)
    }
    
    @Binding var txt : String
    
    func makeUIView(context: UIViewRepresentableContext<MultiLineTF>) -> UITextView {
        let view = UITextView()
        
        if self.txt != "" {
            view.text = self.txt
            view.textColor = .white
        } else {
            view.text = "Type something"
            view.textColor = .white
        }
        
        view.font = .systemFont(ofSize: 18)
        view.isEditable = true
        view.backgroundColor = .darkGray
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<MultiLineTF>) {
        
    }
    
    class Coordinator : NSObject,UITextViewDelegate {
        var parent : MultiLineTF
        
        init( parent1 : MultiLineTF){
            parent = parent1
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if self.parent.txt == "" {
                textView.text = ""
                textView.textColor = .white
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.txt = textView.text
        }
    }
    
} // End MultiLineTF
