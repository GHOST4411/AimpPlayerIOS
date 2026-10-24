import SwiftUI

/// Pantalla principal de reproducción fiel a la interfaz y manejo de AIMP Móvil
struct MainPlayerView: View {
    @ObservedObject var audioService: AudioEngineService
    @ObservedObject var fileManagerService: FileManagerService
    
    @State private var showingEqualizer = false
    @State private var showingPlaylist = false
    @State private var showingFolders = false
    @State private var isDraggingSlider = false
    @State private var dragSliderValue: Double = 0
    
    var body: some View {
        ZStack {
            AimpTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Barra Superior de Herramientas AIMP
                HStack(spacing: 22) {
                    // Botón Explorador de Carpetas
                    Button(action: { showingFolders = true }) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 19))
                            .foregroundColor(AimpTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Indicador central o título de marca AIMP
                    Text("AIMP")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(AimpTheme.primary)
                        .tracking(3)
                    
                    Spacer()
                    
                    // Botón Ecualizador (EQ)
                    Button(action: { showingEqualizer = true }) {
                        HStack(spacing: 3) {
                            Image(systemName: "slider.vertical.3")
                                .font(.system(size: 18))
                            if audioService.isEqEnabled {
                                Circle()
                                    .fill(AimpTheme.primary)
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .foregroundColor(audioService.isEqEnabled ? AimpTheme.primary : AimpTheme.textSecondary)
                    }
                    
                    // Botón Lista de Reproducción
                    Button(action: { showingPlaylist = true }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 19))
                            .foregroundColor(AimpTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                Spacer()
                
                // MARK: - Carátula del Álbum estilo AIMP
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AimpTheme.cardBackground)
                        .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 8)
                    
                    if let track = audioService.currentTrack, let artwork = track.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        // Icono clásico de vinilo / nota musical cuando no hay carátula
                        VStack(spacing: 12) {
                            Image(systemName: "opticaldisc.fill")
                                .font(.system(size: 90))
                                .foregroundColor(AimpTheme.primary.opacity(0.8))
                            Text("AIMP AUDIO")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(AimpTheme.textMuted)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 36)
                
                Spacer()
                
                // MARK: - Información de la Pista (Título, Artista, Formato)
                VStack(spacing: 6) {
                    // Badge digital de Formato (ej: "DOLBY ATMOS", "FLAC 5.1", "MP3")
                    if let track = audioService.currentTrack {
                        Text(track.formatBadge)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(track.isDolbyAtmos ? Color(hex: "FFD700") : AimpTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AimpTheme.surface)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(track.isDolbyAtmos ? Color(hex: "FFD700").opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    }
                    
                    // Título de la Canción
                    Text(audioService.currentTrack?.title ?? "Sin Pista Seleccionada")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AimpTheme.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 30)
                    
                    // Artista y Álbum
                    Text(audioService.currentTrack?.artist ?? "Toca el icono de carpeta para cargar música")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AimpTheme.textSecondary)
                        .lineLimit(1)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 20)
                
                // MARK: - Barra de Progreso y Tiempo (Scrubber)
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { isDraggingSlider ? dragSliderValue : audioService.currentTime },
                            set: { newValue in
                                dragSliderValue = newValue
                            }
                        ),
                        in: 0...max(audioService.duration, 0.001),
                        onEditingChanged: { editing in
                            isDraggingSlider = editing
                            if !editing {
                                audioService.seek(to: dragSliderValue)
                            }
                        }
                    )
                    .accentColor(AimpTheme.primary)
                    
                    HStack {
                        Text(formatTime(isDraggingSlider ? dragSliderValue : audioService.currentTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AimpTheme.textSecondary)
                        
                        Spacer()
                        
                        let remaining = max(0, audioService.duration - (isDraggingSlider ? dragSliderValue : audioService.currentTime))
                        Text("-\(formatTime(remaining))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(AimpTheme.textMuted)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 15)
                
                // MARK: - Fila de Controles de Reproducción
                HStack(spacing: 28) {
                    // Modo Aleatorio (Shuffle)
                    Button(action: { audioService.isShuffle.toggle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 18))
                            .foregroundColor(audioService.isShuffle ? AimpTheme.primary : AimpTheme.textMuted)
                    }
                    
                    // Canción Anterior
                    Button(action: { audioService.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AimpTheme.textPrimary)
                    }
                    
                    // Botón Principal Play / Pause en Círculo Naranja AIMP
                    Button(action: { audioService.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(AimpTheme.primary)
                                .frame(width: 68, height: 68)
                                .shadow(color: AimpTheme.primary.opacity(0.35), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: audioService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: audioService.isPlaying ? 0 : 2)
                        }
                    }
                    
                    // Canción Siguiente
                    Button(action: { audioService.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AimpTheme.textPrimary)
                    }
                    
                    // Repetición (Off -> All -> One)
                    Button(action: {
                        switch audioService.repeatMode {
                        case .off: audioService.repeatMode = .all
                        case .all: audioService.repeatMode = .one
                        case .one: audioService.repeatMode = .off
                        }
                    }) {
                        Image(systemName: audioService.repeatMode.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(audioService.repeatMode != .off ? AimpTheme.primary : AimpTheme.textMuted)
                    }
                }
                .padding(.bottom, 30)
                
                // MARK: - Barra Inferior de Estado
                HStack {
                    if !audioService.playlist.isEmpty {
                        Text("\(audioService.currentIndex + 1) / \(audioService.playlist.count)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(AimpTheme.textMuted)
                    }
                    
                    Spacer()
                    
                    Text(audioService.isSpatialAudioActive ? "AUDIO ESPACIAL / ATMOS" : (audioService.isEqEnabled ? "DSP: ACTIVO" : "DSP: OFF"))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(audioService.isSpatialAudioActive ? Color(hex: "FFD700") : (audioService.isEqEnabled ? AimpTheme.primaryLight : AimpTheme.textMuted))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
            }
        }
        // Hojas modales para Carpetas, Ecualizador y Lista
        .sheet(isPresented: $showingFolders) {
            FolderBrowserView(fileManagerService: fileManagerService, audioService: audioService)
        }
        .sheet(isPresented: $showingEqualizer) {
            EqualizerView(audioService: audioService)
        }
        .sheet(isPresented: $showingPlaylist) {
            PlaylistView(audioService: audioService)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
