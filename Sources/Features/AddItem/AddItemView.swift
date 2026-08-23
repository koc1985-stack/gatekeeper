import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [UserSettings]

    @State private var storeService = StoreService.shared
    @State private var name = ""
    @State private var priceText = ""
    @State private var currencyCode = "TRY"
    @State private var note = ""
    @State private var category: PurchaseCategory = .other
    @State private var cooldownHours: Double = 24
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var mood: Mood?
    @State private var showingNightChallenge = false
    @State private var productLink = ""
    @State private var isFetchingProductInfo = false
    @State private var autoFetchFailed = false
    @State private var isNeed: Bool?
    @State private var alreadyOwnsSimilar: Bool?
    @State private var trigger: PurchaseTrigger?
    @State private var showingInvestmentAnalysis = false
    @State private var showingPaywall = false

    private var settings: UserSettings? { settingsList.first }
    private var price: Double { Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var hourlyWage: Double { settings?.effectiveHourlyWage ?? 0 }
    private var hoursRequired: Double { WageCalculator.hoursRequired(price: price, hourlyWage: hourlyWage) }
    private var isNightRightNow: Bool { settings?.isCurrentlyNight() ?? false }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Ürünün linkini buraya yapıştır (opsiyonel)", text: $productLink)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit { fetchProductInfo() }
                        PasteButton(payloadType: URL.self) { urls in
                            guard let url = urls.first else { return }
                            productLink = url.absoluteString
                            fetchProductInfo()
                        }
                        .labelStyle(.iconOnly)
                    }
                    if isFetchingProductInfo {
                        Label("Ürün bilgileri getiriliyor…", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if !productLink.isEmpty {
                        Button {
                            fetchProductInfo()
                        } label: {
                            Label("Bilgileri Getir", systemImage: "sparkles")
                        }
                        .font(.caption)
                        if autoFetchFailed {
                            Text("Otomatik bulunamadı — adı ve fiyatı elle girebilirsin.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Ürün Linki")
                } footer: {
                    Text("Linki yapıştırınca ürün adını, fiyatını ve görselini otomatik bulmaya çalışırız — her site desteklemeyebilir.")
                }

                Section("Ürün") {
                    TextField("Ne almak istiyorsun?", text: $name)
                    TextField("Fiyat", text: $priceText)
                        .keyboardType(.decimalPad)
                    Picker("Para birimi", selection: $currencyCode) {
                        ForEach(AppCurrency.allCases) { currency in
                            Text("\(currency.rawValue) (\(currency.symbol))").tag(currency.rawValue)
                        }
                    }
                    Picker("Kategori", selection: $category) {
                        ForEach(PurchaseCategory.allCases) { item in
                            Label {
                                Text(item.displayName)
                            } icon: {
                                Image(systemName: item.symbolName)
                            }
                            .tag(item)
                        }
                    }
                    TextField("Not (opsiyonel)", text: $note, axis: .vertical)
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Fotoğraf ekle", systemImage: "photo.badge.plus")
                    }
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Section("Soğuma Süresi") {
                    if storeService.isPremium {
                        Picker("Süre", selection: $cooldownHours) {
                            Text("12 saat").tag(12.0)
                            Text("24 saat").tag(24.0)
                            Text("48 saat").tag(48.0)
                            Text("72 saat").tag(72.0)
                            Text("7 gün").tag(168.0)
                        }
                    } else {
                        HStack {
                            Text("24 saat")
                            Spacer()
                            Text("Premium ile özelleştir")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if price > 0 && hourlyWage > 0 {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bunu almak için")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(WageCalculator.formattedHours(hoursRequired))
                                .font(.title2.bold())
                            Text("çalışman gerekiyor")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if price > 0 {
                    Section("Bu parayı yatırsaydın?") {
                        Button {
                            attemptShowInvestmentAnalysis()
                        } label: {
                            Label("Yatırım Analizini Gör", systemImage: "chart.xyaxis.line")
                        }
                        Text(investmentAnalysisFooter)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                ReflectionSection(
                    isNeed: $isNeed,
                    alreadyOwnsSimilar: $alreadyOwnsSimilar,
                    trigger: $trigger,
                    price: price,
                    monthlyIncome: settings?.effectiveMonthlyIncome ?? 0
                )

                Section("Şu an nasıl hissediyorsun?") {
                    MoodPicker(selection: $mood)
                        .listRowInsets(EdgeInsets())
                        .padding()
                }
            }
            .navigationTitle("Yeni İstek")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") { attemptSave() }
                        .disabled(name.isEmpty || price <= 0)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .onAppear {
                currencyCode = settings?.currencyCode ?? "TRY"
                cooldownHours = settings?.defaultCooldownHours ?? 24
            }
            .onChange(of: productLink) { _, newValue in
                guard name.isEmpty, let url = URL(string: newValue), let host = url.host else { return }
                name = host
            }
            .fullScreenCover(isPresented: $showingNightChallenge) {
                NightChallengeView(
                    challenge: settings?.nightChallenge ?? .hold,
                    onPassed: { save() },
                    onCancel: {}
                )
            }
            .sheet(isPresented: $showingInvestmentAnalysis, onDismiss: markFreeAnalysisUsed) {
                InvestmentAnalysisView(itemPrice: price, currencyCode: currencyCode)
            }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
        }
    }

    private var investmentAnalysisFooter: String {
        if storeService.isPremium {
            return "Premium ile sınırsız yatırım analizi."
        } else if settings?.hasUsedFreeInvestmentAnalysis == true {
            return "Ücretsiz analiz hakkını kullandın — sınırsız erişim için Premium gerekir."
        } else {
            return "İlk analiz ücretsiz. Sonrasında Premium ile sınırsız kullanabilirsin."
        }
    }

    private func attemptShowInvestmentAnalysis() {
        if storeService.isPremium || settings?.hasUsedFreeInvestmentAnalysis != true {
            showingInvestmentAnalysis = true
        } else {
            showingPaywall = true
        }
    }

    private func markFreeAnalysisUsed() {
        guard !storeService.isPremium else { return }
        settings?.hasUsedFreeInvestmentAnalysis = true
    }

    private func fetchProductInfo() {
        guard let url = URL(string: productLink), url.scheme?.hasPrefix("http") == true else { return }
        isFetchingProductInfo = true
        autoFetchFailed = false
        Task {
            let info = await ProductLinkFetcher.fetch(from: url)
            await MainActor.run {
                isFetchingProductInfo = false
                guard let info else {
                    autoFetchFailed = true
                    return
                }
                if let fetchedName = info.name, !fetchedName.isEmpty {
                    name = fetchedName
                }
                if let fetchedPrice = info.price, fetchedPrice > 0 {
                    priceText = String(fetchedPrice)
                }
                if let fetchedCurrency = info.currencyCode, AppCurrency(rawValue: fetchedCurrency) != nil {
                    currencyCode = fetchedCurrency
                }
                autoFetchFailed = (info.name == nil && info.price == nil)
            }
            if let imageURL = info?.imageURL, imageData == nil {
                if let (data, _) = try? await URLSession.shared.data(from: imageURL) {
                    await MainActor.run { imageData = data }
                }
            }
        }
    }

    private func attemptSave() {
        if isNightRightNow {
            showingNightChallenge = true
        } else {
            save()
        }
    }

    private func save() {
        var combinedNote = note
        if !productLink.isEmpty {
            combinedNote = note.isEmpty ? productLink : "\(productLink)\n\(note)"
        }
        let item = PurchaseItem(
            name: name,
            price: price,
            currencyCode: currencyCode,
            note: combinedNote,
            imageData: imageData,
            category: category,
            cooldownHours: cooldownHours,
            mood: mood,
            source: .manual,
            sourceDomain: URL(string: productLink)?.host,
            isNeed: isNeed,
            alreadyOwnsSimilar: alreadyOwnsSimilar,
            trigger: trigger
        )
        modelContext.insert(item)
        NotificationService.shared.scheduleReminder(for: item)
        dismiss()
    }
}
