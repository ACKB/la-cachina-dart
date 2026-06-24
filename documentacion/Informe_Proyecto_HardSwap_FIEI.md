# 📖 INFORME FINAL DE PROYECTO: HARDSWAP FIEI (K-CHINA)
## Marketplace C2C de Hardware y Mentoría Técnica para la UNFV

---

### 👥 INFORMACIÓN DEL GRUPO DE TRABAJO
* **Institución:** Universidad Nacional Federico Villarreal (UNFV)
* **Facultad:** Facultad de Ingeniería Electrónica e Informática (FIEI)
* **Proyecto:** HardSwap FIEI (anteriormente denominado K-china)
* **Metodología:** Desarrollo Ágil - SCRUM
* **Estado:** Sprint 2 Completado / Sprint 3 y 4 Planificados
* **Fecha:** 21 de mayo de 2026

#### **Integrantes del Equipo:**
1. **Aviles Cortez, Juan Diego**
2. **Benites Berrocal, Carlos D'Alessandro**
3. **Koo Benavides, Armando Cesar**
4. **Pacheco Díaz, Danner Michael**
5. **Suazo Apolinario, Andrea del Pilar**

---

## 💻 RESUMEN EJECUTIVO

El presente informe técnico expone el proceso metodológico, el diseño de arquitectura y la ejecución del proyecto **HardSwap FIEI** (K-china), un mercado transaccional del Consumidor al Consumidor (C2C) y plataforma de mentoría técnica enfocado en la comunidad estudiantil de la Facultad de Ingeniería Electrónica e Informática de la UNFV. 

A través de la aplicación de la metodología ágil **Scrum**, el proyecto se ha desarrollado de manera iterativa e incremental, alcanzando un MVP robusto al término del **Sprint 2**. La solución tecnológica consta de una aplicación móvil-first desarrollada en **Flutter** integrada a un backend serverless en **Supabase** (PostgreSQL), la cual destaca por su sistema de almacenamiento de imágenes codificadas en Base64 y una capa de seguridad inquebrantable a nivel de motor de base de datos a través de **Row Level Security (RLS)**.

---

## 1. INTRODUCCIÓN Y PROBLEMÁTICA

### 1.1. Contexto de la FIEI - UNFV
En la formación académica de las ingenierías de la FIEI (Mecatrónica, Electrónica, Informática y Telecomunicaciones), el desarrollo práctico mediante laboratorios y proyectos integradores exige la adquisición constante de hardware libre, placas de desarrollo, sensores, actuadores y componentes de instrumentación.

### 1.2. Problemática Identificada
Tras una exhaustiva investigación de campo, se detectaron los siguientes puntos de dolor fundamentales:
1. **Ineficiencia en la Economía Circular:** Al finalizar cada ciclo académico, una gran cantidad de componentes electrónicos operativos quedan en desuso y acumulados en los hogares de los alumnos de ciclos superiores, mientras que los alumnos ingresantes deben comprar componentes nuevos a precios elevados.
2. **Riesgos y Logística Informal:** La comercialización informal actual en grupos de Facebook o chats de WhatsApp masivos genera desorden, una alta latencia en la respuesta y riesgos de fraudes o robos al realizar transacciones con desconocidos externos a la institución.
3. **Falta de Información y Garantía Técnica:** Los canales genéricos impiden clasificar y filtrar los dispositivos bajo parámetros técnicos críticos (voltajes, estado de los pines, enlaces a Datasheets). Además, existe el miedo recurrente de comprar piezas quemadas o dañadas.
4. **Brecha de Aprendizaje Colectivo:** Se identificó una demanda por asesoría y transferencia de conocimiento técnico entre el estudiante vendedor (ciclo superior) y el comprador (ciclo inferior), aspecto que el mercado informal desaprovecha por completo.

---

## 2. OBJETIVOS DEL PROYECTO

