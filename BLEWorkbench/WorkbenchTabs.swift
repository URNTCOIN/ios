import SwiftUI

struct WorkbenchTabs: View {
    var body: some View {
        TabView {
            NearbyDevicesView()
                .tabItem { Label("Исследовать", systemImage: "dot.radiowaves.left.and.right") }
            TestStandView()
                .tabItem { Label("Тестовый стенд", systemImage: "sensor.tag.radiowaves.forward") }
        }
    }
}

struct NearbyDevicesView: View {
    @EnvironmentObject private var bluetooth: BluetoothLab
    @State private var selectedDevice: SelectedDevice?

    var body: some View {
        NavigationStack {
            ZStack {
                LabTheme.canvas.ignoresSafeArea()
                ambientLight
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        intro
                        scanCard
                        if bluetooth.devices.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 10) {
                                ForEach(bluetooth.devices) { device in
                                    Button { selectedDevice = SelectedDevice(id: device.id) } label: {
                                        DeviceRow(device: device)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 13)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedDevice) { selection in
                DeviceDetailView(deviceID: selection.id)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var intro: some View {
        HStack(alignment: .center, spacing: 13) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(LabTheme.sage)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("BLE Workbench")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .tracking(-0.65)
                    .foregroundStyle(LabTheme.ink)
                Text("Исследуй выбранные BLE-устройства")
                    .font(.system(size: 13))
                    .foregroundStyle(LabTheme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
    }

    private var scanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 9) {
                Circle()
                    .fill(bluetooth.isScanning ? LabTheme.sage : Color.gray.opacity(0.45))
                    .frame(width: 8, height: 8)
                Text(bluetooth.bluetoothState)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LabTheme.ink)
                Spacer()
                if bluetooth.isScanning { ProgressView().tint(LabTheme.sage) }
            }
            Button {
                bluetooth.isScanning ? bluetooth.stopScan() : bluetooth.startScan()
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: bluetooth.isScanning ? "stop.fill" : "dot.radiowaves.left.and.right")
                        .font(.system(size: 13, weight: .semibold))
                    Text(bluetooth.isScanning ? "Остановить сканирование" : "Сканировать BLE")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 49)
                .background(LabTheme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            Text("Сканирование работает, пока открыт этот экран. Найденные устройства остаются только в памяти приложения.")
                .font(.system(size: 11))
                .lineSpacing(2)
                .foregroundStyle(LabTheme.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.8), lineWidth: 1) }
        .shadow(color: LabTheme.ink.opacity(0.06), radius: 18, x: 0, y: 9)
    }

    private var emptyState: some View {
        VStack(spacing: 9) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(LabTheme.sage.opacity(0.8))
                .padding(.bottom, 3)
            Text(bluetooth.devices.isEmpty && bluetooth.isScanning ? "Ищем устройства" : "Пока ничего не найдено")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(LabTheme.ink)
            Text("Запусти сканирование рядом со своим BLE-устройством.")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(LabTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
    }

    private var ambientLight: some View {
        GeometryReader { proxy in
            ZStack {
                Circle().fill(.white.opacity(0.8)).frame(width: 240).blur(radius: 64)
                    .position(x: proxy.size.width * 0.08, y: proxy.size.height * 0.08)
                Circle().fill(LabTheme.sage.opacity(0.14)).frame(width: 280).blur(radius: 76)
                    .position(x: proxy.size.width * 0.97, y: proxy.size.height * 0.76)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

private struct SelectedDevice: Identifiable {
    let id: UUID
}

private struct DeviceRow: View {
    let device: PeripheralSnapshot

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.isConnected ? "point.3.connected.trianglepath.dotted" : "wave.3.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(device.isConnected ? LabTheme.sage : LabTheme.secondary)
                .frame(width: 42, height: 42)
                .background(LabTheme.paleSage.opacity(0.8), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LabTheme.ink)
                    .lineLimit(1)
                Text(device.advertisedServices.isEmpty ? device.id.uuidString.uppercased() : device.advertisedServices.joined(separator: " · "))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(LabTheme.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(device.rssi) dBm")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(LabTheme.ink)
                Text(device.isConnected ? "Подключено" : "Найдено")
                    .font(.system(size: 10))
                    .foregroundStyle(LabTheme.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(LabTheme.secondary.opacity(0.7))
        }
        .padding(13)
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.82), lineWidth: 1) }
    }
}

struct DeviceDetailView: View {
    @EnvironmentObject private var bluetooth: BluetoothLab
    @Environment(\.dismiss) private var dismiss
    let deviceID: UUID

    private var device: PeripheralSnapshot? { bluetooth.devices.first(where: { $0.id == deviceID }) }

    var body: some View {
        NavigationStack {
            Group {
                if let device {
                    List {
                        Section("Устройство") {
                            LabeledContent("Имя", value: device.name)
                            LabeledContent("Сигнал", value: "\(device.rssi) dBm")
                            LabeledContent("ID iOS", value: device.id.uuidString.uppercased())
                            LabeledContent("Состояние", value: device.isConnected ? "Подключено" : "Не подключено")
                        }
                        Section("GATT-сервисы") {
                            if device.discoveredServices.isEmpty {
                                Text(device.isConnected ? "Ожидание списка сервисов…" : "Подключись, чтобы прочитать список сервисов.")
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(device.discoveredServices) { service in
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(service.uuid).font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    ForEach(service.characteristics) { characteristic in
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack(alignment: .top) {
                                                Text(characteristic.uuid)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .textSelection(.enabled)
                                                Spacer(minLength: 8)
                                                if characteristic.properties.contains("Read"), device.isConnected {
                                                    Button("Читать") {
                                                        bluetooth.read(characteristic.uuid, from: deviceID, serviceID: service.uuid)
                                                    }
                                                    .font(.system(size: 11, weight: .semibold))
                                                }
                                            }
                                            Text(characteristic.properties.joined(separator: " · "))
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                            if let value = characteristic.lastValue {
                                                Text(value)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundStyle(.secondary)
                                                    .textSelection(.enabled)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        Section {
                            Text("Показаны только данные, доступные через Core Bluetooth. Это не радиоперехват и не оценка безопасности устройства.")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(device.isConnected ? "Отключить" : "Подключиться") {
                                device.isConnected ? bluetooth.disconnect(deviceID) : bluetooth.connect(to: deviceID)
                            }
                            .font(.system(size: 13, weight: .semibold))
                        }
                        ToolbarItem(placement: .principal) {
                            Text("BLE-устройство").font(.system(size: 15, weight: .semibold))
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Готово") { dismiss() }
                        }
                    }
                } else {
                    ContentUnavailableView("Устройство пропало", systemImage: "antenna.radiowaves.left.and.right")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
