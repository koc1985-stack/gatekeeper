import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsList: [UserSettings]
    @State private var storeService = StoreService.shared
    @State private var showingPaywall = false
    @State private var showingWageEditor = false

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kazanç") {
                    Button {
                        showingWageEditor = true
                    } label: {
                        HStack {
                            Text("Saatlik ücret")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(CurrencyFormatter.format(settings?.effectiveHourlyWage ?? 0, currencyCode: settings?.currencyCode ?? "TRY"))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let settings {
                    Section("Bekleme Süresi") {
                        Picker("Varsayılan süre", selection: Binding(
                            get: { settings.defaultCooldownHours },
                            set: { settings.defaultCooldownHours = $0 }
                        )) {
                            Text("12 saat").tag(12.0)
                            Text("24 saat").tag(24.0)
                            Text("48 saat").tag(48.0)
                            Text("72 saat").tag(72.0)
                            Text("7 gün").tag(168.0)
                        }
                        .disabled(!storeService.isPremium)
                        if !storeService.isPremium {
                            Text("Özel süreler Premium ile açılır")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Para Birimi") {
                        Picker("Para birimi", selection: Binding(
                            get: { settings.currencyCode },
                            set: { settings.currencyCode = $0 }
                        )) {
                            ForEach(AppCurrency.allCases) { currency in
                                Text("\(currency.rawValue) (\(currency.symbol))").tag(currency.rawValue)
                            }
                        }
                    }

                    Section("Bildirimler") {
                        Toggle("Hatırlatma bildirimleri", isOn: Binding(
                            get: { settings.notificationsEnabled },
                            set: { newValue in
                                settings.notificationsEnabled = newValue
                                if newValue {
                                    Task { await NotificationService.shared.requestAuthorization() }
                                }
                            }
                        ))
                    }
                }

                Section("Premium") {
                    if storeService.isPremium {
                        Label("Premium aktif", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Premium'a Geç") { showingPaywall = true }
                    }
                    Button("Satın alımları geri yükle") {
                        Task { await storeService.restore() }
                    }
                }

                Section("Senkronizasyon") {
                    Label("iCloud ile otomatik senkronize edilir", systemImage: "icloud.fill")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Bekle v1.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ayarlar")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingWageEditor) { WageInputView(isEditingExisting: true) }
        }
    }
}