### 2.1. Objetivo General
* **Desarrollar e implementar un sistema C2C transaccional escalable (HardSwap FIEI)** que facilite la comercialización estructurada, económica y segura de hardware de desarrollo y la transferencia de conocimiento técnico entre los estudiantes de la UNFV.

### 2.2. Objetivos Específicos
1. **Diseñar una base de datos relacional robusta** en PostgreSQL, capaz de estructurar fichas técnicas, normalizar relaciones complejas e implementar integridad referencial en cascada para kits y favoritos.
2. **Implementar garantías estructurales de seguridad** mediante autenticación institucional (`@unfv.edu.pe`) y políticas de Row Level Security (RLS) en el motor de base de datos para impedir accesos no autorizados.
3. **Construir una interfaz de usuario interactiva y fluida** móvil-first con Flutter, capaz de soportar cargas asíncronas y optimización de renderizado de imágenes a 60 FPS.
4. **Optimizar la arquitectura del MVP para reducir costos de infraestructura**, almacenando imágenes codificadas en Base64 directamente en arreglos de PostgreSQL para prescindir de servicios de storage tradicionales de pago.

---

## 3. METODOLOGÍA Y ANÁLISIS DE USUARIOS (SCRUM INCEPTION)

### 3.1. Investigación de Campo e Insumos de Usuario
Para validar la viabilidad y delinear el MVP, el equipo ejecutó entrevistas semiestructuradas a una muestra representativa de **10 estudiantes** de las diversas escuelas académicas de la FIEI.

#### **Hallazgos Clave de las Entrevistas:**
* **Urgencia y Proximidad:** Los estudiantes priorizan resolver la emergencia del laboratorio de forma inmediata. Viajar a Paruro o Wilson les consume entre 3 y 4 horas entre el tráfico y el traslado, además del gasto económico en transporte. Prefieren realizar las transacciones directamente dentro del campus.
* **Disposición a Segunda Mano:** El 100% de los entrevistados valida el uso de componentes usados para laboratorios por factores de ahorro presupuestal y resiliencia ante errores de principiante ("prefiero quemar un componente barato de segunda que uno caro y nuevo").
* **Miedo a Estafas:** El principal obstáculo es la falta de garantía sobre la operatividad del componente. Restringir la comunidad a usuarios verificados de la UNFV y centralizar el catálogo técnico elimina esta incertidumbre de raíz.
* **El Valor de la Mentoría:** El "Tip del Vendedor" y los esquemas de conexión representan un activo de valor inestimable. Los alumnos de ciclos bajos valoran enormemente el soporte de aprendizaje colectivo que un compañero mayor puede brindarles.

---

## 4. PRODUCT BACKLOG COMPLETO (PILAS DEL PROYECTO)

El backlog del producto se estructuró a partir de las necesidades detectadas en el estudio cualitativo y la priorización de los Sprints de desarrollo:

