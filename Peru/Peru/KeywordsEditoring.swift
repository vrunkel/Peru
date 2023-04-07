//
//  AuthorsEditoring.swift
//  Peru
//
//  Created by Volker Runkel on 01.04.23.
//

import SwiftUI
import CoreData
import AQUI
import WrappingHStack
import UniformTypeIdentifiers

struct KeywordsPopoverContent: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Keywords.keyword, ascending: true)], animation: .default)
    private var keywordItems: FetchedResults<Keywords>
    
    @Binding var keywordsSet: NSSet
    
    init(_ keywordsSet: Binding<NSSet>) {
        self._keywordsSet = keywordsSet
    }
    
    @State private var selectedKeyword: Keywords?
    
    @State var keyword: String = ""
    
    @State private var isOn = false
    
    var anyOfMultiple: [String] {[
        keyword
    ]}
    
    func getToggleState(keyword: Keywords) -> Binding<Bool> {
        return Binding(get: {self.keywordsSet.contains(keyword)}, set: {
            if $0 {
                let newSet = NSMutableSet(set: self.keywordsSet)
                newSet.add(keyword)
                self.keywordsSet = NSSet(set: newSet)
            } else {
                let newSet = NSMutableSet(set: self.keywordsSet)
                newSet.remove(keyword)
                self.keywordsSet = NSSet(set: newSet)
            }
        })
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Edit keywords")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            HStack(alignment: .bottom) {
                VStack {
                    TextField("Keyword", text: $keyword)
                }.frame(width: 200)
                    .disabled(self.selectedKeyword == nil)
                Spacer()
                VStack(alignment: .trailing) {
                    Button {
                        let keyword = Keywords(context: viewContext)
                        keyword.keyword = "Keyword"
                        self.selectedKeyword = keyword
                    } label: {
                        Image(systemName: "plus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                    Button {
                        viewContext.delete(self.selectedKeyword!)
                        self.selectedKeyword = nil
                    } label: {
                        Image(systemName: "minus.square")
                    }.buttonStyle(BorderlessButtonStyle())
                        .disabled(self.selectedKeyword == nil)
                }
            }
            
            WrappingHStack(keywordsSet.allObjects as! [Keywords],id: \.self,  alignment: .leading, spacing: .constant(0)) {
                let keyword = $0
                Text($0.keyword ?? "---")
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.gray, lineWidth: 3)
                    )
                    .onTapGesture {
                        self.selectedKeyword = keyword
                    }
            }
            
            ScrollViewReader { proxy in
                List(selection: $selectedKeyword) {
                    ForEach(keywordItems, id: \.self) { keyword in
                        HStack {
                            Text(keyword.keyword ?? "---")
                            Spacer()
                            Toggle(isOn: getToggleState(keyword: keyword)) {
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                }.onChange(of: selectedKeyword) { newValue in
                    if self.selectedKeyword != nil {
                        self.keyword = self.selectedKeyword?.keyword ?? ""
                        proxy.scrollTo(self.selectedKeyword!, anchor: .center)
                    }
                    else {
                        self.keyword = ""
                    }
                }
            }
        }
        .onChange(of: anyOfMultiple, perform: { newValue in
            if self.selectedKeyword != nil {
                self.selectedKeyword!.keyword = self.keyword
            }
        })
        .frame(minWidth: 250, idealWidth: 250, maxWidth: 300, minHeight: 250, idealHeight: 350, maxHeight: 500, alignment: .leading)
        .padding()
    }
}
