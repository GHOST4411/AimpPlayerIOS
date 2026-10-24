import Foundation
import AVFoundation
import UIKit

/// Representa una pista de audio con metadatos completos y detección de Dolby Atmos / Multicanal
struct AudioTrack: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let fileExtension: String
    let artwork: UIImage?
    let channelCount: Int
    let isDolbyAtmos: Bool
    
    // Indicador digital estilo AIMP (ej. "DOLBY ATMOS", "FLAC 5.1", "MP3")
    var formatBadge: String {
        if isDolbyAtmos {
            return "DOLBY ATMOS"
        } else if channelCount > 2 {
            return "\(fileExtension.uppercased()) \(channelCount)CH"
        } else {
            return fileExtension.uppercased()
        }
    }
    
    static func == (lhs: AudioTrack, rhs: AudioTrack) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Carga metadatos y analiza las pistas de audio para detectar canales y Dolby Atmos
    static func from(url: URL) async -> AudioTrack {
        let asset = AVURLAsset(url: url)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Artista Desconocido"
        var album = "Álbum Desconocido"
        var artwork: UIImage? = nil
        var duration: TimeInterval = 0
        var channelCount = 2
        var isDolbyAtmos = false
        
        do {
            duration = try await CMTimeGetSeconds(asset.load(.duration))
            let metadata = try await asset.load(.commonMetadata)
            
            for item in metadata {
                guard let commonKey = item.commonKey else { continue }
                switch commonKey {
                case .commonKeyTitle:
                    if let stringVal = try? await item.load(.stringValue) {
                        title = stringVal
                    }
                case .commonKeyArtist:
                    if let stringVal = try? await item.load(.stringValue) {
                        artist = stringVal
                    }
                case .commonKeyAlbumName:
                    if let stringVal = try? await item.load(.stringValue) {
                        album = stringVal
                    }
                case .commonKeyArtwork:
                    if let data = try? await item.load(.dataValue) {
                        artwork = UIImage(data: data)
                    }
                default:
                    break
                }
            }
            
            // Inspeccionar las pistas de audio internas para Dolby Atmos / canales
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            for track in audioTracks {
                let formatDescriptions = try await track.load(.formatDescriptions)
                for desc in formatDescriptions {
                    if let audioStreamBasicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(desc) {
                        let channels = Int(audioStreamBasicDesc.pointee.mChannelsPerFrame)
                        if channels > channelCount {
                            channelCount = channels
                        }
                        
                        // Formato de cuatro caracteres (FourCC)
                        let formatID = audioStreamBasicDesc.pointee.mFormatID
                        // 'ec-3' (Enhanced AC-3 / Dolby Digital Plus / Atmos) o 'ac-3'
                        let formatIDString = FourCharCodeToString(formatID)
                        if formatIDString == "ec-3" || formatIDString == "ac-3" || channels > 2 {
                            isDolbyAtmos = true
                        }
                    }
                }
            }
        } catch {
            print("Error cargando metadatos para \(url.lastPathComponent): \(error)")
        }
        
        // Si el archivo tiene extensión típica de Dolby (.ec3, .eac3)
        let ext = url.pathExtension.lowercased()
        if ext == "ec3" || ext == "eac3" {
            isDolbyAtmos = true
        }
        
        return AudioTrack(
            id: UUID(),
            url: url,
            title: title,
            artist: artist,
            album: album,
            duration: duration > 0 ? duration : 0,
            fileExtension: url.pathExtension,
            artwork: artwork,
            channelCount: channelCount,
            isDolbyAtmos: isDolbyAtmos
        )
    }
    
    private static func FourCharCodeToString(_ code: FourCharCode) -> String {
        let bytes: [CChar] = [
            CChar((code >> 24) & 0xFF),
            CChar((code >> 16) & 0xFF),
            CChar((code >> 8) & 0xFF),
            CChar(code & 0xFF),
            0
        ]
        return String(cString: bytes)
    }
}
