import Cwlroots
import Logging

fileprivate let expectedFilePath = "SwiftWLR/Util/Logger.swift"
fileprivate let basePath = #file.dropLast(expectedFilePath.count)
fileprivate let basePathCount = basePath.count

public struct WLRLogHandler: LogHandler {
    public var logLevel: Logger.Level = .info
    public var metadata = Logger.Metadata()

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }

    public init(label: String) {
        wlr_log_init(wlrLogImportance(of: logLevel), nil)
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        file: String,
        function: String,
        line: UInt
    ) {
        let mergedMetadata = metadata?.isEmpty ?? true
            ? self.metadata
            : self.metadata.merging(
                metadata!, uniquingKeysWith: { _, new in new })
        
        let formattedMetadata = format(mergedMetadata)
        let wlrLevel = wlrLogImportance(of: level)

        let formattedFile = file.dropFirst(basePathCount)

        let message =
            "[\(formattedFile):\(line)] " +
            "\(formattedMetadata.map { "{\($0)}" } ?? "") " +
            "\(message)"

        withVaList([]) { vaList in
            _wlr_vlog(wlrLevel, message, vaList)
        }
    }

    private func wlrLogImportance(
        of level: Logger.Level
    ) -> wlr_log_importance {
        switch level {
            case .trace, .debug:
                return WLR_DEBUG
            case .info, .notice:
                return WLR_INFO
            case .warning, .error, .critical:
                return WLR_ERROR
        }
    }

    private func format(_ metadata: Logger.Metadata) -> String? {
        return !metadata.isEmpty ?
            metadata.map { "\($0)=\($1)" }.joined(separator: " ") : nil
    }
}
