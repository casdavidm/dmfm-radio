# 📻 DM/FM Radio — iOS App (SwiftUI)

App nativa de radio en streaming para iOS desarrollada con **SwiftUI**, **AVFoundation** y **MediaPlayer**, con interfaz minimalista oscura y acento amarillo, sintonizador de vinilo y conexión directa a la base de datos mundial de emisoras en vivo vía **Radio Browser API**.

![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![XcodeGen](https://img.shields.io/badge/XcodeGen-Ready-purple)
![CI](https://img.shields.io/badge/Build-GitHub%20Actions-success?logo=github-actions)
![Radio Browser](https://img.shields.io/badge/Radio--Browser-API-yellow)

---

## 🎨 Paleta de Colores Estricta

| Elemento | Hex | Color |
|---|---|---|
| **Fondo principal** | `#111827` | Azul oscuro profundo |
| **Contenedores y tarjetas** | `#1F2937` | Gris azulado oscuro |
| **Borde sutil** | `#374151` | Borde divisor |
| **Acento y elementos activos** | `#ffc61a` | Amarillo brillante |
| **Tipografía principal** | `#ffffff` | Blanco puro |
| **Tipografía secundaria y diales** | `#9CA3AF` | Gris neutro |

---

## ✨ Características

- 🌍 **Base de Datos Mundial de Emisoras**: Conectada a la API pública de **Radio Browser** (`de1.api.radio-browser.info`) con búsqueda en tiempo real de miles de emisoras globales.
- 🔒 **Filtro HTTPS Estricto**: Filtra exclusivamente streams seguros con protocolo `https://` y bitrate funcional para garantizar compatibilidad nativa en iOS.
- ⚡ **Barra de Búsqueda Reactiva**: Búsqueda instantánea con *debounce* de 400ms por nombre de emisora o género musical.
- 🏷️ **Chips de Filtro Rápido**: Accesos directos a:
  - `Top Mundial` (emisoras con mayor número de votos globales)
  - `España` (`ES`)
  - `México` (`MX`)
  - `Colombia` (`CO`)
  - `Argentina` (`AR`)
  - `Favoritos` (guardados localmente con `FavoritesManager`)
- 💿 **El Vinilo & Dial de Sintonizador FM**:
  - Disco de vinilo minimalista con animación fluida a 60/120 fps mediante `TimelineView`.
  - Escala analógica/digital graduada de 88.0 a 108.0 MHz con aguja en amarillo `#ffc61a` posicionada en la frecuencia de la emisora.
- 📱 **Mini-Reproductor Persistente**: Barra inferior flotante con mini vinilo, nombre de la estación, estado de búfer ("Sintonizando señal...") y botón circular Play/Pause en `#ffc61a`. Al pulsar, despliega la hoja modal con el reproductor completo.
- 🔄 **Reproducción en Segundo Plano**: Soporte completo con `UIBackgroundModes: [audio]`; la música continúa reproduciéndose con la pantalla bloqueada o al cambiar de aplicación.
- 🎛️ **Controles en Pantalla Bloqueada & Centro de Control**: Integración con `MPNowPlayingInfoCenter` y `MPRemoteCommandCenter`.
- 🛠️ **Arquitectura Declarativa con XcodeGen**: El proyecto `.xcodeproj` se genera a partir de `project.yml`, evitando conflictos de Git.
- 🚀 **Compilación Automática (.ipa)**: Pipeline de GitHub Actions en macOS que genera y firma el paquete instalador `.ipa` en cada push a `main`.

---

## 📁 Estructura del Proyecto

```
dmfm-radio/
├── .github/
│   └── workflows/
│       └── build-ios.yml              # Pipeline CI/CD que genera el archivo .ipa
├── DMFMRadio/
│   ├── Config/
│   │   └── AppConfig.swift            # Modelo RadioStation y emisoras por defecto
│   ├── Theme/
│   │   └── AppTheme.swift             # Paleta de colores estricta (#111827, #1F2937, #ffc61a)
│   ├── Services/
│   │   ├── RadioBrowserService.swift  # Cliente de Radio Browser API con búsqueda y filtros
│   │   ├── FavoritesManager.swift     # Persistencia de emisoras favoritas en UserDefaults
│   │   └── RadioPlayer.swift          # Motor AVPlayer, sesión de audio y controles remotos
│   ├── Views/
│   │   ├── ContentView.swift          # Pantalla principal con Header, Search y Chips
│   │   ├── StationCardView.swift      # Tarjeta minimalista de emisora con dial y bitrate
│   │   ├── PersistentMiniPlayerView.swift # Mini-reproductor flotante inferior
│   │   ├── FullPlayerSheetView.swift  # Hoja modal completa con vinilo y escala de dial FM
│   │   ├── VinylDiscView.swift        # Componente de disco de vinilo animado
│   │   ├── PlayerControlsView.swift   # Controles de reproducción y volumen
│   │   └── SettingsView.swift         # Configuración y stream manual
│   ├── Assets.xcassets/               # Iconos de la app y colores
│   ├── Info.plist                     # Modos de segundo plano y configuración ATS
│   └── DMFMApp.swift                  # Punto de entrada @main de la aplicación
├── project.yml                        # Especificación del proyecto para XcodeGen
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

4. Selecciona tu simulador o dispositivo físico iOS y presiona **Cmd + R** para compilar y ejecutar.

---

## 📦 Descarga del instalador .ipa (GitHub Actions)

En cada `push` a la rama `main`:
1. Ve a la pestaña **Actions** en tu repositorio: [casdavidm/dmfm-radio/actions](https://github.com/casdavidm/dmfm-radio/actions).
2. Selecciona la ejecución más reciente del flujo **Build iOS (.ipa)**.
3. En la sección **Artifacts** al pie de la página, descarga el paquete **`DMFMRadio-ipa`**.
4. Puedes instalarlo directamente en tu iPhone o iPad mediante herramientas como AltStore, Sideloadly, TrollStore o firmarlo con tu certificado de Apple Developer.
