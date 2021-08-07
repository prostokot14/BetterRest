//
//  ContentView.swift
//  BetterRest
//
//  Created by Антон Кашников on 02.08.2021.
//
import SwiftUI
struct ContentView: View {
    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = 8.0 // Desired amount of sleep
    @State private var coffeeAmount = 1 // Daily coffee intake (in cups)
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var activeAlert: ActiveAlert = .first
    // Static variable, which means it belongs to the ContentView struct itself rather than a single instance of that struct. This in turn means defaultWakeTime can be read whenever we want, because it doesn’t rely on the existence of any other properties.
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    enum ActiveAlert {
        case first, second
    }
    func calculateBedtime() -> String {
        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: wakeUp
        ) // Decomposition into components (hours and minutes) of the wake-up date
        let hour = (components.hour ?? 0) * 3_600 // Converting hours to seconds
        let minute = (components.minute ?? 0) * 60 // Converting minutes to seconds
        do {
            let model = try SleepCalculator(configuration: .init()) // an instance of the SleepCalculator class
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount)) // Filling in the model fields
            let sleepTime = wakeUp - prediction.actualSleep // Calculation of the time required for sleep (Subtract from the number of seconds that have passed since midnight, the number of seconds needed for sleep)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Your ideal bedtime is " + formatter.string(from: sleepTime) // Converting to string
        } catch {
            activeAlert = .second
            showingAlert = true
            return ""
        }
    }
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("When do you wanna wake up?").font(.headline)) {
                    DatePicker(
                        "Please enter a time",
                        selection: $wakeUp,
                        displayedComponents: .hourAndMinute
                    )
                }
                Section(
                    header: Text("Desired amount of sleep").font(.headline),
                    content: {
                        Stepper(
                            value: $sleepAmount,
                            in: 4...12,
                            step: 0.25
                        ) {
                            Text("\(sleepAmount, specifier: "%g") hours")
                        }
                    }
                )
                Section(header: Text("Daily coffee intake").font(.headline)) {
                    Picker(
                        "Daily coffee intake",
                        selection: $coffeeAmount
                    ) {
                        ForEach(1..<21) {
                            if $0 == 1 {
                                Text("1 cup")
                            } else {
                                Text("\($0) cups")
                            }
                        }
                    }
                }
                Section(header: Text("Recommended bedtime").font(.headline)) {
                    Text(calculateBedtime())
                }
            }
            .navigationBarTitle("BetterRest")
            .navigationBarItems(
                trailing: Button(
                    "Calculate",
                    action: {
                        let _ = calculateBedtime()
                        showingAlert = true
                    }
                )
            )
            .alert(isPresented: $showingAlert) {
                switch activeAlert {
                case .first:
                    return Alert(
                        title: Text("Ideal bedtime"),
                        message: Text(calculateBedtime()),
                        dismissButton: .default(Text("OK"))
                    )
                case .second:
                    return Alert(
                        title: Text("Something went wrong"),
                        message: Text("There was a problem calculating your bedtime"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
