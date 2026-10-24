import SwiftUI
import UniformTypeIdentifiers

/// Explorador de archivos y carpetas locales estilo AIMP Móvil
struct FolderBrowserView: View {
    @ObservedObject var fileManagerService: FileManagerService
    @ObservedObject var audioService: AudioEngineService
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingDocumentPicker = false
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AimpTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Barra de ruta actual estilo terminal/AIMP
                    HStack {
                        Button(action: {
                            fileManagerService.navigateUp()
                        }) {
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AimpTheme.primary)
                        }
                        
                        Text(fileManagerService.currentFolderURL.lastPathComponent)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(AimpTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Botón: Reproducir toda la carpeta actual
                        Button(action: {
                            playEntireCurrentFolder()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 11))
                                Text("Reproducir Todo")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AimpTheme.primary)
                            .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(AimpTheme.surface)
                    
                    Divider().background(AimpTheme.divider)
                    
                    // Lista de Carpetas y Canciones
                    if fileManagerService.items.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "music.note.list")
                                .font(.system(size: 48))
                                .foregroundColor(AimpTheme.textMuted)
                            Text("No hay canciones en esta carpeta")
                                .font(.headline)
                                .foregroundColor(AimpTheme.textSecondary)
                            Text("Copia música a la carpeta de la app mediante la app 'Archivos' de iOS o usa el botón '+'")
                                .font(.caption)
                                .foregroundColor(AimpTheme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: { isShowingDocumentPicker = true }) {
                                Label("Importar archivos...", systemImage: "plus.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(AimpTheme.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(AimpTheme.surface)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(fileManagerService.items) { item in
                                if item.isDirectory {
                                    // Fila de Carpeta
                                    Button(action: {
                                        fileManagerService.navigate(to: item.url)
                                    }) {
                                        HStack(spacing: 14) {
                                            Image(systemName: "folder.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AimpTheme.primary)
                                            Text(item.name)
                                                .foregroundColor(AimpTheme.textPrimary)
                                                .font(.system(size: 15, weight: .medium))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(AimpTheme.textMuted)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowBackground(AimpTheme.background)
                                } else {
                                    // Fila de Archivo de Música
                                    Button(action: {
                                        playSingleFile(url: item.url)
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "music.note")
                                                .foregroundColor(AimpTheme.textSecondary)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .foregroundColor(AimpTheme.textPrimary)
                                                    .font(.system(size: 14))
                                                    .lineLimit(1)
                                                
                                                Text(item.url.pathExtension.uppercased())
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .foregroundColor(AimpTheme.primary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    .listRowBackground(AimpTheme.background)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Explorador de Carpetas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isShowingDocumentPicker = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AimpTheme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AimpTheme.primary)
                    .font(.system(size: 16, weight: .bold))
                }
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPicker { urls in
                    copyImportedFiles(urls: urls)
                }
            }
        }
    }
    
    private func playEntireCurrentFolder() {
        Task {
            let tracks = await fileManagerService.scanAudioFiles(in: fileManagerService.currentFolderURL)
            guard !tracks.isEmpty else { return }
            await MainActor.run {
                audioService.playlist = tracks
                audioService.playTrack(at: 0)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func playSingleFile(url: URL) {
        Task {
            let track = await AudioTrack.from(url: url)
            await MainActor.run {
                // Si la pista ya está en la lista de reproducción, ir a ella; si no, añadirla
                if let index = audioService.playlist.firstIndex(where: { $0.url == url }) {
                    audioService.playTrack(at: index)
                } else {
                    audioService.playlist.append(track)
                    audioService.playTrack(at: audioService.playlist.count - 1)
                }
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func copyImportedFiles(urls: [URL]) {
        let dest = fileManagerService.currentFolderURL
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let targetURL = dest.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: targetURL)
        }
        fileManagerService.loadCurrentFolder()
    }
}

/// Selector de documentos para importar música desde iCloud / Files
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio, UTType.folder], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}
