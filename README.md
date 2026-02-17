# App Tammy — Gestor de Productos (Flutter)

App Flutter para gestionar productos con nombre, precio, descuento e imagen. Funcionalidades:
- **Listar productos** con búsqueda en tiempo real
- **Agregar/editar productos** con imagen, precio y descuento
- **Almacenamiento local** con `shared_preferences`
- **Interfaz intuitiva** con Material Design

## Requisitos

- **Flutter SDK 3.41.1+** (stable)
- **Android SDK** (para APK)
- **macOS + Xcode** (para IPA local, o usar GitHub Actions)
- **ksing** (para firmar IPA)

## Compilación rápida

### Android APK

```bash
cd C:\Users\Omar\Desktop\app_tammy
flutter pub get
flutter build apk --release
# Resultado: build/app/outputs/flutter-apk/app-release.apk
```

Instala en Android:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA (sin macOS)

Opción 1: **Usar GitHub Actions** (recomendado)
1. Crea repo en GitHub: `git init; git add .; git commit -m "Initial"; git push -u origin main`
2. Ve a Actions → selecciona `Build Android and iOS` → Run workflow
3. Descarga artefacto `app-unsigned.ipa`
4. Firma en `ksing` con tus certificados

Opción 2: **Compilar en macOS** (si lo tienes disponible)
```bash
flutter build ipa --release
# Obtiene: build/ios/iphoneos/Runner.app
# Empaqueta en .ipa y firma con ksing
```

## Estructura de archivos

```
app_tammy/
├── lib/
│   └── main.dart           # App principal (productos, búsqueda, editor)
├── pubspec.yaml            # Dependencias Flutter
├── .github/workflows/
│   └── build.yml           # CI/CD para generar APK e IPA
└── README.md               # Este archivo
```

## Notas importantes

- **Permisos**: El plugin `image_picker` solicita permisos de cámara/galería en iOS y Android.
- **Almacenamiento**: Los productos se guardan localmente; los datos persisten entre reinicios.
- **Firma .ipa**: Usa `ksing` con tus certificados Apple para firmar la `.ipa` sin cuenta developer paga.
