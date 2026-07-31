import Foundation
import IOKit.hid

final class LogitechDeviceMonitor {
    struct Snapshot {
        let connectedPointerCount: Int
        let names: [String]
    }

    var onChange: ((Snapshot) -> Void)?
    var onPointerInput: (() -> Void)?

    private let manager: IOHIDManager
    private var pointerDevices = Set<UInt64>()

    init() {
        manager = IOHIDManagerCreate(
            kCFAllocatorDefault,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )

        let mouseMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x046D,
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]
        let pointerMatch: [String: Any] = [
            kIOHIDVendorIDKey as String: 0x046D,
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Pointer
        ]

        IOHIDManagerSetDeviceMatchingMultiple(
            manager,
            [mouseMatch, pointerMatch] as CFArray
        )
    }

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(
            manager,
            { context, _, _, device in
                guard let context else { return }
                let monitor = Unmanaged<LogitechDeviceMonitor>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                monitor.deviceAdded(device)
            },
            context
        )

        IOHIDManagerRegisterDeviceRemovalCallback(
            manager,
            { context, _, _, device in
                guard let context else { return }
                let monitor = Unmanaged<LogitechDeviceMonitor>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                monitor.deviceRemoved(device)
            },
            context
        )

        IOHIDManagerRegisterInputValueCallback(
            manager,
            { context, _, _, value in
                guard let context else { return }
                let monitor = Unmanaged<LogitechDeviceMonitor>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                monitor.received(value)
            },
            context
        )

        IOHIDManagerScheduleWithRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        publishSnapshot()
    }

    func stop() {
        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    private func deviceAdded(_ device: IOHIDDevice) {
        pointerDevices.insert(registryID(for: device))
        publishSnapshot()
    }

    private func deviceRemoved(_ device: IOHIDDevice) {
        pointerDevices.remove(registryID(for: device))
        publishSnapshot()
    }

    private func received(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        let isPointerAxis = usagePage == kHIDPage_GenericDesktop
            && (usage == kHIDUsage_GD_X
                || usage == kHIDUsage_GD_Y
                || usage == kHIDUsage_GD_Wheel)
        let isButton = usagePage == kHIDPage_Button

        if isPointerAxis || isButton {
            onPointerInput?()
        }
    }

    private func registryID(for device: IOHIDDevice) -> UInt64 {
        var identifier: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(IOHIDDeviceGetService(device), &identifier)
        return identifier
    }

    private func publishSnapshot() {
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>
        else {
            onChange?(Snapshot(connectedPointerCount: 0, names: []))
            return
        }

        var ids = Set<UInt64>()
        let names = devices.map { device -> String in
            ids.insert(registryID(for: device))
            return (IOHIDDeviceGetProperty(
                device,
                kIOHIDProductKey as CFString
            ) as? String) ?? "Logitech Mouse"
        }
        pointerDevices = ids

        onChange?(
            Snapshot(
                connectedPointerCount: ids.count,
                names: Array(Set(names)).sorted()
            )
        )
    }
}
