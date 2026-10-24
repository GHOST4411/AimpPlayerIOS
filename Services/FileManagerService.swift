import Foundation
import SwiftUI

/// Servicio para navegar por carpetas y escanear archivos de audio en el almacenamiento local
final class FileManagerService: ObservableObject {
    @Published var currentFolderURL: URL
    @Published var items: [FileSystemItem] = []
    
    // Extensiones compatibles con el motor nativo de iOS (incluye formatos Dolby Atmos y multicanal)
    static let supportedExtensions: Set<String> = ["mp3", "flac", "m4a", "wav", "aac", "alac", "aif", "aiff", "ec3", "eac3", "mp4"]
    
    struct FileSystemItem: Identifiable, Equatable {
        let id = UUID()
        let url: URL
        let name: String
        let isDirectory: Bool
        let size: Int64
    }
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.currentFolderURL = docs
        loadCurrentFolder()
    }
    
    func navigate(to folder: URL) {
        currentFolderURL = folder
        loadCurrentFolder()
    }
    
    func navigateUp() {
        let parent = currentFolderURL.deletingLastPathComponent()
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // No subir más allá del directorio Documentos
        if currentFolderURL.path != docs.path {
            currentFolderURL = parent
            loadCurrentFolder()
        }
    }
    
    func loadCurrentFolder() {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: currentFolderURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            var result: [FileSystemItem] = []
            
            for url in urls {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                let isDir = resourceValues.isDirectory ?? false
                let size = Int64(resourceValues.fileSize ?? 0)
                
                if isDir {
                    result.append(FileSystemItem(url: url, name: url.lastPathComponent, isDirectory: true, size: 0))
                } else if Self.supportedExtensions.contains(url.pathExtension.lowercased()) {
                    result.append(FileSystemItem(url: url, name: url.lastPathComponent, isDirectory: false, size: size))
                }
            }
            
            // Ordenar: primero carpetas, luego archivos alfabéticamente
            self.items = result.sorted {
                if $0.isDirectory != $1.isDirectory {
                    return $0.isDirectory && !$1.isDirectory
                }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        } catch {
            print("Error leyendo carpeta \(currentFolderURL): \(error)")
            self.items = []
        }
    }
    
    /// Escanea recursivamente todos los archivos de audio en la carpeta actual
    func scanAudioFiles(in folderURL: URL) async -> [AudioTrack] {
        var tracks: [AudioTrack] = []
        let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if Self.supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                let track = await AudioTrack.from(url: fileURL)
                tracks.append(track)
            }
        }
        return tracks
    }
}
