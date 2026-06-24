# 🎨 Guía de Diagramas y Modelamiento — HardSwap FIEI

Este archivo contiene el código de todos los diagramas requeridos en la **Sección 2.2 y 2.4** usando la sintaxis **Mermaid.js**. Puedes previsualizarlos en tu IDE o copiarlos y pegarlos en el [Mermaid Live Editor](https://mermaid.live) para exportarlos como imagen (PNG/SVG) o PDF para tu informe final.

---

## 🗺️ 1. Diagramas de Procesos (Sección 2.2)

### 1.1 Diagrama de Procesos (BPMN / Swimlanes simplificado)
Este diagrama muestra la interacción y los flujos de tareas entre el Comprador y el Vendedor durante el ciclo de compraventa.

```mermaid
graph TD
    subgraph Cliente_Comprador ["Comprador"]
        A[Explorar Catálogo de Hardware] --> B{¿Interesado en un item?}
        B -- Sí --> C[Contactar al Vendedor por WhatsApp]
        C --> D[Coordinar punto de encuentro seguro en FIEI]
        D --> E[Revisar estado físico/operativo del componente]
        E --> F{¿Operativo y Conforme?}
        F -- Sí --> G[Pagar vía Yape/Plin o Efectivo]
        F -- No --> H[Cancelar compra]
        G --> I[Fin de la Transacción]
    end
    subgraph Cliente_Vendedor ["Vendedor"]
        V1[Publicar Producto con fotos Base64 y Tips] --> V2[Esperar contacto]
        V2 --> V3[Responder chat y acordar cita en FIEI]
        V3 --> V4[Entregar componente físico]
        V4 --> V5[Recibir confirmación de pago]
        V5 --> V6[Marcar Producto como VENDIDO en la App]
    end
    V1 -.-> A
    C -.-> V2
    V3 -.-> D
    E -.-> V4
    G -.-> V5
    V6 --> I
```

---

### 1.2 Diagrama de Flujo de Transacciones
Muestra las etapas lógicas de una publicación desde su creación hasta su cierre.

```mermaid
flowchart TD
    Start([Inicio]) --> Pub[Vendedor publica producto: status = 'AVAILABLE']
    Pub --> View[Comprador ve listado en v_catalog]
    View --> Deal{¿Hay acuerdo en WhatsApp?}
    Deal -- No --> View
    Deal -- Sí --> Meet[Reunión física en FIEI: Patio, Cafetería, etc.]
    Meet --> Inspect{¿Inspección conforme?}
    Inspect -- No --> Cancel[Operación Cancelada] --> End([Fin])
    Inspect -- Sí --> Pay[Pago por Yape/Plin]
    Pay --> MarkSold[Vendedor marca status = 'SOLD' en la App]
    MarkSold --> End
```

---

### 1.3 Diagrama de Casos de Uso
Define el alcance de las acciones de cada actor (Comprador, Vendedor y Moderador/Administrador) en el sistema.

```mermaid
graph LR
    actor1((Comprador))
    actor2((Vendedor))
    actor3((Administrador))

    subgraph "Casos de Uso HardSwap FIEI"
        UC1(Registrarse / Iniciar Sesión con @unfv.edu.pe)
        UC2(Explorar catálogo de productos)
        UC3(Filtrar por categorías técnicas)
        UC4(Gestionar lista de Favoritos)
        UC5(Contactar vendedor por WhatsApp)
        UC6(Publicar componente electrónico o Kit)
        UC7(Gestionar publicaciones: CRUD)
        UC8(Marcar producto como vendido)
        UC9(Reportar publicación sospechosa)
        UC10(Moderar reportes y suspender usuarios)
    end

    actor1 --> UC1
    actor1 --> UC2
    actor1 --> UC3
    actor1 --> UC4
    actor1 --> UC5
    actor1 --> UC9

    actor2 --> UC1
    actor2 --> UC6
    actor2 --> UC7
    actor2 --> UC8

    actor3 --> UC10
    UC9 -.-> UC10
```

---

### 1.4 Diagrama de Actividades (Ciclo de Vida de una Publicación)
Muestra cómo evoluciona el estado del producto en base a disparadores manuales y automáticos.

```mermaid
stateDiagram-v2
    [*] --> AVAILABLE : Vendedor inserta publicación
    AVAILABLE --> RESERVED : Coordinación de entrega (opcional)
    RESERVED --> AVAILABLE : Cancelación de acuerdo
    AVAILABLE --> SOLD : Transacción exitosa (Vendedor marca como vendido)
    AVAILABLE --> EXPIRED : Pasan 14 días sin venta (expire_old_products)
    EXPIRED --> AVAILABLE : Vendedor renueva publicación (renovar fecha)
    SOLD --> [*]
    EXPIRED --> [*]
```

---

### 1.5 Diagrama de Secuencia — Autenticación Institucional (OAuth)
Muestra el flujo completo de inicio de sesión con Microsoft Entra ID, restricción al dominio `@unfv.edu.pe` y sincronización automática con la base de datos vía trigger.

```mermaid
sequenceDiagram
    actor Alumno
    participant App as App Flutter
    participant Supabase as Supabase Auth
    participant Microsoft as Microsoft Entra ID
    participant DB as PostgreSQL (public.users)

    Alumno->>App: Presiona "Iniciar sesión con Microsoft"
    App->>Supabase: signInWithOAuth(provider: azure)
    Supabase->>Microsoft: Redirige al portal de login UNFV
    Microsoft->>Alumno: Solicita credenciales @unfv.edu.pe
    Alumno->>Microsoft: Ingresa correo + contraseña institucional
    Microsoft-->>Supabase: JWT con email verificado @unfv.edu.pe
    Note over Supabase: Verifica dominio @unfv.edu.pe
    alt Dominio no permitido
        Supabase-->>App: Error: acceso denegado
        App-->>Alumno: "Solo usuarios UNFV pueden acceder"
    else Dominio valido
        Supabase->>DB: INSERT en auth.users
        DB->>DB: TRIGGER on_auth_user_created se ejecuta
        DB->>DB: INSERT en public.users (id, email, name, role='user')
        Supabase-->>App: Session token (JWT)
        App-->>Alumno: Redirige al catalogo de productos
    end
```

---

## 🗄️ 2. Modelado de Base de Datos (Sección 2.4)

### 2.0 Modelo Conceptual
Representa las entidades del negocio y sus relaciones desde una perspectiva abstracta, sin detalles técnicos de implementación.

```mermaid
erDiagram
    USUARIO {
        string Correo
        string Nombre
        string Rol
    }
    CATEGORIA {
        string Nombre
    }
    PRODUCTO {
        string Titulo
        string Descripcion
        number Precio
        string Estado
        string Tipo
    }
    COMPONENTE_KIT {
        string NombreComponente
        number Cantidad
    }
    FAVORITO {
        date FechaGuardado
    }
    REPORTE {
        string Motivo
        boolean Resuelto
    }
    AUDITORIA {
        string Accion
        string TituloAnterior
        string TituloNuevo
    }
    CALIFICACION {
        number Estrellas
        string Comentario
    }

    USUARIO ||--o{ PRODUCTO          : "publica"
    USUARIO ||--o{ FAVORITO          : "guarda"
    USUARIO ||--o{ REPORTE           : "reporta"
    USUARIO ||--o{ CALIFICACION      : "califica como comprador"
    USUARIO ||--o{ CALIFICACION      : "recibe como vendedor"
    CATEGORIA ||--o{ PRODUCTO        : "clasifica"
    PRODUCTO ||--o{ FAVORITO         : "es guardado en"
    PRODUCTO ||--o{ COMPONENTE_KIT   : "contiene"
    PRODUCTO ||--o{ REPORTE          : "es denunciado en"
    PRODUCTO ||--o{ AUDITORIA        : "registra cambios en"
    PRODUCTO ||--o{ CALIFICACION     : "origina"
```

---

### 2.1 Modelo Lógico (Diagrama Entidad-Relación - ERD)
Este diagrama representa las relaciones y campos estructurales configurados en la base de datos PostgreSQL de Supabase.

```mermaid
erDiagram
    users {
        uuid id PK
        text email UK
        text name
        text image
        text whatsapp_number
        boolean email_verified
        text role
        boolean verified_seller
        timestamptz created_at
        timestamptz updated_at
    }
    categories {
        uuid id PK
        text name UK
        text icon
        int sort_order
    }
    products {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        text title
        text description
        integer price
        text status
        text_array images_base64
        text model
        smallint condition
        text datasheet_url
        text tips
        text github_url
        text type
        text course_label
        integer renewal_count
        timestamptz created_at
        timestamptz updated_at
        timestamptz expires_at
    }
    kit_items {
        uuid id PK
        uuid kit_id FK
        text component_name
        integer quantity
        integer sort_order
    }
    favorites {
        uuid user_id PK,FK
        uuid product_id PK,FK
        timestamptz created_at
    }
    reports {
        uuid id PK
        uuid reporter_id FK
        uuid product_id FK
        text reason
        boolean resolved
        uuid resolved_by FK
        timestamptz resolved_at
        timestamptz created_at
    }
    seller_ratings {
        uuid id PK
        uuid seller_id FK
        uuid buyer_id FK
        uuid product_id FK
        smallint stars
        text comment
        timestamptz created_at
    }
    audit_products {
        integer audit_id PK
        uuid product_id FK
        text action
        text old_title
        text new_title
        integer old_price
        integer new_price
        uuid changed_by FK
        timestamptz changed_at
    }

    users ||--o{ products : "publica"
    users ||--o{ favorites : "guarda"
    users ||--o{ reports : "reporta (reporter_id)"
    users ||--o{ reports : "resuelve (resolved_by)"
    categories ||--o{ products : "clasifica"
    products ||--o{ favorites : "es_guardado_en"
    products ||--o{ kit_items : "contiene"
        products ||--o{ reports : "recibe_denuncia"
    users ||--o{ seller_ratings : "recibe calificación (seller_id)"
    users ||--o{ seller_ratings : "da calificación (buyer_id)"
    products ||--o{ seller_ratings : "origina"
    products ||--o{ audit_products : "audita"
    users ||--o{ audit_products : "realiza (changed_by)"
```

---

## 📱 3. Manual Básico de Usuario (Sección 6 — Entregables)

> Este manual describe cómo usar la app **La Cachina FIEI** desde el punto de vista de un estudiante.

### 3.1 Cómo registrarse
1. Abre la app en tu Android o en el navegador web.
2. Presiona el botón **"Iniciar sesión con Microsoft"**.
3. Ingresa tu correo institucional `@unfv.edu.pe` y contraseña.
4. Si tu cuenta es válida, se crea automáticamente tu perfil y entras al catálogo.

> **Importante:** Solo funcionan correos `@unfv.edu.pe`. Cuentas personales (Gmail, Hotmail) son rechazadas por el sistema.

### 3.2 Cómo comprar un componente
1. En la pantalla de **Catálogo**, usa la barra de búsqueda o los filtros de categoría para encontrar el componente que necesitas.
2. Toca la tarjeta del producto para ver los detalles: fotos, condición del componente (escala 1-10), datasheet, tips del vendedor.
3. Presiona el botón verde de **WhatsApp** para contactar directamente al vendedor con un mensaje preconfigurado.
4. Coordina el punto de entrega dentro del campus FIEI.
5. Revisa físicamente el componente antes de pagar.
6. Una vez recibido el componente, ve al detalle del producto y presiona **"Calificar vendedor"** para dejar tu opinión (1-5 estrellas).

### 3.3 Cómo vender un componente
1. Toca el ícono **"+"** en la barra de navegación inferior.
2. Rellena el formulario: título, categoría, descripción, precio (en soles), condición (1-10), modelo y photos del componente.
3. Opcionalmente, agrega el enlace al **Datasheet** y **Tips de conexión** para aumentar la confianza del comprador.
4. Presiona **"Publicar"** — el componente aparecerá en el catálogo para todos los estudiantes.
5. Cuando concretes la venta, busca tu publicación en **"Mis publicaciones"** y presiona **"Marcar como vendido"**.

> **Nota:** Las publicaciones expiran automáticamente a los **14 días** si no se marcan como vendidas. Puedes renovarlas desde "Mis publicaciones".

### 3.4 Cómo crear un Kit educativo
1. En el formulario de publicación, selecciona el tipo **"Kit"**.
2. Indica el curso de la FIEI al que está orientado.
3. Agrega los componentes que incluye el kit uno por uno.
4. El kit aparecerá con una etiqueta especial en el catálogo.

### 3.5 Cómo reportar una publicación
1. En el detalle del producto, presiona el ícono de **bandera** (reporte).
2. Selecciona el motivo del reporte.
3. El administrador recibirá la denuncia y la revisará.

---

## 🛠️ Herramientas para Modelamiento y Generación de Diagramas

Para incorporar estos diagramas de la manera más profesional posible en tu documento final de Word o PDF, puedes utilizar los siguientes métodos:

### 1. Generador Automático de Supabase (Schema Visualizer)
Supabase cuenta con una herramienta nativa para visualizar el modelo físico de tu base de datos:
1. Ingresa a tu **Supabase Dashboard**.
2. Dirígete a la pestaña **Database** (icono de base de datos en la barra lateral izquierda).
3. Selecciona la opción **Schema Visualizer**.
4. Te mostrará un diagrama interactivo con tus tablas (`users`, `products`, etc.), sus columnas y líneas de relación de llaves foráneas. Puedes tomarle captura directamente para tu informe del **Modelo Físico**.

### 2. dbdiagram.io (Para Modelo Lógico / Entidad-Relación)
Si quieres un diagrama de base de datos editable y estético a partir de tu script SQL:
1. Entra a [dbdiagram.io](https://dbdiagram.io/).
2. Copia y pega las sentencias `CREATE TABLE` de tu archivo `schema_completo.sql`.
3. La herramienta procesará el código y te generará automáticamente un diagrama de tablas interactivo con sus relaciones, el cual puedes exportar como imagen o PDF.

### 3. Mermaid Live Editor (Para BPMN, Casos de Uso y Flujo)
Para editar o descargar los diagramas definidos arriba:
1. Abre [mermaid.live](https://mermaid.live).
2. Copia el bloque de código del diagrama que desees (sin las comillas triples de markdown).
3. Pégalo en el panel izquierdo (code editor).
4. En el panel inferior derecho, haz clic en **Actions** y selecciona **Download PNG** o **Download SVG** para guardarlo en alta resolución.

### 4. Camunda Modeler o Draw.io
- Si tu profesor es muy exigente con la notación formal de **BPMN 2.0** (usando compuertas exclusivas, eventos de tiempo, subprocesos, etc.), te recomiendo importar o dibujar el proceso en [draw.io](https://app.diagrams.net/) (que tiene formas específicas para BPMN) o descargar [Camunda Modeler](https://camunda.com/download/modeler/) que es el estándar de modelado de procesos de negocio.
