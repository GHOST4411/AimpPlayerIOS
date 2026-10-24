# AIMP Player para iOS (SwiftUI + AVAudioEngine)

Este proyecto es un clon funcional y visual de **AIMP Móvil (Android)** diseñado específicamente para **iOS (iPhone)**. Está desarrollado en Swift puro con SwiftUI y AVFoundation, sin publicidad, sin rastreo y sin suscripciones.

---

## 🎨 Características Implementadas al Estilo AIMP

1. **Diseño fiel a AIMP:**
   - Tema oscuro nativo carbón (`#121212`) con acentos en **naranja ámbar clásico de AIMP (`#FF8F00`)**.
   - Carátula con bordes redondeados y badge digital de formato (`FLAC`, `MP3`, etc.).
   - Botón Play/Pause circular en naranja de alto contraste.
   - Modos de reproducción: Aleatorio (*Shuffle*) y Repetición (*Off / All / One*).

2. **Navegación por Carpetas (Folder Explorer):**
   - Explorador de directorios locales con navegación jerárquica.
   - Botón *"Reproducir Todo"* para añadir y reproducir una carpeta completa al instante.
   - Selector para importar canciones desde cualquier carpeta de iCloud o de tu iPhone.

3. **Ecualizador de 10 Bandas + Preamp (DSP):**
   - Bandas fijas clásicas de AIMP: `31Hz`, `63Hz`, `125Hz`, `250Hz`, `500Hz`, `1kHz`, `2kHz`, `4kHz`, `8kHz`, `16kHz`.
   - Control deslizante de **Preamp** (-12 dB a +12 dB).
   - Presets integrados: *Plano (Flat), Rock, Graves ++ (Bass Boost), Pop, Clásica, Voz, Techno*.
   - Interruptor rápido `EQ ON / EQ OFF`.

4. **Soporte Nativo para Dolby Atmos y Audio Espacial:**
   - Detección automática de pistas **Dolby Atmos** (E-AC-3 con JOC, `.ec3`, `.eac3`, `.m4a`) y audio multicanal (5.1 y 7.1).
   - Renderizado espacial por hardware con soporte de seguimiento dinámico de cabeza en AirPods Pro y AirPods Max.
   - Insignia digital dorada de alta resolución `DOLBY ATMOS` en la interfaz principal.

5. **Integración profunda con iOS:**
   - **Segundo plano:** La música sigue sonando con la pantalla bloqueada o mientras usas otras apps.
   - **Pantalla de bloqueo y Control Center:** Carátula, título, artista, scrubber y controles de reproducción totalmente sincronizados (`MPNowPlayingInfoCenter`).
   - **Gestión de archivos sin iTunes:** La carpeta de la app es visible directamente en la app **Archivos** de tu iPhone (`En mi iPhone > AIMP Player`), por lo que puedes arrastrar canciones por cable o Wi-Fi.

---

## 🚀 Cómo compilar e instalar en tu iPhone

### Requisitos:
- Un Mac (o máquina virtual con macOS) con **Xcode** instalado (gratis en la Mac App Store).
- Un cable Lightning o USB-C para conectar tu iPhone.
- Una cuenta gratuita de Apple ID.

### Pasos:
1. Abre **Xcode** y selecciona **File > New > Project...** -> Elige **iOS > App**.
2. Nómbralo `AimpPlayerIOS` e interfaz **SwiftUI**.
3. Arrastra los archivos de esta carpeta a tu proyecto en Xcode:
   - `AimpPlayerApp.swift`
   - Carpeta `Models/` (`AudioTrack.swift`)
   - Carpeta `Services/` (`AudioEngineService.swift`, `FileManagerService.swift`)
   - Carpeta `Views/` (`Theme.swift`, `MainPlayerView.swift`, `EqualizerView.swift`, `FolderBrowserView.swift`, `PlaylistView.swift`)
4. En los ajustes de tu proyecto (`Signing & Capabilities`):
   - Inicia sesión con tu Apple ID gratuito en **Team**.
   - Añade la capacidad **Background Modes** y marca **Audio, AirPlay, and Picture in Picture**.
5. Conecta tu iPhone, selecciónalo como dispositivo de destino en la barra superior de Xcode y pulsa **▶ Run (Comando + R)**.
6. ¡Listo! La app se instalará en tu iPhone y podrás transferirle tu música desde la app **Archivos**.
