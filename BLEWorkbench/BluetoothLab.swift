import CoreBluetooth
import Combine
import Foundation

struct PeripheralSnapshot: Identifiable {
    let id: UUID
    var peripheral: CBPeripheral
    var name: String
    var rssi: Int
    var lastSeen: Date
    var advertisedServices: [String]
    var discoveredServices: [ServiceSnapshot] = []
    var isConnected = false
}

struct ServiceSnapshot: Identifiable {
    var id: String { uuid }
    let uuid: String
    var characteristics: [CharacteristicSnapshot]
}

struct CharacteristicSnapshot: Identifiable {
    var id: String { uuid }
    let uuid: String
    let properties: [String]
    var lastValue: String?
}

@MainActor
final class BluetoothLab: NSObject, ObservableObject {
    @Published private(set) var devices: [PeripheralSnapshot] = []
    @Published private(set) var bluetoothState = "Проверка Bluetooth…"
    @Published private(set) var isScanning = false
    @Published private(set) var standState = "Тестовый стенд выключен"
    @Published private(set) var isAdvertising = false
    @Published private(set) var testLog: [String] = []
    @Published private(set) var testValueText = "BLE Workbench test value"

    private var central: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var testService: CBMutableService?
    private var testCharacteristic: CBMutableCharacteristic?
    private var servicePublished = false
    private var shouldAdvertise = false
    private var testValue = Data("BLE Workbench test value".utf8)

    static let testServiceID = CBUUID(string: "4D7A1000-5A31-4F17-9F2B-5B7D1C4B8001")
    static let testCharacteristicID = CBUUID(string: "4D7A1001-5A31-4F17-9F2B-5B7D1C4B8001")

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            bluetoothState = stateDescription(central.state)
            return
        }
        devices = []
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        isScanning = true
        bluetoothState = "Сканирование BLE"
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        bluetoothState = stateDescription(central.state)
    }

    func connect(to id: UUID) {
        guard let device = devices.first(where: { $0.id == id }) else { return }
        stopScan()
        bluetoothState = "Подключение к \(device.name)…"
        central.connect(device.peripheral, options: nil)
    }

    func disconnect(_ id: UUID) {
        guard let device = devices.first(where: { $0.id == id }) else { return }
        central.cancelPeripheralConnection(device.peripheral)
    }

    func read(_ characteristicID: String, from deviceID: UUID, serviceID: String) {
        guard let device = devices.first(where: { $0.id == deviceID }),
              let service = device.peripheral.services?.first(where: { $0.uuid.uuidString == serviceID }),
              let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == characteristicID }),
              characteristic.properties.contains(.read) else { return }
        device.peripheral.readValue(for: characteristic)
    }

    func startTestStand() {
        shouldAdvertise = true
        guard peripheralManager.state == .poweredOn else {
            standState = stateDescription(peripheralManager.state)
            return
        }
        prepareTestServiceIfNeeded()
    }

    func stopTestStand() {
        shouldAdvertise = false
        peripheralManager.stopAdvertising()
        isAdvertising = false
        standState = "Тестовый стенд выключен"
        appendLog("Реклама остановлена")
    }

    func clearTestLog() { testLog = [] }

    func updateTestValue(_ text: String) {
        testValueText = String(text.prefix(180))
        testValue = Data(testValueText.utf8)
        testCharacteristic?.value = testValue
        if let testCharacteristic {
            _ = peripheralManager.updateValue(testValue, for: testCharacteristic, onSubscribedCentrals: nil)
        }
        appendLog("Локальное тестовое значение обновлено (\(testValue.count) байт)")
    }

    private func prepareTestServiceIfNeeded() {
        guard !servicePublished else {
            beginAdvertisingIfRequested()
            return
        }
        guard testService == nil else { return }

        let characteristic = CBMutableCharacteristic(
            type: Self.testCharacteristicID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        let service = CBMutableService(type: Self.testServiceID, primary: true)
        service.characteristics = [characteristic]
        testCharacteristic = characteristic
        testService = service
        peripheralManager.add(service)
        standState = "Публикация тестового GATT-сервиса…"
    }

    private func beginAdvertisingIfRequested() {
        guard shouldAdvertise, peripheralManager.state == .poweredOn else { return }
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [Self.testServiceID],
            CBAdvertisementDataLocalNameKey: "BLE Workbench"
        ])
    }

    private func appendLog(_ message: String) {
        let stamp = Date.now.formatted(date: .omitted, time: .standard)
        testLog.insert("\(stamp)  \(message)", at: 0)
        if testLog.count > 150 { testLog.removeLast(testLog.count - 150) }
    }

    private func stateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown: return "Состояние Bluetooth неизвестно"
        case .resetting: return "Bluetooth перезапускается"
        case .unsupported: return "Bluetooth LE не поддерживается"
        case .unauthorized: return "Нет разрешения на Bluetooth"
        case .poweredOff: return "Включи Bluetooth в настройках iPhone"
        case .poweredOn: return "Bluetooth готов"
        @unknown default: return "Неизвестное состояние Bluetooth"
        }
    }

    private func updateDevice(_ peripheral: CBPeripheral, _ change: (inout PeripheralSnapshot) -> Void) {
        guard let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) else { return }
        var updated = devices[index]
        change(&updated)
        devices[index] = updated
    }
}

