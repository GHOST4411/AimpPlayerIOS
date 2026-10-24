import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Motor de audio principal con soporte para Audio Estándar (10-band EQ) y Dolby Atmos / Audio Espacial
@MainActor
final class AudioEngineService: ObservableObject {
    // Estado observable
    @Published var currentTrack: AudioTrack?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playlist: [AudioTrack] = []
    @Published var currentIndex: Int = 0
    @Published var isShuffle: Bool = false
    @Published var repeatMode: RepeatMode = .all
    @Published var isSpatialAudioActive: Bool = false
    
    // Configuración del Ecualizador (10 bandas: -12dB a +12dB)
    @Published var isEqEnabled: Bool = true {
        didSet { eqUnit.bypass = !isEqEnabled }
    }
    @Published var preampGain: Float = 0.0 {
        didSet { updatePreamp() }
    }
    @Published var eqBands: [Float] = Array(repeating: 0.0, count: 10) {
        didSet { applyEqBands() }
    }
    
    enum RepeatMode {
        case off, all, one
        var iconName: String {
            switch self {
            case .off: return "repeat"
            case .all: return "repeat"
            case .one: return "repeat.1"
            }
        }
    }
    
    // Frecuencias fijas características de AIMP (10 bandas en Hz)
    static let frequencies: [Float] = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    static let bandLabels = ["31", "63", "125", "250", "500", "1K", "2K", "4K", "8K", "16K"]
    
    // Nodos de AVAudioEngine para pistas convencionales con EQ
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let eqUnit = AVAudioUnitEQ(numberOfBands: 10)
    private var audioFile: AVAudioFile?
    
    // AVPlayer dedicado para decodificación nativa por hardware de Dolby Atmos (E-AC-3 / Spatial Audio)
    private var avPlayer: AVPlayer?
    private var avPlayerTimeObserver: Any?
    
    // Timer para actualizar la barra de progreso
    private var progressTimer: AnyCancellable?
    private var currentFrameOffset: AVAudioFramePosition = 0
    private var sampleRate: Double = 44100
    
    init() {
        setupAudioSession()
        setupAudioEngine()
        setupRemoteCommandCenter()
        startTimer()
    }
    
