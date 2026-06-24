# 🛒 Guía de Instalación y Ejecución — La Cachina de FIEI (HardSwap)

> Esta guía está pensada para personas que **nunca han programado**. Sigue cada paso con calma, en orden, y el proyecto funcionará sin problemas.

---

## 📦 Paso 1 — Descomprimir el archivo

Primero necesitas descomprimir el archivo `la-cachina-fiei.tar.gz` que recibiste.

### 🪟 Windows
Windows 11 puede abrir archivos `.tar.gz` directamente desde el Explorador de archivos.

**Opción A — Explorador de archivos (Windows 11):**
1. Haz **doble clic** sobre `la-cachina-fiei.tar.gz`.
2. Dentro verás la carpeta `la-cachina-fiei`, arrástrala a `C:\Proyectos\` o donde prefieras.

**Opción B — Con 7-Zip (recomendado para Windows 10):**
1. Descarga e instala **7-Zip** desde: **https://www.7-zip.org/**
2. Haz **clic derecho** sobre `la-cachina-fiei.tar.gz` → **7-Zip → Extraer aquí**.

**Opción C — WinRAR:**
1. Haz **clic derecho** sobre `la-cachina-fiei.tar.gz` → **Extraer aquí**.

Resultado: tendrás una carpeta `la-cachina-fiei` con todos los archivos del proyecto.

### 🐧 Linux
Abre una terminal y ejecuta:
```bash
tar -xzf la-cachina-fiei.tar.gz -C ~/Proyectos/
```
Esto creará `~/Proyectos/la-cachina-fiei/`.

---

## 🛠️ Paso 2 — Instalar Node.js

El proyecto usa **Node.js** (versión 20 o superior). Es el motor que hace funcionar todo.

### 🪟 Windows
1. Ve a: **https://nodejs.org/es/**
2. Descarga el instalador de la versión **LTS** (La que dice "Recomendado para la mayoría").
3. Ejecuta el instalador `.msi` y acepta todo con **"Siguiente / Next"** hasta que termine.
4. Cuando termine, **reinicia la computadora** por si acaso.
5. Para verificar que se instaló bien, abre **"Símbolo del sistema"** (busca `cmd` en el menú Inicio) y escribe:
   ```
   node --version
   npm --version
   ```
   Deberías ver algo como `v20.x.x` y `10.x.x`.

### 🐧 Linux (Arch / Manjaro)
```bash
sudo pacman -S nodejs npm
```

### 🐧 Linux (Ubuntu / Debian / Linux Mint)
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Verifica la instalación:
```bash
node --version
npm --version
```

---

## 📁 Paso 3 — Entrar a la carpeta del proyecto

Necesitas abrir una terminal **dentro** de la carpeta del proyecto.

### 🪟 Windows
**Opción fácil:** Ve al Explorador de archivos, entra a la carpeta `la-cachina-fiei`, haz clic en la barra de direcciones (donde dice la ruta), escribe `cmd` y presiona Enter. Se abrirá la terminal ya en esa carpeta.

**Alternativa:** Abre el Símbolo del sistema y escribe (ajusta la ruta según donde extrajiste):
```cmd
cd C:\Proyectos\la-cachina-fiei
```

### 🐧 Linux
```bash
cd ~/Proyectos/la-cachina-fiei
```

> 💡 **Tip:** Puedes arrastrar la carpeta al terminal para que se autocomplete la ruta automáticamente.

---

## 📝 Paso 4 — Crear el archivo de configuración (.env)

El proyecto necesita un archivo especial llamado `.env` con las claves de acceso a la base de datos y otros servicios. **Este archivo no viene en el ZIP por seguridad** — hay que crearlo a mano.

### 🪟 Windows
1. Abre el **Bloc de notas** (Notepad). *(Búscalo en el menú Inicio)*
2. Copia y pega **exactamente** el siguiente contenido:

```
DATABASE_URL="postgres://postgres:TU_CONTRASEÑA@db.TU_PROYECTO.supabase.co:5432/postgres"

AZURE_AD_CLIENT_ID="TU_CLIENT_ID"
AZURE_AD_CLIENT_SECRET="TU_CLIENT_SECRET"
AZURE_AD_TENANT_ID="TU_TENANT_ID"

NEXT_PUBLIC_R2_URL="https://TU_ACCOUNT_ID.r2.cloudflarestorage.com/fiei"
R2_ACCESS_KEY_ID="TU_ACCESS_KEY_ID"
R2_SECRET_ACCESS_KEY="TU_SECRET_ACCESS_KEY"

AUTH_SECRET="TU_AUTH_SECRET_GENERADO"
```

3. Ve a **Archivo → Guardar como...**
4. Navega hasta la carpeta `la-cachina-fiei`.
5. En **"Nombre de archivo"** escribe exactamente: `.env`
6. En **"Tipo"** selecciona **"Todos los archivos (*.*)"** ⚠️ ¡Importante! Si no haces esto, se guardará como `.env.txt` y no funcionará.
7. Haz clic en **Guardar**.

Para verificar que quedó bien: abre el Explorador, ve a la carpeta, activa **"Mostrar archivos ocultos"** (Ver → Mostrar → Elementos ocultos) y deberías ver el archivo `.env`.

### 🐧 Linux
Con la terminal dentro de la carpeta del proyecto, ejecuta:
```bash
cat > .env << 'EOF'
DATABASE_URL="postgres://postgres:TU_CONTRASEÑA@db.TU_PROYECTO.supabase.co:5432/postgres"

