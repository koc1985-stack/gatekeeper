import SwiftUI
import SwiftData

struct AddFromShareView: View {
    let sourceURL: String?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var priceText = ""
    @State private var currencyCode = "TRY"
    @State private var mood: Mood?

    init(initialName: String, sourceURL: String?, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.sourceURL = sourceURL
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: initialName)
    }

    private var price: Double { Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ürün") {
                    TextField("Ürün adı", text: $name)
                    TextField("Fiyat", text: $priceText)
                        .keyboardType(.decimalPad)
                    Picker("Para birimi", selection: $currencyCode) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text("\(currency.rawValue) (\(currency.symbol))").tag(currency.rawValue)
                        }
                    }
                }
                Section("Şu an nasıl hissediyorsun?") {
                    MoodPicker(selection: $mood)
                        .listRowInsets(EdgeInsets())
                        .padding()
                }
            }
            .navigationTitle("Bekle'ye Ekle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") { save() }
                        .disabled(name.isEmpty || price <= 0)
                }
            }
            .onAppear {
                let settings = (try? ModelContext(SharedModelContainer.make()).fetch(FetchDescriptor<UserSettings>()))?.first
                if let settings { currencyCode = settings.currencyCode }
            }
        }
    }

    private func save() {
        let context = ModelContext(SharedModelContainer.make())
        let settings = (try? context.fetch(FetchDescriptor<UserSettings>()))?.first
        let item = PurchaseItem(
            name: name,
            price: price,
            currencyCode: currencyCode,
            category: .other,
            cooldownHours: settings?.defaultCooldownHours ?? 24,
            mood: mood,
            source: .extensionSource,
            sourceDomain: sourceURL.flatMap { URL(string: $0)?.host }
        )
        context.insert(item)
        try? context.save()
        onSave()
    }
}
