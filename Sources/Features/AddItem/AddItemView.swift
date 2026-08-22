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
    @State private var showPasteSuggestion = false

    private var settings: UserSettings? { settingsList.first }
    private var price: Double { Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var hourlyWage: Double { settings?.effectiveHourlyWage ?? 0 }
    private var hoursRequired: Double { WageCalculator.hoursRequired(price: price, hourlyWage: hourlyWage) }
    private var isNightRightNow: Bool { settings?.isCurrentlyNight() ?? false }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ürün") {
                    if showPasteSuggestion {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            Label("Panodaki linki yapıştır", systemImage: "doc.on.clipboard")
                        }
                    }
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
                        OpportunityCostRow(price: price, currencyCode: currencyCode, asset: .sp500)
                        OpportunityCostRow(price: price, currencyCode: currencyCode, asset: .gold)
                        Text("Geçmiş performans, gelecek için garanti değildir. Uzun vadeli ortalamalara dayalı kaba bir tahmindir.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

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
                // .hasURLs only checks presence/type — unlike .url/.string, it does NOT trigger
                // the system "X pasted from your clipboard" banner, so this is safe to check silently.
                showPasteSuggestion = UIPasteboard.general.hasURLs
            }
            .fullScreenCover(isPresented: $showingNightChallenge) {
                NightChallengeView(
                    challenge: settings?.nightChallenge ?? .hold,
                    onPassed: { save() },
                    onCancel: {}
                )
            }
        }
    }

    private func pasteFromClipboard() {
        if let url = UIPasteboard.general.url {
            note = url.absoluteString
            if name.isEmpty {
                name = url.host ?? url.absoluteString
            }
        }
        showPasteSuggestion = false
    }

    private func attemptSave() {
        if isNightRightNow {
            showingNightChallenge = true
        } else {
            save()
        }
    }

    private func save() {
        let item = PurchaseItem(
            name: name,
            price: price,
            currencyCode: currencyCode,
            note: note,
            imageData: imageData,
            category: category,
            cooldownHours: cooldownHours,
            mood: mood,
            source: .manual
        )
        modelContext.insert(item)
        NotificationService.shared.scheduleReminder(for: item)
        dismiss()
    }
}

private struct OpportunityCostRow: View {
    let price: Double
    let currencyCode: String
    let asset: InvestmentAsset
    private let years: Double = 3

    private var projected: Double {
        WageCalculator.projectedValue(principal: price, years: years, annualRate: asset.annualReturnRate)
    }

    var body: some View {
        HStack {
            Text(asset.displayName)
                .font(.subheadline)
            Spacer()
            Text("3 yılda \(CurrencyFormatter.format(projected, currencyCode: currencyCode))")
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        }
    }
}
