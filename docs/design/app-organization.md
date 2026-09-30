# Organización de App

`FranAlonso/App` contiene la entrada y la composición concreta de la aplicación. Las carpetas agrupan responsabilidades
existentes; no añaden capas ni trasladan reglas de negocio desde las features. `Bootstrap`, `Features`, `Shared` y
`Telemetry` conservan sus límites actuales.

| Ruta dentro de App | Qué buscar aquí |
|---|---|
| `FranAlonsoApp.swift` | Entrada de SwiftUI y declaración de la escena. |
| `Startup/` | `AppDelegate` y `ApplicationLaunchPlan`: arranque y elección del perfil de ejecución. |
| `Composition/` | `ApplicationComposition`, `AppRuntime` y `ClientDocumentComposition`: construcción y vida de dependencias. |
| `Composition/Dependencies/` | `AppDependencies`, sus extensiones por flujo y `AppEnvironment`: factories e inyección. |
| `Persistence/` | Schemas de aplicación, plan de migración y `ModelContainerFactory`. |
| `Presentation/Authentication/` | Pantalla raíz de autenticación y su ViewModel. |
| `Presentation/Shell/` | Shell adaptativo y su ViewModel. |
| `Presentation/Catalog/` | Entrada común al catálogo y su ViewModel. |
| `Development/` | Fixture de autenticación, composición, escenarios y aviso de la demo de desarrollo. |
| `Navigation/` | Secciones de navegación de la aplicación. |
| `Previews/` | Datos y dependencias deterministas para previews. |

Las pantallas conservan su ViewModel al lado. Las extensiones de `AppDependencies` permanecen en App porque componen
implementaciones concretas de varias capas. `AppEnvironment` distribuye esas dependencias mediante el entorno de SwiftUI.
`AppRuntime` vive en Composition porque administra esa composición durante la vida de la aplicación, más allá del arranque.

Registro de la reorganización y validación: [PLU-69](../progress/app-organization.md).
