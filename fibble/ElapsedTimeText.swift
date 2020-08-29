//
//  ElapsedTimeText.swift
//  fibble
//
//  Created by Viktor Burka on 8/26/20.
//  Copyright © 2020 Viktor Burka. All rights reserved.
//

import SwiftUI

struct ElapsedTimeText: View {
    @State var ti: TimeInterval
    var body: some View {
        Text(String(format: "%02d:%02d:%02d", Int(self.ti) / 3600, Int(self.ti) / 60 % 60, Int(self.ti) % 60)).font(Font.system(size: 80).monospacedDigit())
    }
}

struct ElapsedTimeText_Previews: PreviewProvider {
    static var previews: some View {
        ElapsedTimeText(ti: TimeInterval())
    }
}
