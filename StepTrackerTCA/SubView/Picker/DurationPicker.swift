//
//  DurationPicker.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 22/02/2025.
//

import SwiftUI

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    private var hours: Int { Int(duration) / 3600 }
    private var minutes: Int { (Int(duration) % 3600) / 60 }
    private var seconds: Int { Int(duration) % 60 }
    
    var body: some View {
        HStack {
            Picker("", selection: Binding(
                get: { self.hours },
                set: { newHours in
                    self.duration = TimeInterval(newHours * 3600 + minutes * 60 + seconds)
                }
            )) {
                ForEach(0..<24, id: \.self) { hour in
                    Text("\(hour) h").tag(hour)
                }
            }
            
            Picker("", selection: Binding(
                get: { self.minutes },
                set: { newMinutes in
                    self.duration = TimeInterval(hours * 3600 + newMinutes * 60 + seconds)
                }
            )) {
                ForEach(0..<60, id: \.self) { minute in
                    Text("\(minute) m").tag(minute)
                        
                }
            }
            
            Picker("", selection: Binding(
                get: { self.seconds },
                set: { newSeconds in
                    self.duration = TimeInterval(hours * 3600 + minutes * 60 + newSeconds)
                }
            )) {
                ForEach(0..<60, id: \.self) { second in
                    Text("\(second) s").tag(second)
                }
            }
        }
    }
    
}