| ID | Historia de Usuario | Prioridad | Sprint |
| :---: | :--- | :---: | :---: |
| **PB-01** | Como estudiante FIEI, quiero registrarme con mi correo institucional para validar que pertenezco a la universidad y generar confianza dentro de la plataforma. | Alta | Sprint 1 |
| **PB-02** | Como vendedor, quiero publicar componentes electrónicos con imágenes reales para mostrar el estado físico del producto. | Alta | Sprint 1 |
| **PB-03** | Como vendedor, quiero agregar información técnica del componente (modelo, estado y datasheet) para que los compradores puedan verificar compatibilidad. | Alta | Sprint 1 |
| **PB-04** | Como comprador, quiero buscar componentes mediante filtros y categorías para encontrar rápidamente lo que necesito. | Alta | Sprint 1 |
| **PB-05** | Como comprador, quiero visualizar detalles técnicos y fotografías del producto antes de contactar al vendedor. | Alta | Sprint 1 |
| **PB-06** | Como usuario, quiero guardar publicaciones favoritas para revisarlas posteriormente. | Baja | Sprint 2 |
| **PB-07** | Como estudiante, quiero acordar puntos de entrega seguros dentro de la universidad para facilitar el intercambio presencial. | Media | Sprint 2 |
| **PB-08** | Como usuario, quiero editar o eliminar mis publicaciones cuando el producto ya no esté disponible (ej. después de entregarlo). | Media | Sprint 2 |
| **PB-09** | Como vendedor, quiero crear kits personalizados para cursos específicos como Circuitos I o Electrónica Básica. | Media | Sprint 3 |
| **PB-10** | Como comprador, quiero visualizar el contenido completo de cada kit antes de adquirirlo. | Media | Sprint 3 |
| **PB-11** | Como estudiante de primeros ciclos, quiero acceder a kits prearmados de componentes para ahorrar tiempo y dinero en mis laboratorios. | Alta | Sprint 3 |
| **PB-12** | Como vendedor, quiero agregar recomendaciones técnicas y librerías relacionadas con el componente para ayudar a otros estudiantes. | Alta | Sprint 3 |
| **PB-13** | Como comprador, quiero visualizar tips de uso y configuraciones recomendadas para reducir errores en mis proyectos. | Alta | Sprint 3 |
| **PB-14** | Como administrador, quiero moderar publicaciones y usuarios para mantener el orden en la plataforma. | Media | Sprint 4 |

### **Funcionalidades Críticas del MVP**
Con base en los requerimientos del Product Backlog, se han priorizado y catalogado las siguientes funcionalidades de carácter crítico para constituir el Producto Mínimo Viable (MVP) de HardSwap FIEI:
* **Registro y autenticación universitaria:** Filtro de ingreso exclusivo y validación mediante cuentas con dominio institucional `@unfv.edu.pe`.
* **Publicación de componentes electrónicos:** Módulo ágil con subida asíncrona de fotografías de hardware codificadas en Base64.
* **Catálogo técnico con imágenes y datasheets:** Visualización fluida de piezas, filtrado por categorías específicas de la FIEI y redirección a hojas técnicas oficiales del fabricante.
* **Chat externo para negociación y coordinación:** Utilización de deep-linking con WhatsApp para preconfigurar mensajes automáticos que establecen las bases del acuerdo.
* **Sistema de reputación y verificación:** Intercambios de alta confianza confinados al entorno institucional verificado de la UNFV.
* **Kits de supervivencia para cursos:** Agrupación estructurada de hardware libre requerida para asignaturas prácticas de laboratorio específicas.
* **Repositorio de tips y mentoría técnica:** Espacio pedagógico interciclos para inyectar y visualizar hipervínculos a repositorios de GitHub con código funcional y manuales rápidos de uso.

### **Especificación y Clasificación de Requisitos según Scrum**
Bajo la metodología ágil Scrum, los requisitos no se gestionan en especificaciones tradicionales estáticas, sino que se organizan de manera dinámica en una estructura de valor incremental. A continuación, se detalla la clasificación formal de requisitos del sistema:

