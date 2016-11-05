//
//  StarPrinting.swift
//  StarPrinting
//
//  Created by Dave Carlton on 11/4/16.
//  Copyright © 2016 OpenTable. All rights reserved.
//

import Foundation
import ExternalAccessory

// BluetoothPort.h
enum Emulation : Int {
    case starLineMode
    case escposMode
}

class BluetoothPort: NSObject {
    var portName_: String?
    var portSettings_: String?
    var timeout_: UInt32?
    var selectedAccessory: EAAccessory!
    var session: EASession!
    var writeData: Data!
    var readData: Data!
    var emulation = Emulation.starLineMode
    
    private(set) var isConnected = false
    var endCheckedBlockTimeoutMillis: UInt32?
    
//    class func match(_ portName: String, portSettings: String) -> Bool {
//    }
//    
//    init(portName: String, portSettings: String, timeout: UInt32) {
//    }
//    
//    deinit {
//    }
//    
//    func open() -> Bool {
//    }
//    
//    func write(_ data: Data) -> Int {
//    }
//    
//    func write(withRetry data: Data) -> Int {
//    }
//    
//    func read(_ bytesToRead: Int) -> Data {
//    }
//    
//    func getParsedStatus(_ starPrinterStatus: StarPrinterStatus, level: UInt32) -> Bool {
//    }
//    
//    func getOnlineStatus(_ onlineStatus: Bool) -> Bool {
//    }
//    
//    func beginCheckedBlock(_ starPrinterStatus: StarPrinterStatus, level: UInt32) -> Bool {
//    }
//    
//    func endCheckedBlock(_ starPrinterStatus: StarPrinterStatus, level: UInt32) -> Bool {
//    }
//    
//    func isdConnected() -> Bool {
//    }
//    
//    func close() {
//    }
//    
//    func disconnect() -> Bool {
//    }
}

//
//  NSObject+Printable.h
//  StarPrinting
//
//  Created by Matthew Newberry on 4/11/13.
//  OpenTable
//
import Foundation

//protocol Printable {
//    func printedFormat() -> PrintData
//}
//
//extension NSObject: Printable {
//    internal func printedFormat() -> PrintData {
////        code
//    }
//
//
//    func print_p() {
//        self.print_p(Printer.connected())
//    }
//
//    func print_p(_ printer: Printer) {
//        printer.print_p(self.performSelector(#selector(self.printedFormat)))
//    }
//}

enum PrinterBarcodeType : Int {
    case upce
    case upca
    case ean8
    case ean13
    case code39
    case itf
    case code128
    case code93
    case nw7
}
let kPrinterCMD_Tab = "\u{9}"
let kPrinterCMD_Newline = "\u{a}"
// Alignment
let kPrinterCMD_AlignCenter         = "\u{1b}\u{1d}\u{61}\u{01}"
let kPrinterCMD_AlignLeft           = "\u{1b}\u{1d}\u{61}\u{00}"
let kPrinterCMD_AlignRight          = "\u{1b}\u{1d}\u{61}\u{02}"
let kPrinterCMD_HorizTab            = "\u{1b}\u{44}\u{02}\u{10}\u{22}\u{00}"


// Text Formatting
let kPrinterCMD_StartBold           = "\u{1b}\u{45}"
let kPrinterCMD_EndBold             = "\u{1b}\u{46}"
let kPrinterCMD_StartUnderline      = "\u{1b}\u{2d}\u{01}"
let kPrinterCMD_EndUnderline        = "\u{1b}\u{2d}\u{00}"
let kPrinterCMD_StartUpperline      = "\u{1b}\u{5f}\u{01}"
let kPrinterCMD_EndUpperline        = "\u{1b}\u{5f}\u{00}"

let kPrinterCMD_StartDoubleHW       = "\u{1b}\u{69}\u{01}\u{01}"
let kPrinterCMD_EndDoubleHW         = "\u{1b}\u{69}\u{00}\u{00}"

let kPrinterCMD_StartInvertColor    = "\u{1b}\u{34}"
let kPrinterCMD_EndInvertColor      = "\u{1b}\u{35}"


// Cutting
let kPrinterCMD_CutFull             = "\u{1b}\u{64}\u{02}"
let kPrinterCMD_CutPartial          = "\u{1b}\u{64}\u{03}"


// Barcode
let kPrinterCMD_StartBarcode        = "\u{1b}\u{62}\u{06}\u{02}\u{02}\u{20}12ab34cd56\u{1e}\r\n"
let kPrinterCMD_EndBarcode          = "\u{1e}"

class PrintData {
    var dictionary = [AnyHashable: Any]()
    var filePath = ""
    
