# flutter_prototype_crypto_binance

Esta aplicación Flutter es una interfaz móvil que interactúa con una API y Websocket de Binance, obtiene y muestra información sobre las cryptos en orden desendente con su logo, nombres y precios actualizados en tiempo real, tambien permite buscar cryptos por nombre.

## Características

  - **Listado de Cryptos** 🏆: Muestra una lista de Cryptos con logo, nombres y precios actualizados en tiempo real.
  - **Búsqueda y Filtros** 🎯: Permite buscar cryptos por nombre.
  - **Interfaz Interactiva** 🎨: Utiliza tarjetas que muestran logo, nombres y precios con un cambio de color cuando el precio varia.

## Requerimientos

  - [Flutter](https://docs.flutter.dev/get-started/install)  
  - [Android Studio](https://developer.android.com/studio/install?hl=es-419#windows) (se requiere la versión completa para depurar y compilar código Java o Kotlin en Android)
  - [Git para Windows](https://gitforwindows.org/) para administrar el código fuente.
  - [Visual Studio Code](https://code.visualstudio.com/docs/setup/windows) (editor recomendado para Flutter, junto con la extensión [Flutter para VS Code](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter))
  - Emulador o dispositivo Android para probar la aplicación.

## Instalacion

Siga los pasos a continuación para configurar y ejecutar la aplicación en su entorno local.

### 1. Clonar el repositorio
Abra su terminal favorito y ejecute:
```sh
git git@github.com:dvillafane/flutter_crypto_binance.git
```
### 2. Navegar al directorio del proyecto
Una vez clonado el repositorio, ingrese al directorio del proyecto:
```sh
cd nombre-del-repositorio
```

### 3. Instalar las dependencias
Dentro del directorio del proyecto, ejecute:
```sh
flutter pub get
```

### 4. Configurar el emulador de Android
Si aún no tiene un emulador configurado:

  - Abra Android Studio.

  - Vaya a Virtual Device Manager.
  
  - Configure un nuevo emulador Android siguiendo las instrucciones en pantalla.

### 5. Ejecutar la aplicación
Para compilar y ejecutar la aplicación, utilice:
```sh
flutter run
```