#### **1. Requisitos Funcionales (RF)**
Los Requisitos Funcionales definen los servicios que el sistema debe proporcionar y cómo debe reaccionar ante entradas particulares. En HardSwap FIEI, se derivan directamente del Product Backlog:
* **RF-01 [Autenticación Universitaria] (PB-01):** El sistema debe restringir el registro de usuarios únicamente a direcciones de correo institucional `@unfv.edu.pe`.
* **RF-02 [Publicación de Hardware] (PB-02):** El sistema debe permitir a los usuarios vendedores cargar fotografías reales de sus componentes electrónicos de forma asíncrona.
* **RF-03 [Ficha Técnica] (PB-03):** El sistema debe obligar al vendedor a ingresar la información básica del componente, que incluye el modelo físico, el estado de conservación (escala del 1 al 10) y la dirección opcional del datasheet.
* **RF-04 [Búsqueda Predictiva y Filtros] (PB-04):** El sistema debe ofrecer un motor de búsqueda predictivo con correspondencia difusa (*fuzzy matching*) y filtros por categorías técnicas (ej. Microcontroladores, Herramientas, Sensores).
* **RF-05 [Visualización Detallada] (PB-05):** El sistema debe proporcionar una ficha interactiva del producto mostrando descripción, precio, fotografías y un enlace para abrir la aplicación WhatsApp con un mensaje preconfigurado.
* **RF-06 [Módulo de Favoritos] (PB-06):** El sistema debe permitir a los usuarios autenticados marcar componentes de su interés como favoritos.
* **RF-07 [Selección de Puntos Neutrales] (PB-07):** El sistema debe permitir a los vendedores seleccionar un punto de encuentro físico seguro dentro de la FIEI (Patio FIEI, Cafetería, etc.) para la transacción.
* **RF-08 [CRUD de Publicaciones] (PB-08):** El sistema debe facultar a los vendedores para editar y eliminar sus publicaciones, o cambiar su estado a "Vendido".
* **RF-09 [Agrupación de Componentes en Kits] (PB-09):** El sistema debe permitir a los vendedores crear una publicación de tipo "Kit de Laboratorio" para cursos específicos.
* **RF-10 [Validación de Kit Completo] (PB-10):** El sistema debe mostrar el listado preciso y detallado con la cantidad de cada subcomponente que conforma un kit.
* **RF-11 [Mentoría y Librerías de Código] (PB-12):** El sistema debe permitir adjuntar consejos técnicos de uso y enlaces a repositorios de GitHub relacionados con el componente.
* **RF-12 [Moderación e Informes] (PB-14):** El sistema debe proporcionar un panel de administración para auditar publicaciones reportadas como sospechosas y sancionar usuarios fraudulentos.

#### **2. Requisitos No Funcionales (RNF) y Definición de Terminado (DoD)**
Los Requisitos No Funcionales actúan como restricciones globales del sistema que garantizan la calidad del software. En Scrum, estos requisitos se asocian de manera transversal a la **Definición de Terminado (DoD)**:
* **RNF-01 [Aislamiento RLS]:** Todas las tablas del catálogo deben poseer directivas de Row Level Security (RLS) habilitadas en PostgreSQL.
* **RNF-02 [Tokens de Acceso JWT]:** Todas las consultas REST enviadas al backend deben ir acompañadas del token JWT firmado por Supabase Auth para verificar la identidad (`auth.uid()`).
* **RNF-03 [Procesamiento en Local]:** El algoritmo predictivo del buscador difuso en Flutter debe procesar los términos a nivel local con tiempos de respuesta inferiores a los 100ms.
* **RNF-04 [Eficiencia de Almacenamiento]:** El flujo de carga de imágenes debe realizar una compresión automática de bytes y codificación Base64 en el cliente antes de la transmisión HTTP.
* **RNF-05 [Interfaz Adaptativa (M3)]:** La interfaz de la app debe respetar los lineamientos de **Material Design 3** con contraste accesible y soporte responsivo para Android e iOS.
* **RNF-06 [Clean Architecture]:** El código en Flutter debe estructurarse estrictamente bajo tres capas desacopladas de Clean Architecture: Presentación, Dominio y Datos.

---

## 5. SPRINT 1: CIMENTACIÓN DEL CORE Y CATÁLOGO PÚBLICO

### 5.1. Planificación del Sprint 1
* **Objetivo principal:** Diseñar la estructura fundamental de la base de datos PostgreSQL, configurar la sincronización de autenticación automatizada de Supabase e implementar el catálogo público del marketplace en Flutter con filtros interactivos.
* **Historias de Usuario cubiertas:** PB-01, PB-02, PB-03, PB-04, PB-05.
* **Esfuerzo planificado:** 64 horas de desarrollo.

