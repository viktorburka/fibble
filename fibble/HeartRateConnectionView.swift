//
//  HeartRateConnectionView.swift
//  fibble
//
//  Created by Viktor Burka on 9/19/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct HeartRateConnectionView: View {
    @Binding var state: HeartRateProviderState
    var body: some View {
        Image(systemName: stateImage(state: self.state))
            .font(.system(size: 60, weight: .regular)).foregroundColor(.gray)
            .opacity(state == .ready ? 0.0 : 1.0)
    }
    
    func stateImage(state: HeartRateProviderState) -> String {
        switch state {
        case .powerOff:
            return "0.circle"
        case .powerOn:
            return "1.circle"
        case .scan:
            return "2.circle"
        case .connect:
            return "3.circle"
        case .discoverServices:
            return "4.circle"
        case .discoverCharacteristics:
            return "5.circle"
        case .ready:
            return "circle.fill"
        }
    }
}

struct HeartRateConnectionView_Previews: PreviewProvider {
    @State static var state = HeartRateProviderState.ready
    static var previews: some View {
        HeartRateConnectionView(state: $state)
    }
}
