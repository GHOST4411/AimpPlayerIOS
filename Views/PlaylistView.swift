import SwiftUI

/// Vista de la lista de reproducción y cola actual estilo AIMP
struct PlaylistView: View {
    @ObservedObject var audioService: AudioEngineService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AimpTheme.background.ignoresSafeArea()
                
                if audioService.playlist.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(AimpTheme.textMuted)
                        Text("La cola de reproducción está vacía")
                            .font(.headline)
                            .foregroundColor(AimpTheme.textSecondary)
                        Text("Añade canciones desde el explorador de carpetas.")
                            .font(.caption)
                            .foregroundColor(AimpTheme.textMuted)
                    }
                } else {
                    List {
                        ForEach(Array(audioService.playlist.enumerated()), id: \.element.id) { index, track in
                            let isCurrent = (index == audioService.currentIndex)
                            
                            Button(action: {
                                audioService.playTrack(at: index)
                            }) {
                                HStack(spacing: 12) {
                                    // Índice o indicador de reproducción
                                    if isCurrent && audioService.isPlaying {
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(AimpTheme.primary)
                                            .frame(width: 24)
                                    } else {
                                        Text(String(format: "%02d", index + 1))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(isCurrent ? AimpTheme.primary : AimpTheme.textMuted)
                                            .frame(width: 24)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(track.title)
                                            .font(.system(size: 14, weight: isCurrent ? .bold : .medium))
                                            .foregroundColor(isCurrent ? AimpTheme.primary : AimpTheme.textPrimary)
                                            .lineLimit(1)
                                        
                                        HStack(spacing: 8) {
                                            Text(track.artist)
                                                .font(.system(size: 12))
                                                .foregroundColor(AimpTheme.textSecondary)
                                                .lineLimit(1)
                                            
                                            Text("•")
                                                .font(.system(size: 10))
                                                .foregroundColor(AimpTheme.textMuted)
                                            
                                            Text(track.formatBadge)
                                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                .foregroundColor(AimpTheme.primaryLight)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Duración de la pista
                                    Text(formatTime(track.duration))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(AimpTheme.textMuted)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(isCurrent ? AimpTheme.surface : AimpTheme.background)
                        }
                        .onDelete(perform: deleteTracks)
                        .onMove(perform: moveTracks)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Lista de Reproducción")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !audioService.playlist.isEmpty {
                        EditButton()
                            .foregroundColor(AimpTheme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AimpTheme.primary)
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
    
    private func deleteTracks(at offsets: IndexSet) {
        audioService.playlist.remove(atOffsets: offsets)
    }
    
    private func moveTracks(from source: IndexSet, to destination: Int) {
        audioService.playlist.move(fromOffsets: source, toOffset: destination)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
