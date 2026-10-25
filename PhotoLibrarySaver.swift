import Foundation
import Photos
import UIKit

enum PhotoLibrarySaver {
    static func saveImage(from remoteURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        URLSession.shared.dataTask(with: remoteURL) { data, response, error in
            if let error {
                finish(.failure(error), completion: completion)
                return
            }

            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let data,
                  let image = UIImage(data: data) else {
                finish(.failure(PhotoSaveError.invalidImage), completion: completion)
                return
            }

            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    finish(.failure(PhotoSaveError.permissionDenied), completion: completion)
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { saved, error in
                    if saved {
                        finish(.success(()), completion: completion)
                    } else {
                        finish(.failure(error ?? PhotoSaveError.writeFailed), completion: completion)
                    }
                }
            }
        }.resume()
    }

    static func saveVideo(from remoteURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        URLSession.shared.downloadTask(with: remoteURL) { localURL, response, error in
            if let error {
                finish(.failure(error), completion: completion)
                return
            }

            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let localURL else {
                finish(.failure(PhotoSaveError.invalidVideo), completion: completion)
                return
            }

            let fileExtension = remoteURL.pathExtension.isEmpty ? "mov" : remoteURL.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)

            do {
                try FileManager.default.copyItem(at: localURL, to: destination)
            } catch {
                finish(.failure(error), completion: completion)
                return
            }

            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    try? FileManager.default.removeItem(at: destination)
                    finish(.failure(PhotoSaveError.permissionDenied), completion: completion)
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destination)
                } completionHandler: { saved, error in
                    try? FileManager.default.removeItem(at: destination)
                    if saved {
                        finish(.success(()), completion: completion)
                    } else {
                        finish(.failure(error ?? PhotoSaveError.writeFailed), completion: completion)
                    }
                }
            }
        }.resume()
    }

    private static func finish(
        _ result: Result<Void, Error>,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}

private enum PhotoSaveError: LocalizedError {
    case invalidImage
    case invalidVideo
    case permissionDenied
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Η εικόνα δεν μπόρεσε να ληφθεί."
        case .invalidVideo: "Το βίντεο δεν μπόρεσε να ληφθεί."
        case .permissionDenied: "Δεν επιτράπηκε η αποθήκευση στη Συλλογή Φωτογραφιών."
        case .writeFailed: "Η εικόνα δεν μπόρεσε να αποθηκευτεί."
        }
    }
}