    func `init`(dictionary: [AnyHashable: Any], atFilePath filePath: String) {
        
        self.dictionary = dictionary
        self.filePath = filePath
        
    }
}

//  Printer.m
let kConnectedPrinterKey = "ConnectedPrinterKey"

enum PrinterStatus : Int {
    case disconnected
    case connecting
    case connected
    case lowPaper
    case coverOpen
    case outOfPaper
    case connectionError
    case lostConnectionError
    case printError
    case unknownError
    case incompatible
    case noStatus
}

typealias PrinterResultBlock = (_ success: Bool) -> Void
typealias PrinterSearchBlock = (_ found: [Any]) -> Void
protocol PrinterDelegate: class {
    func printer(_ printer: Printer, didChange status: PrinterStatus)
}

class Printer: NSObject {
    weak var delegate: PrinterDelegate?
    var port: SMPort!
    var modelName: String?
    var portName: String?
    var macAddress: String?
    var friendlyName: String?
    var name: String {
        get {
            if friendlyName != nil {
                return friendlyName!
            } else {
                return modelName!
            }
        }
    }
    private(set) var isHasError = false
    private(set) var isOffline = false
    private(set) var isOnlineWithError = false
    private(set) var isCompatible = false
    var heartbeatTimer: Timer!
    var previousOnlineStatus: PrinterStatus!
    //    var status = PrinterStatus(rawValue: 0)
    var status: PrinterStatus {
        get {
            // TODO: add getter implementation
            return self.status
        }
        set(status) {
            if self.status != status {
                if !self.isOffline && self.status != .connecting {
                    self.previousOnlineStatus = self.status
                }
                self.status = status
                if delegate != nil {
                    DispatchQueue.main.async(execute: {() -> Void in
                        self.delegate!.printer(self, didChange: status)
                    })
                }
            }
        }
    }
//    var isReadyToPrint: Bool {
//        var result = self.status.connected | self.status.lowPaper
//        return result
//    }
//    var isHasError: Bool {
//        return self.status != .connected && self.status != .connecting && self.status != .disconnected
//    }
//    var isOffline: Bool {
//        return self.status == .connectionError | self.status == .lostConnectionError | self.status == .unknownError
//    }
//    var isOnlineWithError: Bool {
//        return self.isHasError && !self.isOffline && self.status != .printError
//    }
//    var isCompatible: Bool {
//        var compatible = true
//        var p = self.modelName.components(separatedBy: " (")
//        if p.count == 2 {
//            var modelNumber = p[0]
//            var result = (modelNumber as NSString).rangeOf("TSP1")
//            if result.location == NSNotFound {
//                compatible = false
//            }
//        }
//        return compatible
//    }
//    
//    class func fromPort(_ port: PortInfo) -> Printer {
//        var printer = Printer()
//        printer.modelName = port.modelName
//        printer.portName = port.portName
//        printer.macAddress = port.macAddress
//        printer.initialize()
//        return printer
//    }
//    
    class func connected() -> Printer {
        // if already connected, return instance
        var myStat = self.status
        if .connected {
            return connectedPrinter
        }
        // try to get previously used printer
        var defaults = UserDefaults.standard
        if defaults.object(forKey: kConnectedPrinterKey)! {
            var encoded = defaults.object(forKey: kConnectedPrinterKey)!
            connectedPrinter = NSKeyedUnarchiver.unarchiveObject(withData: encoded)!
            return connectedPrinter
        }
        // signify no connected printer
        return nil
    }
    
    class func search(_ printer_search: PrinterSearchBlock) {
        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
            // look for my class of printers
            var foundPrinters = SMPort.searchPrinter()
            // setup array of possible printers
            var printers = [Any]() /* capacity: foundPrinters.count */
            // lookup last connected printer, if any (non-nil)
            var lastKnownPrinter = Printer.connected()
            // run thru the found printer ports
            for p: PortInfo in foundPrinters {
                var printer = Printer.fromPort(p)
                // TODO DAC-2016-10-31 This makes no sense, if we are running thru found printers why is the last
                // known used, if it is not online (not in the found list) we should not be using it
                if (printer.macAddress == lastKnownPrinter.macAddress) {
                    printers.append(lastKnownPrinter)
                }
                else {
                    printers.append(printer)
                }
            }
            // TODO Is this supposed to be recursive?
            DispatchQueue.main.async(execute: {() -> Void in
                printer_search(printers)
            })
        })
    }
