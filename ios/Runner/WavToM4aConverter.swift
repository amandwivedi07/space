import AVFoundation
import Flutter
import UIKit

/// Converts the WAV files from stt_record into M4A, which production /media accepts.
final class WavToM4aConverter: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "space/audio_convert",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(WavToM4aConverter(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "wavToM4a" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let args = call.arguments as? [String: String],
          let src = args["src"],
          let dest = args["dest"] else {
      result(FlutterError(code: "bad_args", message: "src and dest required", details: nil))
      return
    }
    convert(src: src, dest: dest, result: result)
  }

  private func convert(src: String, dest: String, result: @escaping FlutterResult) {
    let srcURL = URL(fileURLWithPath: src)
    let destURL = URL(fileURLWithPath: dest)
    try? FileManager.default.removeItem(at: destURL)

    let asset = AVURLAsset(url: srcURL)
    guard let session = AVAssetExportSession(
      asset: asset,
      presetName: AVAssetExportPresetAppleM4A
    ) else {
      result(FlutterError(code: "export", message: "Could not create export session", details: nil))
      return
    }
    session.outputURL = destURL
    session.outputFileType = .m4a
    session.exportAsynchronously {
      DispatchQueue.main.async {
        if session.status == .completed {
          result(dest)
        } else {
          result(FlutterError(
            code: "export",
            message: session.error?.localizedDescription ?? "export failed",
            details: nil
          ))
        }
      }
    }
  }
}
