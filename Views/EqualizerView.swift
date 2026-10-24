import SwiftUI

/// Pantalla del ecualizador clásico de 10 bandas con estilo AIMP
struct EqualizerView: View {
    @ObservedObject var audioService: AudioEngineService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AimpTheme.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Cabecera de controles superiores: Switch y Presets
                    HStack {
                        // Interruptor de Encendido/Apagado estilo AIMP
                        Toggle("EQ", isOn: $audioService.isEqEnabled)
                            .toggleStyle(AimpToggleStyle())
                            .frame(width: 90)
                        
                        Spacer()
                        
                        // Menú de Presets
                        Menu {
                            ForEach(EqPreset.allCases) { preset in
                                Button(preset.rawValue) {
                                    audioService.applyPreset(preset)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "slider.horizontal.3")
                                Text("Ajustes Predefinidos")
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(AimpTheme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AimpTheme.surface)
                            .cornerRadius(8)
                        }
                        
                        // Botón Restablecer a 0
                        Button(action: {
                            audioService.applyPreset(.flat)
                            audioService.preampGain = 0
                        }) {
                            Text("Reset")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AimpTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(AimpTheme.cardBackground)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Divider().background(AimpTheme.divider)
                    
                    // Sección de Preamp y las 10 bandas
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 14) {
                            // Deslizador de Preamp
                            VStack(spacing: 8) {
                                Text(String(format: "%+.1f dB", audioService.preampGain))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(AimpTheme.primary)
                                
                                VerticalSlider(
                                    value: $audioService.preampGain,
                                    range: -12...12,
                                    accentColor: AimpTheme.primaryLight
                                )
                                .frame(width: 32, height: 220)
                                
                                Text("PREAMP")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AimpTheme.textPrimary)
                            }
                            .padding(.horizontal, 4)
                            
                            Rectangle()
                                .fill(AimpTheme.divider)
                                .frame(width: 1, height: 240)
                            
                            // Las 10 bandas del ecualizador
                            ForEach(0..<10, id: \.self) { index in
                                VStack(spacing: 8) {
                                    Text(String(format: "%+.1f", audioService.eqBands[index]))
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(audioService.isEqEnabled ? AimpTheme.primary : AimpTheme.textMuted)
                                    
                                    VerticalSlider(
                                        value: $audioService.eqBands[index],
                                        range: -12...12,
                                        accentColor: AimpTheme.primary,
                                        isEnabled: audioService.isEqEnabled
                                    )
                                    .frame(width: 28, height: 220)
                                    
                                    Text(AudioEngineService.bandLabels[index])
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AimpTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Ecualizador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
}

/// Control deslizante vertical personalizado para simular las perillas de AIMP
struct VerticalSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    var accentColor: Color = AimpTheme.primary
    var isEnabled: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let normalized = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbY = height * (1 - normalized)
            
            ZStack(alignment: .bottom) {
                // Barra de fondo
                RoundedRectangle(cornerRadius: 3)
                    .fill(AimpTheme.sliderTrack)
                    .frame(width: 4)
                
                // Línea central de 0 dB
                Rectangle()
                    .fill(AimpTheme.textMuted.opacity(0.6))
                    .frame(width: 16, height: 1)
                    .position(x: geometry.size.width / 2, y: height / 2)
                
                // Barra de ganancia activa
                RoundedRectangle(cornerRadius: 3)
                    .fill(isEnabled ? accentColor : AimpTheme.textMuted)
                    .frame(width: 4, height: abs(thumbY - height / 2))
                    .position(x: geometry.size.width / 2, y: (thumbY + height / 2) / 2)
                
                // Botón deslizador (Thumb) estilo AIMP
                Circle()
                    .fill(isEnabled ? accentColor : AimpTheme.textMuted)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    )
                    .position(x: geometry.size.width / 2, y: thumbY)
            }
            .frame(width: geometry.size.width, height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled else { return }
                        let clampedY = max(0, min(height, gesture.location.y))
                        let percent = 1 - (clampedY / height)
                        let newValue = range.lowerBound + Float(percent) * (range.upperBound - range.lowerBound)
                        value = newValue
                    }
            )
        }
    }
}

/// Estilo de interruptor con los colores de AIMP
struct AimpToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Text(configuration.isOn ? "EQ ON" : "EQ OFF")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(configuration.isOn ? AimpTheme.primary : AimpTheme.textMuted)
            
            RoundedRectangle(cornerRadius: 14)
                .fill(configuration.isOn ? AimpTheme.primary : AimpTheme.sliderTrack)
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
