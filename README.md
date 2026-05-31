# 🛒 La Cachina FIEI (HardSwap) — Flutter Web & Mobile

¡Bienvenido al repositorio de **La Cachina FIEI (HardSwap)**! Este proyecto es un marketplace premium y responsivo de hardware diseñado específicamente para la comunidad de estudiantes de la **FIEI - Universidad Nacional Federico Villarreal (UNFV)**. Permite a los estudiantes publicar, buscar, guardar favoritos y contactar a vendedores por WhatsApp para la compra y venta de componentes electrónicos.

El proyecto está construido bajo una arquitectura modular y adaptativa, sirviendo de manera fluida tanto en computadoras de escritorio (diseño web de doble columna) como en dispositivos móviles.

---

## 🚀 Características Clave

* **Diseño Web Adaptativo Premium (Responsive Layout):** Cabecera web de escritorio superior, rejilla adaptativa de productos (de 2 a 5 columnas según el tamaño de la pantalla), formularios centrados y protegidos a `700px`, y hojas de opciones flotantes.
* **Detalle de Producto en Doble Columna (Desktop UX):** Interfaz dividida en PC que coloca la galería multimedia a la izquierda y los detalles/especificaciones técnicas con scroll independiente a la derecha.
* **Base de Datos Remota con Supabase:** Integración nativa con **Supabase (PostgreSQL en la nube)** para autenticación, gestión de catálogo en tiempo real e imágenes.
* **Gestión de Estado Reactiva (Riverpod):** Control robusto e inmutable del estado usando `flutter_riverpod` y `hooks_riverpod`.
* **Ficha Técnica y Tips Técnicos (PB-03/12/13):** Espacio especializado para añadir el modelo exacto de componentes, condición (escala 1-10), enlace a datasheet, tips de uso y enlaces a repositorios de GitHub.
* **Soporte de Kits Educativos (PB-09/10/11):** Permite publicar conjuntos de componentes (Kits) especificando la lista de elementos incluidos, cantidad y el curso universitario asociado.

---

## 📁 Arquitectura del Proyecto (Clean Architecture)

El código sigue las mejores prácticas de **Clean Architecture** estructurado por características modulares (`features`):

```
lib/
├── core/
│   ├── theme/          ← Sistema de diseño, colores (HSL) y tipografía (Google Fonts)
│   ├── router/         ← Enrutamiento declarativo y guards con go_router
│   └── widgets/        ← Componentes globales (Layout Responsivo, BottomNav, Shimmer de carga)
└── features/
    ├── auth/           ← Autenticación segura con Microsoft Entra ID
    ├── catalog/        ← Exploración de productos, búsqueda local fuzzy y filtros por categoría
    ├── favorites/      ← Gestión local de favoritos de hardware
    ├── product_management/ ← Dashboard personal, publicación de productos y kits con ficha técnica
    └── user_profile/   ← Configuración de número de WhatsApp de contacto institucional
```

---

## 💻 Requisitos Previos

Asegúrate de contar con el SDK de Flutter instalado en tu sistema:
- **Flutter SDK:** `>=3.19.0` (Probado y optimizado en Flutter `3.41.9`)
- **Dart SDK:** `>=3.3.0 <4.0.0`

---

## 🔌 Instalación y Ejecución

1. **Clonar este repositorio:**
   ```bash
   git clone https://github.com/TU_USUARIO/la-cachina-dart.git
   cd la-cachina-dart
   ```

2. **Instalar dependencias del proyecto:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar en modo Desarrollo (Web Server de Bajo Consumo):**
   Si deseas probar el proyecto de forma local ahorrando al máximo la memoria RAM de tu computadora, inicia el servidor sin abrir navegadores pesados de forma automática:
   ```bash
   flutter run -d web-server --web-renderer html --web-port 8080
   ```
   Luego, abre tu navegador habitual y entra a **`http://localhost:8080`**.

4. **Compilar la Web de forma Ultra Ligera (Producción):**
   Para publicar el proyecto en hostings estáticos (como GitHub Pages o Vercel) optimizando la velocidad de carga al 100%, genera la versión HTML nativa:
   ```bash
   flutter build web --release --web-renderer html
   ```

---

## ☁️ Backend y Servicios Cloud

Este proyecto no requiere de bases de datos locales pesadas. Toda la persistencia de datos e imágenes está configurada en la nube:
- **Base de Datos:** PostgreSQL remoto administrado por **Supabase**.
- **Almacenamiento de Imágenes:** Cloudflare R2 / Supabase Storage.
- **Autenticación:** Proveedor seguro de Microsoft Office 365.

---

## 🎨 Principios de Diseño Visual

La interfaz web ha sido pulida bajo estrictos estándares estéticos modernos:
- Paleta de colores armoniosa basada en escala de grises Zinc y acentos en Azul Primario.
- Microanimaciones para estados de hover y carga simulados mediante Shimmers fluidos.
- Pestañas de navegación web flotantes adaptadas para su uso cómodo tanto con mouse como con pantallas táctiles.