    // MARK: - Configuración de Sesión con Soporte Dolby Atmos y Audio Espacial
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Configurar categoría para permitir reproducción multicanal y audio espacial nativo
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            
            // Solicitar número máximo de canales de salida (para sonido envolvente / Atmos)
            if session.maximumOutputNumberOfChannels > 2 {
                try session.setPreferredOutputNumberOfChannels(session.maximumOutputNumberOfChannels)
            }
            try session.setActive(true)
        } catch {
            print("Error activando AVAudioSession con soporte espacial: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(eqUnit)
        
        for (index, freq) in Self.frequencies.enumerated() {
            let band = eqUnit.bands[index]
            band.frequency = freq
            band.filterType = .parametric
            band.bandwidth = 1.0
            band.gain = 0
            band.bypass = false
        }
        
        audioEngine.connect(playerNode, to: eqUnit, format: nil)
        audioEngine.connect(eqUnit, to: audioEngine.mainMixerNode, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error iniciando AVAudioEngine: \(error)")
        }
    }
    
    // MARK: - Control de Reproducción (Híbrido: Atmos y Estándar)
    
    func playTrack(at index: Int) {
        guard playlist.indices.contains(index) else { return }
        currentIndex = index
        let track = playlist[index]
        currentTrack = track
        duration = track.duration
        currentTime = 0
        isSpatialAudioActive = track.isDolbyAtmos
        
        // Detener reproductores previos
        playerNode.stop()
        if let observer = avPlayerTimeObserver {
            avPlayer?.removeTimeObserver(observer)
            avPlayerTimeObserver = nil
        }
        avPlayer?.pause()
        avPlayer = nil
        
        if track.isDolbyAtmos {
            // Reproducción nativa con decodificación de objetos espaciales Dolby Atmos en AVPlayer
            playDolbyAtmosTrack(track: track)
        } else {
            // Reproducción en AVAudioEngine con ecualizador de 10 bandas
            playStandardTrack(track: track)
        }
        
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    private func playDolbyAtmosTrack(track: AudioTrack) {
        let playerItem = AVPlayerItem(url: track.url)
        // Permitir espacialización multicanal y objetos Atmos con seguimiento de cabeza
        playerItem.isAudioSpatializationAllowed = true
        
        let player = AVPlayer(playerItem: playerItem)
        self.avPlayer = player
        
        // Observador de tiempo de AVPlayer
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        avPlayerTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, self.isPlaying else { return }
            self.currentTime = CMTimeGetSeconds(time)
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handleTrackEnded()
        }
        
        player.play()
    }
    
    private func playStandardTrack(track: AudioTrack) {
        do {
            let file = try AVAudioFile(forReading: track.url)
            self.audioFile = file
            self.sampleRate = file.processingFormat.sampleRate
            self.currentFrameOffset = 0
            
            playerNode.scheduleFile(file, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handleTrackEnded()
                }
            }
            
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            playerNode.play()
        } catch {
            print("Error cargando archivo de audio estándar: \(error)")
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            if let player = avPlayer {
                player.pause()
            } else {
                playerNode.pause()
            }
            isPlaying = false
        } else {
            if let player = avPlayer {
                player.play()
                isPlaying = true
            } else if playerNode.isPlaying == false, audioFile == nil, !playlist.isEmpty {
                playTrack(at: currentIndex)
            } else {
                playerNode.play()
                isPlaying = true
            }
        }
        updateNowPlayingPlaybackState()
    }
    
    func nextTrack() {
        guard !playlist.isEmpty else { return }
        if isShuffle {
            let randomIndex = Int.random(in: 0..<playlist.count)
            playTrack(at: randomIndex)
        } else {
            let nextIndex = (currentIndex + 1) % playlist.count
            playTrack(at: nextIndex)
        }
    }
    
    func previousTrack() {
        guard !playlist.isEmpty else { return }
        if currentTime > 3.0 {
            seek(to: 0)
        } else {
            let prevIndex = (currentIndex - 1 + playlist.count) % playlist.count
            playTrack(at: prevIndex)
        }
    }
    
    func seek(to time: TimeInterval) {
        currentTime = time
        if let player = avPlayer {
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        } else if let file = audioFile {
            let targetFrame = AVAudioFramePosition(time * sampleRate)
            guard targetFrame < file.length else { return }
            
            let frameCount = AVAudioFrameCount(file.length - targetFrame)
            playerNode.stop()
            playerNode.scheduleSegment(file, startingFrame: targetFrame, frameCount: frameCount, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    self?.handleTrackEnded()
                }
            }
            currentFrameOffset = targetFrame
            if isPlaying { playerNode.play() }
        }
        updateNowPlayingInfo()
    }
    
    private func handleTrackEnded() {
        switch repeatMode {
        case .one:
            seek(to: 0)
        case .all:
            nextTrack()
        case .off:
            if currentIndex + 1 < playlist.count {
                nextTrack()
            } else {
                isPlaying = false
                currentTime = 0
            }
        }
    }
    
    // MARK: - Ecualizador y Preamp
    
    private func applyEqBands() {
        for (index, gain) in eqBands.enumerated() {
            if index < eqUnit.bands.count {
                eqUnit.bands[index].gain = gain
            }
        }
    }
    
    private func updatePreamp() {
        let linearGain = pow(10.0, preampGain / 20.0)
        playerNode.volume = linearGain
    }
    
    func applyPreset(_ preset: EqPreset) {
        eqBands = preset.gains
        applyEqBands()
    }
    
    private func startTimer() {
        progressTimer = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isPlaying, self.avPlayer == nil,
                      let nodeTime = self.playerNode.lastRenderTime,
                      let playerTime = self.playerNode.playerTime(forNodeTime: nodeTime) else { return }
                
                let currentSec = Double(playerTime.sampleTime + self.currentFrameOffset) / self.sampleRate
                if currentSec <= self.duration {
                    self.currentTime = max(0, currentSec)
                }
            }
    }
    
    // MARK: - Pantalla de Bloqueo y Control Center
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album,
            MPMediaItemPropertyPlaybackDuration: track.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let image = track.artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func updateNowPlayingPlaybackState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

/// Presets clásicos de ecualización estilo AIMP
enum EqPreset: String, CaseIterable, Identifiable {
    case flat = "Plano"
    case rock = "Rock"
    case bassBoost = "Graves ++"
    case pop = "Pop"
    case classical = "Clásica"
    case vocal = "Voz"
    case techno = "Techno"
    
    var id: String { rawValue }
    
    var gains: [Float] {
        switch self {
        case .flat:
            return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        case .rock:
            return [4.5, 3.0, 1.5, 0, -1.0, -0.5, 1.5, 3.0, 4.0, 4.5]
        case .bassBoost:
            return [7.0, 5.5, 3.5, 1.5, 0, 0, 0, 0, 0, 0]
        case .pop:
            return [-1.5, 0.5, 2.0, 3.5, 4.0, 3.0, 1.5, 0.5, -0.5, -1.0]
        case .classical:
            return [4.0, 3.0, 2.5, 2.0, -1.0, -1.0, 0, 2.0, 3.0, 3.5]
        case .vocal:
            return [-2.0, -2.0, -1.0, 1.5, 3.5, 3.5, 2.0, 0.5, -0.5, -1.5]
        case .techno:
            return [5.5, 4.5, 2.0, 0, -1.5, 0, 1.5, 3.5, 4.5, 5.0]
        }
    }
}