//
//    class func portClass() -> AnyClass {
//        return SMPort.self
//    }
//    
//    convenience init(for status: PrinterStatus) {
//        switch status {
//        case .connected:
//            return NSLocalizedString("Connected", comment: "Connected")
//        case .connecting:
//            return NSLocalizedString("Connecting", comment: "Connecting")
//        case .disconnected:
//            return NSLocalizedString("Disconnected", comment: "Disconnected")
//        case .lowPaper:
//            return NSLocalizedString("Low Paper", comment: "Low Paper")
//        case .coverOpen:
//            return NSLocalizedString("Cover Open", comment: "Cover Open")
//        case .outOfPaper:
//            return NSLocalizedString("Out of Paper", comment: "Out of Paper")
//        case .connectionError:
//            return NSLocalizedString("Connection Error", comment: "Connection Error")
//        case .lostConnectionError:
//            return NSLocalizedString("Lost Connection", comment: "Lost Connection")
//        case .printError:
//            return NSLocalizedString("Print Error", comment: "Print Error")
//        case .incompatible:
//            return NSLocalizedString("Incompatible Printer", comment: "Incompatible Printer")
//        default:
//            return NSLocalizedString("Unknown Error", comment: "Unknown Error")
//        }
//        
//    }
//    
//    func connect(_ result: PrinterResultBlock) {
//        self.log("Attempting to connect")
//        connectedPrinter = self
//        self.status = .connecting
//        var connectJob = {(_ portConnected: Bool) -> Void in
//            if !portConnected {
//                self.jobFailedRetry(true)
//                self.log("Failed to connect")
//            }
//            else {
//                self.establishConnection()
//                self.jobWasSuccessful()
//                self.log("Successfully connected")
//            }
//            if result {
//                result(portConnected)
//            }
//        }
//        objc_setAssociatedObject(connectJob, ConnectJobTag, 1, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        self.addJob(connectJob)
//    }
//    
//    override func disconnect() {
//        self.status = .disconnected
//        connectedPrinter = nil
//        var defaults = UserDefaults.standard
//        defaults.removeObject(forKey: kConnectedPrinterKey)
//        self.stopHeartbeat()
//    }
//    
//    func printTest() {
//        //    AppDelegate *_delegate = [[UIApplication sharedApplication] delegate];
//        if !Printer.connected() {
//            return
//        }
//        var filePath = Bundle.main.path(forResource: "receipt_short", ofType: "xml")!
//        var dictionary = ["{{printerStatus}}": Printer.init(for: Printer.connected().status), "{{printerName}}": Printer.connected().name]
//        //    PrintData *printData = [[PrintData alloc] initWithDictionary:nil atFilePath:filePath];
//        var printData = PrintData.init(dictionary: dictionary, atFilePath: filePath)
//        self.print(printData)
//        //    [_delegate testPrint: @"Hey there"];
//    }
//    // Should only be called by unit tests
//    var jobs = [Any]()
//    var queue: OperationQueue!
//    
//    func startHeartbeat() {
//        if !self.heartbeatTimer {
//            DispatchQueue.main.async(execute: {() -> Void in
//                self.heartbeatTimer = Timer.scheduledTimer(timeInterval: kHeartbeatInterval, target: self, selector: #selector(self.heartbeat), userInfo: nil, repeats: true)
//            })
//        }
//    }
//    
//    func stopHeartbeat() {
//        self.heartbeatTimer.invalidate()
//        self.heartbeatTimer = nil
//    }
//    // This should usually not be called directly, rather objects should
//    // conform to the `Printable` protocol
//    
//    func print(_ printData: PrintData) {
//        self.log("Queued a print job")
//        var printJob = {(_ portConnected: Bool) -> Void in
//            var error = !portConnected || !self.isReadyToPrint
//            if !error {
//                var dictionary = printData()
//                var filePath = printData.filePath
//                var contents = FileManager.default.contents(at: filePath)!
//                var s = String(contents, encoding: String.Encoding.utf8)
//                dictionary.enumerateKeysAndObjects(usingBlock: {(_ key: String, _ value: String, _ stop: Bool) -> Void in
//                    s = s.replacingOccurrences(of: key, with: value)
//                })
//                var parser = PrintParser()
//                var data = parser.parse(s.data(using: String.Encoding.utf8))
//                if !self.printChit(data) {
//                    self.status = .printError
//                    error = true
//                }
//            }
//            if error {
//                self.log("Print job unsuccessful")
//                self.jobFailedRetry(true)
//            }
//            else {
//                self.log("Print job successfully finished")
//                self.jobWasSuccessful()
//            }
//        }
//        objc_setAssociatedObject(printJob, PrintJobTag, 1, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        self.addJob(printJob)
//    }
//    
//    // MARK: - Class Methods
//    // MARK: - Initialization & Coding
//    
//    override func initialize() {
//        self.jobs = [Any]()
//        self.queue = OperationQueue()
//        self.queue.maxConcurrentOperationCount = 1
//        self.previousOnlineStatus = .disconnected
//        self.performCompatibilityCheck()
//    }
//    
//    override func encode(withCoder encoder: NSCoder) {
//        encoder.encodeObject(self.modelName, forKey: "modelName")
//        encoder.encodeObject(self.portName, forKey: "portName")
//        encoder.encodeObject(self.macAddress, forKey: "macAddress")
//        encoder.encodeObject(self.friendlyName, forKey: "friendlyName")
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        super.init()
//        
//        self.modelName = aDecoder.decodeObject(forKey: "modelName")!
//        self.portName = aDecoder.decodeObject(forKey: "portName")!
//        self.macAddress = aDecoder.decodeObject(forKey: "macAddress")!
//        self.friendlyName = aDecoder.decodeObject(forKey: "friendlyName")!
//        self.initialize()
//        
//    }
//    // MARK: - Port Handling
//    
    func openPort() -> Bool {
        var error = false
        do {
            self.port = SMPort.getPort(self.portName, "", 3000)
            if !(self.port != nil) {
                error = true
            }
        }   catch let _ {
            self.status = .unknownError
            error = true
        }
        return !error
    }
    
    func releasePort() {
        if (self.port != nil) {
            SMPort.release(self.port)
            self.port = nil
        }
    }

