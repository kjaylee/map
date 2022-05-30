//
//  ContentView.swift
//  map
//
//  Created by DEV on 2022/05/27.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MapView()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

