import SwiftUI

struct TestStandView: View {
    @EnvironmentObject private var bluetooth: BluetoothLab
    @State private var localValue = "BLE Workbench test value"

    var body: some View {
        NavigationStack {
            ZStack {
                LabTheme.canvas.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 17) {
                            header
                            serviceCard
                            valueCard
                            safetyNote
                            logHeader
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                    }
                    .scrollIndicators(.hidden)
                    logPanel
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { localValue = bluetooth.testValueText }
            .onChange(of: bluetooth.testValueText) { _, value in localValue = value }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Тестовый стенд")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .tracking(-0.7)
                .foregroundStyle(LabTheme.ink)
            Text("Этот iPhone публикует тестовый GATT-сервис для проверки твоего BLE-клиента.")
                .font(.system(size: 14))
                .lineSpacing(3)
                .foregroundStyle(LabTheme.secondary)
        }
    }

    private var serviceCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("ДЕМО-СЕРВИС")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(LabTheme.secondary)
                    Text(BluetoothLab.testServiceID.uuidString)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(LabTheme.ink)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 8)
                Circle()
                    .fill(bluetooth.isAdvertising ? LabTheme.sage : Color.gray.opacity(0.4))
                    .frame(width: 9, height: 9)
                    .padding(.top, 3)
            }
            Divider().overlay(.white.opacity(0.5))
            VStack(alignment: .leading, spacing: 6) {
                Text("ТЕСТОВАЯ ХАРАКТЕРИСТИКА")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(LabTheme.secondary)
                Text(BluetoothLab.testCharacteristicID.uuidString)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(LabTheme.ink)
                    .textSelection(.enabled)
                Text("Read · Write · Notify")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LabTheme.sage)
            }
            HStack(spacing: 8) {
                Image(systemName: "dot.radiowaves.left.and.right")
                Text(bluetooth.standState)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(LabTheme.secondary)
            Button {
                bluetooth.isAdvertising ? bluetooth.stopTestStand() : bluetooth.startTestStand()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: bluetooth.isAdvertising ? "stop.fill" : "antenna.radiowaves.left.and.right")
                    Text(bluetooth.isAdvertising ? "Остановить стенд" : "Запустить стенд")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(LabTheme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 23, style: .continuous).strokeBorder(.white.opacity(0.84), lineWidth: 1) }
        .shadow(color: LabTheme.ink.opacity(0.06), radius: 18, x: 0, y: 9)
    }

    private var valueCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("ЗНАЧЕНИЕ ДЛЯ ПРОВЕРКИ")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(LabTheme.secondary)
            TextField("Тестовый текст", text: $localValue, axis: .vertical)
                .font(.system(size: 14))
                .lineLimit(1...4)
                .padding(13)
                .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 15, style: .continuous).strokeBorder(.white, lineWidth: 1) }
            Button("Обновить локальное значение") {
                bluetooth.updateTestValue(localValue)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(LabTheme.sage)
            .disabled(!bluetooth.isAdvertising)
        }
        .padding(16)
        .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1) }
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(LabTheme.sage)
            Text("Стенд предоставляет только этот тестовый сервис. Журнал остаётся на устройстве и очищается при закрытии приложения.")
                .font(.system(size: 12))
                .lineSpacing(2)
                .foregroundStyle(LabTheme.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LabTheme.paleSage.opacity(0.55), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var logHeader: some View {
        HStack {
            Text("СЕССИЯ")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(LabTheme.secondary)
            Spacer()
            Button("Очистить") { bluetooth.clearTestLog() }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LabTheme.sage)
        }
    }

    private var logPanel: some View {
        Group {
            if bluetooth.testLog.isEmpty {
                Text("События подключения появятся здесь")
                    .font(.system(size: 12))
                    .foregroundStyle(LabTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 19)
                    .padding(.vertical, 13)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(bluetooth.testLog.enumerated()), id: \.offset) { _, entry in
                            Text(entry)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(LabTheme.ink.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 19)
                    .padding(.vertical, 13)
                }
                .frame(maxHeight: 118)
            }
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.8)).frame(height: 1) }
    }
}
