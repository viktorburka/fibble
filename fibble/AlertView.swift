//
//  AlertView.swift
//  fibble
//
//  Created by Viktor Burka on 9/13/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct AlertView: View {
    @Binding var heartRateAlert: Bool
    @Binding var hydrationAlert: Bool
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "heart.slash")
                .opacity(heartRateAlert ? 1 : 0)
                .font(.system(size: 30, weight: .regular)).foregroundColor(.red)
            Image(systemName: "cloud.heavyrain")
                .opacity(hydrationAlert ? 1 : 0)
                .font(.system(size: 30, weight: .regular)).foregroundColor(.blue)
        }
    }
}

struct AlertView_Previews: PreviewProvider {
    @State static var heartRateAlert = true
    @State static var hydrationAlert = true
    static var previews: some View {
        AlertView(heartRateAlert: $heartRateAlert, hydrationAlert: $hydrationAlert)
    }
}