### 5.2. Arquitectura de Base de Datos y Seguridad (PostgreSQL / Supabase)
Durante esta fase inicial, se configuraron las extensiones criptográficas y de IDs aleatorios, y se diseñaron las tablas base en la nube de Supabase.

#### **Esquema de Base de Datos - Hito Sprint 1:**
* **`public.users`:** Espejo seguro de la tabla interna `auth.users` de Supabase Auth.
* **`public.categories`:** Listado precargado con las categorías técnicas de la facultad (Microcontroladores, Sensores, Herramientas, RF, etc.).
* **`public.products`:** Almacenamiento central del marketplace con restricciones físicas (`CHECK` para precios positivos y estados de vida del 1 al 10).

#### **El Sincronizador Automático de Cuentas (Trigger SQL):**
Para garantizar que cada estudiante registrado a través del sistema de autenticación institucional de Supabase tenga un perfil público manipulable de manera inmediata, se diseñó e implementó un Trigger a nivel del motor relacional:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    'user'
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

### 5.3. Implementación en el Frontend (Flutter)
En la parte móvil se crearon las pantallas clave para cumplir el objetivo del catálogo técnico:
* **`login_screen.dart`:** Validador local de dominio institucional y puerta de enlace OAuth.
* **`catalog_screen.dart`:** Utiliza inyección de estados asíncronos y filtros selectivos. Implementa una barra interactiva de chips (`category_chip_bar.dart`) y una barra de búsqueda predictiva con búsqueda "fuzzy".
* **`new_product_screen.dart`:** Interfaz intuitiva para vendedores que permite rellenar especificaciones técnicas y adjuntar fotos tomadas al instante con la cámara del celular.

---

## 6. SPRINT 2: LOGÍSTICA SEGURA Y GESTIÓN DE PUBLICACIONES

### 6.1. Planificación del Sprint 2
* **Objetivo principal:** Habilitar el módulo de transacciones seguras (WhatsApp y puntos de entrega físicos en la universidad), permitir al comprador guardar componentes de interés, y otorgar control total de inventario a los vendedores.
* **Historias de Usuario cubiertas:** PB-06, PB-07, PB-08.
* **Esfuerzo planificado:** 30 horas de desarrollo.

### 6.2. Diseño de Tablas y Seguridad Incremental
Para soportar las nuevas capacidades del hito sin romper la normalización, se crearon tablas de relación cruzada y se securizó la base de datos contra ataques de inyección y suplantación de identidad mediante **Row Level Security (RLS)**.

#### **Nuevas Tablas del Sprint 2:**
* **`public.favorites`:** Tabla de unión de muchos a muchos que mapea la persistencia de los favoritos por usuario.
* **`public.reports`:** Registro estructurado de denuncias para moderación.
* **`public.kit_items`:** Tabla relacional enlazada en cascada (`ON DELETE CASCADE`) para soportar la composición interna de KITS para el Sprint 3.

#### **El Escudo Protector de Datos (Políticas RLS Activas):**
Con RLS habilitado, los usuarios no acceden de forma irrestricta a las tablas. El motor de PostgreSQL evalúa la identidad firmada por JWT (`auth.uid()`) antes de ejecutar cualquier transacción:

```sql
-- Activar el aislamiento a nivel de fila
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 1. El catálogo de productos disponibles es público para lectura
CREATE POLICY "catalog is public" ON public.products 
  FOR SELECT USING (true);

-- 2. Solo el autor con token JWT válido puede inyectar publicaciones
CREATE POLICY "owners can insert products" ON public.products 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Solo el propietario legítimo de la publicación puede actualizarla o retirarla
CREATE POLICY "owners can update products" ON public.products 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "owners can delete products" ON public.products 
  FOR DELETE USING (auth.uid() = user_id);

-- 4. Excepción administrativa: los moderadores tienen privilegios absolutos
CREATE POLICY "admins can do anything on products" ON public.products 
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );
```

