//
//  DocumentScannerView.swift
//  Daily Task
//
//  Created by Baldwin Kiel Malabanan on 2025-03-10.
//

import SwiftUI
import VisionKit
import Vision

struct DocumentScannerView: UIViewControllerRepresentable {
    /// Completion handler returns an array of recognized text strings (e.g., one per line or block)
    var completion: ([String]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerVC = VNDocumentCameraViewController()
        scannerVC.delegate = context.coordinator
        return scannerVC
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var completion: ([String]) -> Void
        
        init(completion: @escaping ([String]) -> Void) {
            self.completion = completion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedTexts: [String] = []
            
            // Create a text recognition request
            let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                for observation in observations {
                    if let bestCandidate = observation.topCandidates(1).first {
                        scannedTexts.append(bestCandidate.string)
                    }
                }
            }
            recognizeTextRequest.recognitionLevel = .accurate
            
            // Process each page in the scan
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let cgImage = image.cgImage {
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    do {
                        try requestHandler.perform([recognizeTextRequest])
                    } catch {
                        print("Error during text recognition: \(error)")
                    }
                }
            }
            
            // Dismiss the scanner and return the recognized text
            controller.dismiss(animated: true) {
                self.completion(scannedTexts)
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            controller.dismiss(animated: true)
            print("Scanning failed: \(error)")
        }
    }
}