AZURE_AD_CLIENT_ID="TU_CLIENT_ID"
AZURE_AD_CLIENT_SECRET="TU_CLIENT_SECRET"
AZURE_AD_TENANT_ID="TU_TENANT_ID"

NEXT_PUBLIC_R2_URL="https://TU_ACCOUNT_ID.r2.cloudflarestorage.com/fiei"
R2_ACCESS_KEY_ID="TU_ACCESS_KEY_ID"
R2_SECRET_ACCESS_KEY="TU_SECRET_ACCESS_KEY"

AUTH_SECRET="TU_AUTH_SECRET_GENERADO"
EOF
```

---

## 📦 Paso 5 — Instalar los módulos del proyecto

Ahora instalarás todas las librerías que el proyecto necesita. Solo se hace **una vez**.

Con la terminal dentro de la carpeta `la-cachina-fiei`, ejecuta:

```bash
npm install
```

> ⏳ Esto puede tardar entre **2 y 5 minutos** dependiendo de tu conexión a internet. Verás muchos mensajes en pantalla, eso es normal. Espera a que diga que terminó.

Cuando termine verás algo como:
```
added 847 packages in 3m
```

---

## 🗄️ Paso 6 — Generar el cliente de base de datos

El proyecto usa Prisma para conectarse a la base de datos. Ejecuta este comando una sola vez:

```bash
npx prisma generate
```

Verás un mensaje que dice `✔ Generated Prisma Client`. ¡Eso significa que funcionó!

---

## 🚀 Paso 7 — ¡Ejecutar el proyecto!

¡Ya está todo listo! Para iniciar el servidor de desarrollo:

```bash
npm run dev
```

Verás algo como esto en la terminal:
```
  ▲ Next.js 16.2.3
  - Local:        http://localhost:3000

 ✓ Starting...
 ✓ Ready in 2.1s
```

Ahora abre tu **navegador web** (Chrome, Firefox, Edge, etc.) y ve a:

**👉 http://localhost:3000**

¡El proyecto está corriendo! 🎉

> ℹ️ Necesitas internet para que el login con Microsoft funcione y para cargar imágenes, ya que la base de datos y el almacenamiento están en la nube.

---

## ⏹️ Cómo detener el servidor

Para apagar el servidor, ve a la terminal donde está corriendo y presiona:

```
Ctrl + C
```

---

## 🔁 Cómo volver a ejecutarlo en el futuro

La próxima vez que quieras correr el proyecto, solo necesitas:

1. Abrir la terminal.
2. Entrar a la carpeta del proyecto:
   - **Windows:** `cd C:\Proyectos\la-cachina-fiei`
   - **Linux:** `cd ~/Proyectos/la-cachina-fiei`
3. Ejecutar: `npm run dev`
4. Abrir el navegador en **http://localhost:3000**

Los pasos de instalación (npm install, prisma generate) **solo se hacen una vez**.

---

## ❓ Problemas comunes

| Problema | Solución |
|---|---|
| `npm` no se reconoce como comando | Node.js no está instalado. Repite el Paso 2 y reinicia el PC. |
| `Cannot find module` | Ejecuta `npm install` de nuevo (Paso 5). |
| El navegador muestra "Esta web no está disponible" | Asegúrate de que el servidor esté corriendo (`npm run dev`) y usa exactamente `http://localhost:3000`. |
| Error sobre `.env` o variables de entorno | Verifica que creaste el archivo `.env` correctamente en el Paso 4 y que está dentro de la carpeta `la-cachina-fiei`. |
| Puerto 3000 en uso | Cierra otras aplicaciones o reinicia la computadora. |
| Error de Prisma / base de datos | Verifica que tienes internet activo y que el `DATABASE_URL` en el `.env` está correcto. |

---

## 🧰 ¿Qué tecnologías usa el proyecto?

| Tecnología | Para qué sirve |
|---|---|
| **Node.js v20+** | Motor de ejecución de JavaScript (como el motor de un carro) |
| **npm** | Gestor de módulos/librerías (instala todo lo necesario) |
| **Next.js 16** | Framework web principal (frontend + backend) |
| **React 19** | Librería para crear la interfaz visual |
| **TypeScript** | JavaScript mejorado con detección de errores |
| **Prisma** | Herramienta para comunicarse con la base de datos |
| **PostgreSQL** | Base de datos (alojada en Supabase, en la nube ☁️) |
| **Tailwind CSS** | Sistema de estilos visuales |
| **NextAuth v5** | Sistema de autenticación (login con cuenta Microsoft) |
| **Cloudflare R2** | Almacenamiento de imágenes en la nube ☁️ |

> 📌 **Importante:** La base de datos y el almacenamiento de imágenes están **en la nube** — no necesitas instalar PostgreSQL ni nada extra. Solo necesitas **Node.js** y **conexión a internet**.

---

*Guía creada para el proyecto La Cachina de FIEI — HardSwap*