### 6.3. Mejoras Funcionales y UX en el Frontend
* **`dashboard_screen.dart` (Mis Publicaciones):** Un espacio centralizado para que el vendedor gestione su inventario activo. Incorpora la capacidad de cambiar de estado de forma instantánea de *AVAILABLE* a *SOLD* (marcar como vendido) o eliminar la publicación con un diálogo de confirmación seguro.
* **`whatsapp_form_widget.dart`:** Vinculación directa al WhatsApp del vendedor. Al pulsar el botón "Contactar Vendedor", la aplicación realiza un deep-linking seguro abriendo la API de WhatsApp con un mensaje preconfigurado detallando el título del producto, precio, y sugiriendo reunirse en uno de los puntos predefinidos del campus (ej: *"Hola, estoy interesado en tu ESP32 de S/. 25.00 publicado en HardSwap. ¿Podemos vernos en el Patio Principal de la FIEI?"*).
* **Integración del Catálogo de Favoritos:** Pantalla dedicada que permite navegar y monitorear la variación de precios o el stock de los productos que el estudiante tiene en la mira.

---

## 7. OPTIMIZACIÓN DESTACADA DE ARQUITECTURA: EL HACK DE IMÁGENES EN BASE64

Una de las decisiones arquitectónicas más brillantes implementadas por el equipo para el MVP de **HardSwap FIEI** fue el **almacenamiento de imágenes de productos como Base64 dentro de arreglos integrados en PostgreSQL (`images_base64 TEXT[]`)**.

### ¿Por qué se tomó esta decisión?
1. **Reducción a Cero del Gasto en Storage:** El almacenamiento tradicional en la nube (AWS S3, Google Cloud Storage, Supabase Buckets) requiere suscripciones de pago y configuraciones complejas de CORS y buckets en el desarrollo inicial.
2. **Consultas en una Sola Petición:** Al guardar el catálogo técnico y la representación binaria cifrada de la imagen en un solo registro relacional, el frontend de Flutter obtiene toda la información de la publicación en una única solicitud asíncrona. Se reduce drásticamente el consumo de tráfico HTTP y el retardo de latencia.
3. **Flujo de Carga Directo en Flutter:**
   * El vendedor toma una foto con el `image_picker`.
   * El dispositivo móvil lee los bytes y los codifica a un String Base64 de forma local.
   * Se empaqueta en el objeto JSON de inserción y se envía a la nube en una llamada instantánea.
   * En el catálogo, la UI decodifica e inyecta la memoria directamente en el widget `Image.memory()` a 60 FPS estables.

---

## 8. ESTRUCTURA COMPLETA DE ARCHIVOS DEL PROYECTO ACTUAL

El proyecto actual se rige por una arquitectura modular, estructurada bajo estándares de desarrollo escalables y limpios para Flutter:

```
la-cachina-dart/
├── schema_completo.sql          ← 🗄️ Esquema de Base de Datos PostgreSQL v2.0 (Supabase/Local)
├── pubspec.yaml                ← Gestión de librerías y dependencias
├── lib/
│   ├── main.dart               ← Punto de entrada e inicialización de servicios
│   ├── models/
│   │   ├── user_model.dart     ← Modelo estructural para usuarios
│   │   ├── category_model.dart ← Mapeo estructurado de categorías
│   │   └── product_model.dart  ← Modelo de datos de publicaciones y enumeradores de estado
│   ├── database/
│   │   ├── database_config.dart ← Parámetros de entorno y strings de conexión
│   │   └── database_service.dart ← Repositorio asíncrono central (Queries, Stored Procedures)
│   ├── services/
│   │   └── auth_service.dart   ← Lógica y wrappers de autenticación corporativa
│   ├── screens/
│   │   ├── login_screen.dart   ← Portal de acceso y validación de correo
│   │   ├── catalog_screen.dart ← Visualización del catálogo técnico con búsqueda predictiva
│   │   ├── dashboard_screen.dart ← Gestión de inventario de ventas del vendedor
│   │   └── new_product_screen.dart ← Formulario técnico de publicación con toma de fotos
│   ├── widgets/
│   │   ├── navbar_widget.dart         ← Barra inferior de navegación interactiva
│   │   ├── product_card_widget.dart   ← Tarjeta del catálogo adaptativa
│   │   ├── product_actions_widget.dart ← Panel de mandos y edición
│   │   ├── whatsapp_form_widget.dart  ← Módulo de deep-linking y mensajería
│   │   └── category_chip_bar.dart    ← Barra horizontal de categorías
│   └── utils/
│       ├── app_theme.dart      ← Configuración visual Material Design 3 (Claro / Oscuro)
│       ├── app_router.dart     ← Manejador del árbol de rutas de la aplicación
│       └── format_utils.dart   ← Parseadores y conversores (ej: Conversión de centavos a soles)
```