// MARK: - Job Handling
//    
//    func addJob(_ job: PrinterJobBlock) {
//        if self.isHeartbeatJob(job) && self.jobs.count > 0 {
//            return
//        }
//        self.jobs.append(job)
//        self.printJobCount("Adding job")
//        if self.jobs.count == 1 || self.queue.operationCount == 0 {
//            self.runNext()
//        }
//    }
//    
//    func runNext() {
//        var block = {() -> Void in
//            if self.jobs.count == 0 {
//                return
//            }
//            var job = self.jobs[0]
//            var portConnected = false
//            for i in 0..<20 {
//                portConnected = self.openPort()
//                if portConnected {
//                    
//                }
//                self.log("Retrying to open port!")
//                usleep(1000 * 333)
//            }
//            if !portConnected {
//                // Printer is offline
//                if self.status != .unknownError {
//                    if self.isConnectJob(job) {
//                        self.status = .connectionError
//                    }
//                    else {
//                        self.status = .lostConnectionError
//                    }
//                }
//            }
//            else {
//                // Printer is online but might have an error
//                self.updateStatus()
//            }
//            job(portConnected)
//            self.releasePort()
//        }
//        //        self.queue.addOperation block
//    }
//    
//    func jobWasSuccessful() {
//        self.jobs.remove(at: 0)
//        self.printJobCount("SUCCESS, Removing job")
//        self.runNext()
//    }
//    
//    func jobFailedRetry(_ retry: Bool) {
//        if !retry {
//            self.jobs.remove(at: 0)
//            self.printJobCount("FAILURE, Removing job")
//        }
//        else {
//            var delayInSeconds: Double = kJobRetryInterval
//            var popTime = DispatchTime.now() + Double(Int64(delayInSeconds * Double(NSEC_PER_SEC)))
//            DispatchQueue.main.asyncAfter(deadline: popTime / Double(NSEC_PER_SEC), execute: {() -> Void in
//                if self.jobs.count == 0 {
//                    return
//                }
//                self.log("***** RETRYING JOB ******")
//                var job = self.jobs[0]
//                self.jobs.remove(at: 0)
//                self.jobs.append(job)
//                self.runNext()
//            })
//        }
//    }
//    // MARK: - Connection
//    
//    func establishConnection() {
//        if !self.isOnlineWithError {
//            self.status = .connected
//        }
//        var defaults = UserDefaults.standard
//        var encoded = NSKeyedArchiver.archivedData(withRootObject: self)
//        defaults.set(encoded, forKey: kConnectedPrinterKey)
//        defaults.synchronize()
//        self.startHeartbeat()
//    }
//    // MARK: - Printing
//    
//    func printChit(_ data: Data) -> Bool {
//        self.log("Printing")
//        var error = false
//        var completed = false
//        // Add cut manually
//        var printData = Data(data: data)
//        printData.append(kPrinterCMD_CutFull.data(using: String.Encoding.ascii))
//        var commandSize = printData.length
//        var dataToSentToPrinter: UInt8 = UInt8(malloc(commandSize))
//        printData.getBytes(dataToSentToPrinter)
//        repeat {
//            do {
//                var totalAmountWritten = 0
//                while totalAmountWritten < commandSize {
//                    var remaining = commandSize - totalAmountWritten
//                    var blockSize = (remaining > 1024) ? 1024 : remaining
//                    var amountWritten = self.port.writePort(dataToSentToPrinter, totalAmountWritten, blockSize)
//                    totalAmountWritten += amountWritten
//                }
//                if totalAmountWritten < commandSize {
//                    error = true
//                }
//            }             catch let exception {
//                self.log(exception.description)
//                error = true
//            }
//            completed = true
//            free(dataToSentToPrinter)
//            RunLoop.current.run(mode: NSDefaultRunLoopMode, before: Date(timeIntervalSinceNow: kHeartbeatInterval))
//        } while !completed
//        return !error
//    }
//    // MARK: - Heartbeat
//    
//    func heartbeat() {
//        var heartbeatJob = {(_ portConnected: Bool) -> Void in
//            self.jobWasSuccessful()
//            self.log("*** Heartbeat ***")
//        }
//        objc_setAssociatedObject(heartbeatJob, HeartbeatTag, 1, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        self.addJob(heartbeatJob)
//    }
//    // MARK: - Status
//    
//    func updateStatus() {
//        if !self.performCompatibilityCheck() {
//            return
//        }
//        var status = .noStatus
//        var printerStatus: StarPrinterStatus_2
//        self.port.getParsedStatus(printerStatus, 2)
//        if printerStatus.offline == SM_TRUE {
//            if printerStatus.coverOpen == SM_TRUE {
//                status = .coverOpen
//            }
//            else if printerStatus.receiptPaperEmpty == SM_TRUE {
//                status = .outOfPaper
//            }
//            else if printerStatus.receiptPaperNearEmptyInner == SM_TRUE || printerStatus.receiptPaperNearEmptyOuter == SM_TRUE {
//                status = .lowPaper
//            }
//        }
//        // CoverOpen, LowPaper, or OutOfPaper
//        if status != .noStatus {
//            self.status = status
//            return
//        }
//        // Printer did have error, but error is now resolved
//        if self.isHasError {
//            self.status = self.previousOnlineStatus
//        }
//    }
//    // MARK: - Properties
//    
//    func description() -> String {
//        var desc = "<Printer: \(self) { name:\(self.name) mac:\(self.macAddress) model:\(self.modelName) portName:\(self.portName) status:\(Printer.init(for: self.status))}>"
//        return desc
//    }
//    /*
//     Star TSP100 model printers are do not support line mode commands.
//     Until better raster mode support is enabled, we're notify that they're incompatible.
//     */
//    
//    func performCompatibilityCheck() -> Bool {
//        var compatible = self.isCompatible()
//        if !compatible {
//            self.status = .incompatible
//        }
//        return compatible
//    }
//    // MARK: - Helpers
//    
//    func log(_ message: String) {
//        if DEBUG_LOGGING {
//            print("\("\(DEBUG_PREFIX) \(self) -> \(message)")")
//        }
//    }
//    
//    func printJobCount(_ message: String) {
//        self.log("\(message) -> Job Count = \(self.jobs.count)")
//    }
//    
//    func isConnectJob(_ job: PrinterJobBlock) -> Bool {
//        var isConnectJob = objc_getAssociatedObject(job, PrintJobTag)
//        return CInt(isConnectJob) == 1
//    }
//    
//    func isPrintJob(_ job: PrinterJobBlock) -> Bool {
//        var isPrintJob = objc_getAssociatedObject(job, PrintJobTag)
//        return CInt(isPrintJob) == 1
//    }
//    
//    func isHeartbeatJob(_ job: PrinterJobBlock) -> Bool {
//        var isHeartbeatJob = objc_getAssociatedObject(job, HeartbeatTag)
//        return CInt(isHeartbeatJob) == 1
//    }
//    
//    var heartbeatTimer: Timer!
//    var previousOnlineStatus = PrinterStatus(rawValue: 0)
//    
//    func performCompatibilityCheck() -> Bool {
//    }
}

// Printer
//import StarIO
//import ObjectiveC
//let DEBUG_LOGGING = false
//let DEBUG_PREFIX = "Printer:"
//let kHeartbeatInterval = 5.0
//let kJobRetryInterval = 2.0
//let PORT_CLASS = self.init().portClass()
//typealias PrinterOperationBlock = () -> Void
//typealias PrinterJobBlock = (_ portConnected: Bool) -> Void
//var connectedPrinter: Printer!
//
//let PrintJobTag = "PrintJobTag"
//
//let HeartbeatTag = "HeartbeatTag"
//
//let ConnectJobTag = "ConnectJobTag"
