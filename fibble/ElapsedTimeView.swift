//
//  ElapsedTimeView.swift
//  fibble
//
//  Created by Viktor Burka on 9/8/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct ElapsedTimeView: View {
    @Binding var elapsed: TimeInterval
    var body: some View {
        Text(String(format: "%02d:%02d:%02d", Int(elapsed) / 3600, Int(elapsed) / 60 % 60, Int(elapsed) % 60))
//            .font(Font.system(size: 80).monospacedDigit())
    }
}

struct ElapsedTimeView_Previews: PreviewProvider {
    @State static var elapsed = TimeInterval(20.0)
    static var previews: some View {
        ElapsedTimeView(elapsed: $elapsed)
    }
}