extension BluetoothLab: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = stateDescription(central.state)
        if central.state != .poweredOn { isScanning = false }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
            ?? peripheral.name
            ?? "Без имени · \(peripheral.identifier.uuidString.prefix(8))"
        let services = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []).map(\.uuidString)
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            var updated = devices[index]
            updated.name = name
            updated.rssi = RSSI.intValue
            updated.lastSeen = .now
            updated.advertisedServices = services
            updated.peripheral = peripheral
            devices[index] = updated
        } else {
            devices.append(PeripheralSnapshot(
                id: peripheral.identifier,
                peripheral: peripheral,
                name: name,
                rssi: RSSI.intValue,
                lastSeen: .now,
                advertisedServices: services
            ))
        }
        devices.sort { $0.rssi > $1.rssi }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        updateDevice(peripheral) { $0.isConnected = true }
        bluetoothState = "Подключено: \(peripheral.name ?? "BLE-устройство")"
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        updateDevice(peripheral) { $0.isConnected = false }
        bluetoothState = error?.localizedDescription ?? "Не удалось подключиться"
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        updateDevice(peripheral) { $0.isConnected = false }
        bluetoothState = error.map { "Отключено: \($0.localizedDescription)" } ?? "Устройство отключено"
    }
}

extension BluetoothLab: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil { return }
        updateDevice(peripheral) { item in
            item.discoveredServices = (peripheral.services ?? []).map {
                ServiceSnapshot(uuid: $0.uuid.uuidString, characteristics: [])
            }
        }
        peripheral.services?.forEach { peripheral.discoverCharacteristics(nil, for: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        let characteristics = (service.characteristics ?? []).map { characteristic in
            CharacteristicSnapshot(uuid: characteristic.uuid.uuidString, properties: propertyNames(characteristic.properties))
        }
        updateDevice(peripheral) { item in
            guard let index = item.discoveredServices.firstIndex(where: { $0.uuid == service.uuid.uuidString }) else { return }
            item.discoveredServices[index].characteristics = characteristics
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            bluetoothState = "Чтение не выполнено: \(error.localizedDescription)"
            return
        }
        let value = characteristic.value ?? Data()
        let hex = value.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " ")
        let text = String(data: value, encoding: .utf8).map { String($0.prefix(100)) }
        let preview = [text, hex.isEmpty ? nil : "HEX: \(hex)"]
            .compactMap { $0 }
            .joined(separator: "\n")
        updateDevice(peripheral) { item in
            guard let serviceIndex = item.discoveredServices.firstIndex(where: { $0.uuid == characteristic.service?.uuid.uuidString }),
                  let characteristicIndex = item.discoveredServices[serviceIndex].characteristics.firstIndex(where: { $0.uuid == characteristic.uuid.uuidString }) else { return }
            item.discoveredServices[serviceIndex].characteristics[characteristicIndex].lastValue = preview.isEmpty ? "Пустое значение" : preview
        }
    }

    private func propertyNames(_ properties: CBCharacteristicProperties) -> [String] {
        var names: [String] = []
        if properties.contains(.read) { names.append("Read") }
        if properties.contains(.write) { names.append("Write") }
        if properties.contains(.writeWithoutResponse) { names.append("Write no response") }
        if properties.contains(.notify) { names.append("Notify") }
        if properties.contains(.indicate) { names.append("Indicate") }
        if properties.contains(.authenticatedSignedWrites) { names.append("Signed write") }
        if properties.contains(.notifyEncryptionRequired) { names.append("Notify: encryption required") }
        if properties.contains(.indicateEncryptionRequired) { names.append("Indicate: encryption required") }
        return names.isEmpty ? ["No standard properties"] : names
    }
}

extension BluetoothLab: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        standState = stateDescription(peripheral.state)
        guard peripheral.state == .poweredOn else {
            isAdvertising = false
            return
        }
        prepareTestServiceIfNeeded()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            standState = "Не удалось опубликовать тестовый сервис"
            appendLog("Ошибка публикации GATT-сервиса")
            return
        }
        servicePublished = true
        standState = "Тестовый GATT-сервис готов"
        appendLog("Опубликован тестовый GATT-сервис")
        beginAdvertisingIfRequested()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            isAdvertising = false
            standState = "Реклама не запущена: \(error.localizedDescription)"
            appendLog("Ошибка запуска рекламы")
        } else {
            isAdvertising = true
            standState = "Стенд виден по Bluetooth"
            appendLog("Начата реклама тестового сервиса")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        appendLog("Клиент подписался на тестовые уведомления")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        appendLog("Клиент отключил тестовые уведомления")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == Self.testCharacteristicID else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }
        if request.offset > testValue.count {
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }
        request.value = testValue.subdata(in: request.offset..<testValue.count)
        peripheral.respond(to: request, withResult: .success)
        appendLog("Клиент прочитал тестовое значение")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == Self.testCharacteristicID, let value = request.value else {
                peripheral.respond(to: request, withResult: .attributeNotFound)
                continue
            }
            testValue = value
            testValueText = String(data: value, encoding: .utf8).map { String($0.prefix(180)) } ?? "Двоичные данные (\(value.count) байт)"
            testCharacteristic?.value = value
            peripheral.respond(to: request, withResult: .success)
            appendLog("Клиент записал тестовое значение (\(value.count) байт)")
            if let testCharacteristic {
                peripheral.updateValue(value, for: testCharacteristic, onSubscribedCentrals: nil)
            }
        }
    }
}