---

## 9. APRENDIZAJES Y MEJORAS VS. IDEA INICIAL

El proyecto ha experimentado una evolución notable desde su concepción inicial (que contemplaba un backend pesado basado en Next.js, Express y bases de datos locales) hasta migrar a una arquitectura móvil nativa más eficiente:
* **Seguridad Centralizada:** Se reemplazó la lógica compleja de validación en la capa intermedia de software por directivas SQL directas (RLS) en el motor, volviendo la aplicación virtualmente inmune a manipulaciones externas.
* **Rendimiento UI:** El uso de Flutter con gestión de estados optimizada garantiza transiciones y desplazamientos fluidos de la galería de imágenes del catálogo a 60 FPS estables.
* **Diseño Académico Relevante:** Puntos de entrega seguros predefinidos eliminaron el miedo al encuentro con desconocidos, promoviendo el campus de la FIEI como un espacio de comercio libre de riesgos.

---

## 10. TRABAJO FUTURO Y PLANIFICACIÓN DE SPRINTS RESTANTES

El desarrollo ágil del proyecto continuará en los siguientes dos sprints planificados para alcanzar la versión de producción 1.0:

### 🚀 Sprint 3: Módulo de Kits e Integración de Mentoría (PB-09 a PB-13)
* **Objetivo:** Permitir la creación de "Kits de Supervivencia" estructurados para asignaturas específicas y dotar a cada componente de valor pedagógico mediante tips del vendedor y vínculos a código abierto.
* **Componentes a Modificar/Crear:**
  * Habilitar la inserción múltiple en `public.kit_items` asociada a un producto base tipo `KIT`.
  * Diseñar la UI especial en el catálogo que diferencie tarjetas de componentes individuales y kits académicos de ciclos superiores.
  * Añadir bloques dinámicos de recomendaciones técnicas en `lib/screens/new_product_screen.dart` y repositorios GitHub validados en el frontend.

### 👑 Sprint 4: Panel de Moderación y Auditoría del Sistema (PB-14)
* **Objetivo:** Implementar la interfaz administrativa de moderación y auditoría de seguridad.
* **Componentes a Modificar/Crear:**
  * Crear la pantalla de Panel de Administración (`admin_dashboard_screen.dart`) restringida por el rol `admin` de la base de datos.
  * Habilitar reportes directos en el motor para publicaciones denunciadas y suspender automáticamente cuentas que violen los términos de uso de la comunidad universitaria.

---

### 📝 CONCLUSIÓN GENERAL

**HardSwap FIEI** demuestra con éxito que una plataforma de comercio C2C institucional, respaldada por garantías tecnológicas estructuradas (autenticación obligatoria `@unfv.edu.pe`, políticas RLS nativas, almacenamiento ágil de imágenes en Base64 y puntos seguros dentro del campus), tiene el potencial de transformar el mercado informal y desordenado de hardware en un ecosistema seguro, dinámico y pedagógico dentro de la comunidad de la Universidad Nacional Federico Villarreal.
