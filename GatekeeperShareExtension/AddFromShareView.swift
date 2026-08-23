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
    @State private var isNeed: Bool?
    @State private var alreadyOwnsSimilar: Bool?
    @State private var trigger: PurchaseTrigger?
    @State private var consideration: ConsiderationPeriod?
    @State private var isFetchingProductInfo = false
    @State private var monthlyIncome: Double = 0
    @State private var imageData: Data?

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
                    if isFetchingProductInfo {
                        Label("Ürün bilgileri getiriliyor…", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    TextField("Ürün adı", text: $name)
                    TextField("Fiyat", text: $priceText)
                        .keyboardType(.decimalPad)
                    Picker("Para birimi", selection: $currencyCode) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text("\(currency.rawValue) (\(currency.symbol))").tag(currency.rawValue)
                        }
                    }
                }

                ReflectionSection(
                    isNeed: $isNeed,
                    alreadyOwnsSimilar: $alreadyOwnsSimilar,
                    trigger: $trigger,
                    consideration: $consideration,
                    price: price,
                    monthlyIncome: monthlyIncome,
                    mood: mood
                )

                Section("Şu an nasıl hissediyorsun?") {
                    MoodPicker(selection: $mood)
                        .listRowInsets(EdgeInsets())
                        .padding()
                }
            }
            .navigationTitle("DurBi'ye Ekle")
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
                if let settings {
                    currencyCode = settings.currencyCode
                    monthlyIncome = settings.effectiveMonthlyIncome
                }
                fetchProductInfoIfPossible()
            }
        }
    }

    private func fetchProductInfoIfPossible() {
        guard let sourceURL, let url = URL(string: sourceURL) else { return }
        isFetchingProductInfo = true
        Task {
            let info = await ProductLinkFetcher.fetch(from: url)
            await MainActor.run {
                isFetchingProductInfo = false
                guard let info else { return }
                if let fetchedName = info.name, !fetchedName.isEmpty {
                    name = fetchedName
                }
                if let fetchedPrice = info.price, fetchedPrice > 0 {
                    priceText = String(fetchedPrice)
                }
                if let fetchedCurrency = info.currencyCode, AppCurrency(rawValue: fetchedCurrency) != nil {
                    currencyCode = fetchedCurrency
                }
            }
            if let imageURL = info?.imageURL, let (data, _) = try? await URLSession.shared.data(from: imageURL) {
                await MainActor.run { imageData = data }
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
            imageData: imageData,
            category: .other,
            cooldownHours: settings?.defaultCooldownHours ?? 24,
            mood: mood,
            source: .extensionSource,
            sourceDomain: sourceURL.flatMap { URL(string: $0)?.host },
            isNeed: isNeed,
            alreadyOwnsSimilar: alreadyOwnsSimilar,
            trigger: trigger,
            consideration: consideration
        )
        context.insert(item)
        try? context.save()
        onSave()
    }
}
