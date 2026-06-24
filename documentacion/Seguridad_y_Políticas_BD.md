# 🛡️ Seguridad y Políticas RLS — Base de Datos "La Cachina"

Este documento contiene un resumen detallado y amigable de todas las medidas de seguridad, permisos y políticas de **Seguridad a Nivel de Fila (RLS)** configuradas en la base de datos de tu proyecto.

---

## 🔑 Conceptos Clave en la Seguridad

Para entender las reglas de la base de datos, primero debemos entender los **tres tipos de actores** que interactúan con ella:

| Actor | Descripción en el Sistema | Cómo lo identifica la base de datos |
| :--- | :--- | :--- |
| **Público (Anon/Cualquiera)** | Cualquier persona que abre la app (esté o no registrada). | `true` o políticas públicas sin restricciones. |
| **Propietario (Owner)** | El usuario específico que creó un registro (el dueño de una publicación o favorito). | Su ID de sesión (`auth.uid()`) coincide con la columna `user_id`. |
| **Administrador (Admin)** | Un usuario especial con permisos de moderador para auditar y borrar contenido inapropiado. | Un registro en la tabla `public.users` con `role = 'admin'`. |

---

## 📋 Resumen de Políticas RLS por Tabla

A continuación, se detalla qué puede hacer cada actor en las distintas tablas del sistema:

### 👤 Tabla: `public.users` (Perfiles de Usuario)
*Controla quién puede ver y modificar la información de perfil (nombres, teléfonos, etc).*

| Operación | Nombre de la Política | ¿Quién tiene acceso? | Condición SQL (`USING` / `WITH CHECK`) | Explicación sencilla |
| :---: | :--- | :---: | :--- | :--- |
| **SELECT** | `"users can read all profiles"` | **Público** 🔓 | `true` | Cualquiera puede ver los nombres y números de WhatsApp para poder contactar a los vendedores. |
| **UPDATE** | `"users can update own profile"`| **Dueño** 🔑 | `auth.uid() = id` | Solo tú puedes modificar tu propio perfil (foto, teléfono, etc.). |
| **INSERT** | *Manejado por Trigger* | **Sistema** 🤖 | *Trigger de Supabase Auth* | Los usuarios se crean automáticamente cuando se registran en Supabase. |
| **DELETE** | *Deshabilitado* 🚫 | **Nadie** | `false` | Las cuentas no se pueden borrar directamente por RLS para evitar pérdidas accidentales. |

---

### 📦 Tabla: `public.products` (Publicaciones / Kits)
*Controla quién vende, edita y elimina productos del marketplace.*

| Operación | Nombre de la Política | ¿Quién tiene acceso? | Condición SQL (`USING` / `WITH CHECK`) | Explicación sencilla |
| :---: | :--- | :---: | :--- | :--- |
| **SELECT** | `"catalog is public"` | **Público** 🔓 | `true` | Todos los visitantes de la app pueden ver el catálogo de productos disponibles. |
| **INSERT** | `"owners can insert products"` | **Dueño** 🔑 | `auth.uid() = user_id` | Solo puedes publicar productos si los asocias a tu propio ID de usuario autenticado. |
| **UPDATE** | `"owners can update products"` | **Dueño** 🔑 | `auth.uid() = user_id` | Solo tú puedes cambiar el precio, título o fotos de tus productos. |
| **DELETE** | `"owners can delete products"` | **Dueño** 🔑 | `auth.uid() = user_id` | Solo tú puedes retirar o eliminar tu publicación de la app. |
| **ALL** | `"admins can do anything on products"`| **Admin** 👑 | `EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')` | Los administradores pueden editar o eliminar cualquier producto de cualquier usuario (para moderación). |

---

### ⭐ Tabla: `public.favorites` (Favoritos)
*Asegura la privacidad de los productos que cada usuario guarda.*

| Operación | Nombre de la Política | ¿Quién tiene acceso? | Condición SQL | Explicación sencilla |
| :---: | :--- | :---: | :--- | :--- |
| **ALL** | `"users can manage own favorites"`| **Dueño** 🔑 | `auth.uid() = user_id` | Solo tú puedes ver tu lista de favoritos, añadir nuevos favoritos o eliminarlos. Nadie más tiene acceso. |

---

### 🔌 Tabla: `public.kit_items` (Componentes de Kits)
*Garantiza la consistencia al armar conjuntos de herramientas o piezas.*

| Operación | Nombre de la Política | ¿Quién tiene acceso? | Condición SQL | Explicación sencilla |
| :---: | :--- | :---: | :--- | :--- |
| **SELECT** | `"kit_items readable by all"` | **Público** 🔓 | `true` | Todos pueden ver el contenido de los kits de componentes electrónicos. |
| **ALL** | `"owners manage kit items"` | **Dueño** 🔑 | `EXISTS (SELECT 1 FROM products WHERE id = kit_id AND user_id = auth.uid())` | Solo puedes agregar, editar o quitar componentes de un kit si tú eres el dueño del producto base (`kit_id`). |

---

### 🚨 Tabla: `public.reports` (Reportes de Moderación)
*Maneja las denuncias sobre publicaciones inapropiadas o estafas.*

| Operación | Nombre de la Política | ¿Quién tiene acceso? | Condición SQL | Explicación sencilla |
| :---: | :--- | :---: | :--- | :--- |
| **INSERT** | `"users create reports"` | **Dueño** 🔑 | `auth.uid() = reporter_id` | Cualquier usuario logueado puede crear un reporte de denuncia, pero debe estar firmado por él mismo. |
| **SELECT** | `"admins read reports"` | **Admin** 👑 | `EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')` | Solo los moderadores/administradores pueden ver la lista de denuncias activas en la app. |
| **UPDATE** | `"admins update reports"` | **Admin** 👑 | `EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')` | Solo los administradores pueden marcar un reporte como "Resuelto". |

---

## 🔍 Consultas SQL para Auditar RLS en Supabase

Si estás en el **SQL Editor de Supabase** y quieres comprobar el estado de la seguridad de tu base de datos, puedes ejecutar las siguientes consultas:

### 1. Ver qué tablas tienen RLS activo
Esta consulta te mostrará si las tablas tienen activada la seguridad de fila (debe decir `true` en `rowsecurity`):
```sql
SELECT 
  schemaname, 
  tablename, 
  rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### 2. Listar todas las políticas activas
Esta consulta te dará la lista exacta de políticas creadas en la base de datos, indicando a qué tabla pertenecen y qué comando SQL las rige:
```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual::text as using_expression,
  with_check::text as with_check_expression
FROM pg_policies
WHERE schemaname = 'public';
```
