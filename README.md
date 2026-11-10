# 📻 DM/FM Radio — iOS App (SwiftUI)

App nativa de radio en streaming para iOS desarrollada con **SwiftUI**, **AVFoundation** y **MediaPlayer**, estructurada con **XcodeGen** y compilada automáticamente en la nube a través de **GitHub Actions**.

![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![XcodeGen](https://img.shields.io/badge/XcodeGen-Ready-purple)
![CI](https://img.shields.io/badge/Build-GitHub%20Actions-success?logo=github-actions)

---

## ✨ Características

- 🎵 **Streaming en Vivo de Alta Fidelidad**: Compatible con servidores Icecast, Shoutcast, HLS y URLs MP3/AAC directas.
- 🔄 **Reproducción en Segundo Plano**: Configurado con `UIBackgroundModes: [audio]`; la radio sigue sonando mientras usas otras apps o con la pantalla apagada.
- 📱 **Control en Pantalla Bloqueada & Centro de Control**: Integración completa con `MPNowPlayingInfoCenter` y `MPRemoteCommandCenter` (Reproducir, Pausar, Cambiar volumen, Ver carátula y estado "En Vivo").
- 🏷️ **Metadatos en Tiempo Real**: Extracción automática de títulos de canciones y artistas desde los metadatos ICY del stream.
- 🌊 **Visualizador de Ondas & Vinilo Giratorio**: Animaciones fluidas que responden al estado de reproducción.
- 🎛️ **Selector de Emisoras & URL Personalizada**: Incluye canales preconfigurados y una pantalla de configuración para probar cualquier URL de streaming al instante.
- 🛠️ **Arquitectura Declarativa con XcodeGen**: El archivo `.xcodeproj` se genera bajo demanda mediante `project.yml`, eliminando conflictos de merge en Git.
- 🚀 **Compilación Automática (.ipa)**: Flujo de trabajo en GitHub Actions que genera el paquete instalador `.ipa` en cada commit a la rama `main`.

---

## 📁 Estructura del Proyecto

```
dmfm-radio/
├── .github/
│   └── workflows/
│       └── build-ios.yml          # Pipeline CI/CD para compilar el instalador .ipa
├── DMFMRadio/
│   ├── Config/
│   │   └── AppConfig.swift        # Emisoras predeterminadas y URL principal
│   ├── Services/
│   │   └── RadioPlayer.swift      # Motor de audio con AVPlayer, sesión y controles remotos
│   ├── Views/
│   │   ├── ContentView.swift      # Pantalla principal del reproductor
│   │   ├── PlayerControlsView.swift # Botones de reproducción y volumen
│   │   ├── VisualizerView.swift   # Espectro animado de ondas
│   │   └── SettingsView.swift     # Modal de configuración y stream personalizado
│   ├── Assets.xcassets/           # Colores e iconos de la app
│   ├── Info.plist                 # Permisos de audio y configuración ATS
│   └── DMFMRadioApp.swift         # Entrada principal @main de la app
├── project.yml                    # Especificación del proyecto para XcodeGen
├── .gitignore
└── README.md
```

---

## 🛠️ Cómo abrir y ejecutar localmente en tu Mac

1. **Instalar XcodeGen** (si no lo tienes):
   ```bash
   brew install xcodegen
   ```

2. **Generar el proyecto de Xcode**:
   ```bash
   xcodegen generate
   ```

3. **Abrir en Xcode**:
   ```bash
   open DMFMRadio.xcodeproj
   ```

4. Selecciona tu simulador o dispositivo físico iOS y presiona **Cmd + R** para ejecutar.

---

## 🌐 Cómo cambiar la URL de la Radio por defecto

Abre el archivo `DMFMRadio/Config/AppConfig.swift` y actualiza la variable `defaultStreamURL` con la dirección de tu emisora:

```swift
enum AppConfig {
    static let appName = "DM/FM Radio"
    static let defaultStreamURL = "https://tu-servidor-de-radio.com/stream"
    // ...
}
```

---

## 📦 Descarga del instalador .ipa (GitHub Actions)

Cada vez que realizas un `push` a la rama `main`:
1. Ve a la pestaña **Actions** en tu repositorio en GitHub: [casdavidm/dmfm-radio](https://github.com/casdavidm/dmfm-radio/actions).
2. Selecciona la ejecución más reciente del flujo **Build iOS (.ipa)**.
3. En la sección **Artifacts** al pie de la página, descarga el archivo comprimido **`DMFMRadio-ipa`**.
4. Puedes instalarlo en tu iPhone o iPad mediante herramientas como AltStore, Sideloadly, TrollStore o firmarlo con tu cuenta de desarrollador Apple.

