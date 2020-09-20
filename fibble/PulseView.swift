//
//  PulseView.swift
//  fibble
//
//  Created by Viktor Burka on 9/19/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct PulseView: View {
    @Binding var pulse: Bool
    var body: some View {
        Image(systemName: "circle.fill")
            .opacity(pulse ? 1.0 : 0.0)
            .font(.system(size: 10, weight: .regular)).foregroundColor(.green)
            .animation(/*@START_MENU_TOKEN@*/.easeIn/*@END_MENU_TOKEN@*/)
    }
}

//struct PulseView_Previews: PreviewProvider {
//    static var previews: some View {
//        PulseView()
//    }
//}
