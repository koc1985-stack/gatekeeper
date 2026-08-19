import SwiftUI
import SwiftData

struct WageInputView: View {
    var isEditingExisting: Bool = false
    var onContinue: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [UserSettings]

    @State private var mode: IncomeEntryMode = .hourly
    @State private var hourlyText: String = ""
    @State private var monthlyText: String = ""
    @State private var hoursPerWeekText: String = "45"

    private var settings: UserSettings {
        if let existing = settingsList.first { return existing }
        let created = UserSettings()
        modelContext.insert(created)
        return created
    }

    private var computedHourly: Double {
        switch mode {
        case .hourly:
            return Double(hourlyText.replacingOccurrences(of: ",", with: ".")) ?? 0
        case .monthly:
            let monthly = Double(monthlyText.replacingOccurrences(of: ",", with: ".")) ?? 0
            let hours = Double(hoursPerWeekText.replacingOccurrences(of: ",", with: ".")) ?? 45
            return WageCalculator.hourlyWage(fromMonthlyIncome: monthly, hoursPerWeek: hours)
        }
    }

    var body: some View {
        Group {
            if isEditingExisting {
                NavigationStack {
                    form
                        .navigationTitle("Kazanç")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Kaydet") {
                                    save()
                                    dismiss()
                                }
                            }
                        }
                }
            } else {
                form
            }
        }
        .onAppear(perform: load)
    }

    private var form: some View {
        Form {
            Section {
                Picker("Giriş yöntemi", selection: $mode) {
                    Text("Saatlik").tag(IncomeEntryMode.hourly)
                    Text("Aylık maaş").tag(IncomeEntryMode.monthly)
                }
                .pickerStyle(.segmented)
            }
            if mode == .hourly {
                Section("Saatlik net kazancın") {
                    TextField("Örn. 150", text: $hourlyText)
                        .keyboardType(.decimalPad)
                }
            } else {
                Section("Aylık net maaşın") {
                    TextField("Örn. 30000", text: $monthlyText)
                        .keyboardType(.decimalPad)
                }
                Section("Haftalık çalışma saatin") {
                    TextField("Örn. 45", text: $hoursPerWeekText)
                        .keyboardType(.decimalPad)
                }
            }
            Section {
                HStack {
                    Text("Saatlik karşılığın")
                    Spacer()
                    Text(CurrencyFormatter.format(computedHourly, currencyCode: settings.currencyCode))
                        .bold()
                }
            }
            if !isEditingExisting {
                Section {
                    Button("Devam Et") {
                        save()
                        onContinue?()
                    }
                    .disabled(computedHourly <= 0)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
        }
    }

    private func load() {
        let current = settings
        mode = current.incomeEntryMode
        hourlyText = current.hourlyWage > 0 ? String(current.hourlyWage) : ""
        monthlyText = current.monthlyIncome > 0 ? String(current.monthlyIncome) : ""
        hoursPerWeekText = String(current.hoursPerWeek)
    }

    private func save() {
        let current = settings
        current.incomeEntryMode = mode
        switch mode {
        case .hourly:
            current.hourlyWage = computedHourly
        case .monthly:
            current.monthlyIncome = Double(monthlyText.replacingOccurrences(of: ",", with: ".")) ?? 0
            current.hoursPerWeek = Double(hoursPerWeekText.replacingOccurrences(of: ",", with: ".")) ?? 45
        }
    }
}
