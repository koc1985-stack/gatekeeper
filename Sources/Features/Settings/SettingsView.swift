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
                ProfileSection()

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

                    Section {
                        Toggle("Gece Kuşu Kilidi", isOn: Binding(
                            get: { settings.nightModeEnabled },
                            set: { settings.nightModeEnabled = $0 }
                        ))
                        if settings.nightModeEnabled {
                            Stepper(
                                "Başlangıç: \(settings.nightModeStartHour):00",
                                value: Binding(
                                    get: { settings.nightModeStartHour },
                                    set: { settings.nightModeStartHour = $0 }
                                ),
                                in: 0...23
                            )
                            Stepper(
                                "Bitiş: \(settings.nightModeEndHour):00",
                                value: Binding(
                                    get: { settings.nightModeEndHour },
                                    set: { settings.nightModeEndHour = $0 }
                                ),
                                in: 0...23
                            )
                            Picker("Zorluk", selection: Binding(
                                get: { settings.nightChallenge },
                                set: { settings.nightChallenge = $0 }
                            )) {
                                ForEach(NightChallenge.allCases) { challenge in
                                    Text(challenge.displayName).tag(challenge)
                                }
                            }
                        }
                    } header: {
                        Text("Gece Kuşu Kilidi")
                    } footer: {
                        Text("Belirlediğin gece saatlerinde hem uygulamada hem Safari uzantısında ekstra bir engel gösterilir.")
                    }

                    Section {
                        NavigationLink {
                            ExtensionSetupView()
                        } label: {
                            Label("Safari Uzantısını Etkinleştir", systemImage: "safari.fill")
                        }
                    } footer: {
                        Text("Trendyol, Amazon, Zara ve H&M ödeme sayfalarında otomatik uyarı için gerekir.")
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
                    Text("DurBi v1.0")
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
