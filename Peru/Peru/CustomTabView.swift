//
//  CustomTabView.swift
//  Peru
//
//  Created by Volker Runkel on 22.03.23.
//

import SwiftUI

public extension Color {

    #if os(macOS)
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
    static let secondaryBackgroundColor = Color(NSColor.controlBackgroundColor)
    #else
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)
    #endif
}

/*
 https://stackoverflow.com/questions/60674035/swiftui-custom-tab-view-for-macos-ios
 */
 public struct CustomTabView: View {
    
    public enum TabBarPosition { // Where the tab bar will be located within the view
        case top
        case bottom
    }
    
    private let tabBarPosition: TabBarPosition
    private let tabText: [String]
    private let tabIconNames: [String]
    private let tabViews: [AnyView]
    
    @State private var selection = 0
    
    public init(tabBarPosition: TabBarPosition, content: [(tabText: String, tabIconName: String, view: AnyView)]) {
        self.tabBarPosition = tabBarPosition
        self.tabText = content.map{ $0.tabText }
        self.tabIconNames = content.map{ $0.tabIconName }
        self.tabViews = content.map{ $0.view }
    }
    
    public var tabBar: some View {
        
        HStack {
            Spacer()
            ForEach(0..<tabText.count, id: \.self) { index in
                HStack {
                    Image(systemName: self.tabIconNames[index])
                    Text(self.tabText[index])
                }
                .padding()
                .foregroundColor(self.selection == index ? Color.accentColor : Color.primary)
                .background(Color.secondaryBackgroundColor)
                .onTapGesture {
                    self.selection = index
                }
            }
            Spacer()
        }
        .padding(0)
        .background(Color.secondaryBackgroundColor) // Extra background layer to reset the shadow and stop it applying to every sub-view
        .shadow(color: Color.clear, radius: 0, x: 0, y: 0)
        .background(Color.secondaryBackgroundColor)
        .shadow(
            color: Color.black.opacity(0.25),
            radius: 3,
            x: 0,
            y: tabBarPosition == .top ? 1 : -1
        )
        .zIndex(99) // Raised so that shadow is visible above view backgrounds
    }
    public var body: some View {
        
        VStack(spacing: 0) {
            
            if (self.tabBarPosition == .top) {
                tabBar
            }
            
            tabViews[selection]
                .padding(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if (self.tabBarPosition == .bottom) {
                tabBar
            }
        }
        .padding(0)
    }
}

/*
public struct CustomTabView: View {
    
    public enum TabBarPosition { // Where the tab bar will be located within the view
        case top
        case bottom
    }
    
    private let tabBarPosition: TabBarPosition
    private let tabText: [String]
    private let tabIconNames: [String]
    private let tabViews: [AnyView]
    
    @State private var selection = 0
    
        public init(tabBarPosition: TabBarPosition, content: [(tabText: String, tabIconName: String, view: AnyView)]) {
        self.tabBarPosition = tabBarPosition
        self.tabText = content.map{ $0.tabText }
        self.tabIconNames = content.map{ $0.tabIconName }
        self.tabViews = content.map{ $0.view }
        }
    
        public var tabBar: some View {
        VStack {
            Spacer()
                .frame(height: 5.0)
            HStack {
                Spacer()
                    .frame(width: 50)
                ForEach(0..<tabText.count) { index in
                    VStack {
                        Image(systemName: self.tabIconNames[index])
                            .font(.system(size: 40))
                        Text(self.tabText[index])
                    }
                    .frame(width: 65, height: 65)
                    .padding(5)
                    .foregroundColor(self.selection == index ? Color.accentColor : Color.primary)
                    .background(Color.secondaryBackgroundColor)
                    .onTapGesture {
                        self.selection = index
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(self.selection == index ? Color.backgroundColor.opacity(0.33) : Color.red.opacity(0.0))
                    )               .onTapGesture {
                        self.selection = index
                    }

                }
                Spacer()
            }
            .frame(alignment: .leading)
            .padding(0)
            .background(Color.secondaryBackgroundColor) // Extra background layer to reset the shadow and stop it applying to every sub-view
            .shadow(color: Color.clear, radius: 0, x: 0, y: 0)
            .background(Color.secondaryBackgroundColor)
            .shadow(
                color: Color.black.opacity(0.25),
                radius: 3,
                x: 0,
                y: tabBarPosition == .top ? 1 : -1
            )
            .zIndex(99) // Raised so that shadow is visible above view backgrounds
        }
        }

    public var body: some View {
        VStack(spacing: 0) {
                if (self.tabBarPosition == .top) {
                tabBar
            }
        
            tabViews[selection]
            .padding(0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
            if (self.tabBarPosition == .bottom) {
            tabBar
            }
    }
    .padding(0)
    }
} */
