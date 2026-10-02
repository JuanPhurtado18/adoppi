# Adoppi

### Plataforma móvil para la adopción responsable de mascotas

Adoppi es una aplicación móvil desarrollada con **Flutter y Dart** que busca facilitar y centralizar el proceso de adopción responsable de mascotas, conectando **personas interesadas en adoptar** con **refugios y organizaciones de protección animal**.

El proyecto nace como una iniciativa de desarrollo de software enfocada en brindar mayor visibilidad a los animales que necesitan un hogar y mejorar la comunicación entre adoptantes y refugios.

> **Adoppi — Encuentra tu compañero perfecto. **

---

## Sobre el proyecto

Actualmente, muchos refugios y fundaciones publican información sobre mascotas disponibles para adopción a través de redes sociales, grupos y diferentes plataformas, lo que dificulta encontrar información centralizada y actualizada.

Adoppi propone una plataforma especializada donde los usuarios pueden:

* Explorar mascotas disponibles para adopción.
* Buscar y filtrar mascotas según diferentes características.
* Consultar información detallada de cada mascota.
* Conocer los refugios responsables.
* Consultar la ubicación de los refugios.
* Comunicarse directamente con los refugios.
* Gestionar su perfil.
* Recibir notificaciones relacionadas con el proceso de adopción.

Por su parte, los refugios cuentan con herramientas para administrar su información y gestionar las mascotas publicadas.

---

## Objetivo

Desarrollar una plataforma móvil que facilite la adopción responsable de mascotas mediante un espacio digital centralizado que permita conectar refugios con posibles adoptantes.

El proyecto busca mejorar la visibilidad de las mascotas disponibles y facilitar el acceso a información relevante antes de iniciar un proceso de adopción.

---

## Funcionalidades

###  Usuarios

* Registro de usuarios.
* Inicio de sesión.
* Recuperación de contraseña.
* Gestión del perfil.
* Configuración de cuenta.
* Consulta de mascotas disponibles.
* Búsqueda y filtrado de mascotas.
* Consulta de información detallada.
* Consulta de refugios.
* Comunicación mediante chat.
* Recepción de notificaciones.

### Mascotas

Cada mascota puede contar con información como:

* Nombre.
* Edad.
* Raza.
* Sexo.
* Tamaño.
* Fotografías.
* Descripción.
* Estado de salud.
* Información de vacunación.
* Historia.
* Estado de adopción.
* Refugio responsable.

### Refugios

Los refugios cuentan con funcionalidades para:

* Gestionar su perfil.
* Administrar información del refugio.
* Publicar mascotas.
* Editar mascotas.
* Eliminar mascotas.
* Gestionar la información relacionada con sus mascotas.
* Comunicarse con posibles adoptantes.

### Búsqueda y filtros

La aplicación contempla filtros para facilitar la búsqueda de mascotas según características como:

* Tipo de mascota.
* Edad.
* Tamaño.
* Sexo.
* Estado de vacunación.
* Compatibilidad con niños.
* Estado de adopción.

### Geolocalización

Adoppi contempla la visualización de refugios mediante mapas, permitiendo consultar sus ubicaciones y facilitar el acceso a información relacionada con ellos.

### Chat

La aplicación incorpora un sistema de mensajería para facilitar la comunicación entre usuarios y refugios y permitir consultas relacionadas con la adopción.

### Notificaciones

El sistema utiliza notificaciones para informar sobre eventos relevantes de la aplicación, como nuevos mensajes y otras actualizaciones relacionadas con el proceso de adopción.

---

## Tecnologías utilizadas

| Tecnología                   | Uso                                           |
| ---------------------------- | --------------------------------------------- |
| **Flutter**                  | Desarrollo de la aplicación móvil             |
| **Dart**                     | Lenguaje de programación                      |
| **Riverpod**                 | Gestión del estado                            |
| **GoRouter**                 | Navegación y manejo de rutas                  |
| **Supabase**                 | Autenticación, base de datos y almacenamiento |
| **Firebase Cloud Messaging** | Sistema de notificaciones push                |
| **Figma**                    | Diseño y prototipado de interfaces            |
| **Git / GitHub**             | Control de versiones                          |

La integración de Supabase se realiza mediante `supabase_flutter`, mientras que Firebase se utiliza principalmente para la infraestructura de notificaciones mediante Firebase Cloud Messaging.

---

## Arquitectura

El proyecto está organizado siguiendo una separación por funcionalidades y responsabilidades dentro de la aplicación.

Entre las principales áreas se encuentran:

```text
lib/
├── core/
│   ├── router/
│   └── theme/
│
├── features/
│   ├── auth/
│   ├── splash/
│   ├── home/
│   ├── shelter_panel/
│   ├── chat/
│   ├── notifications/
│   └── admin/
│
└── main.dart
```

La aplicación utiliza **Riverpod** para la gestión del estado y **GoRouter** para controlar la navegación y el acceso a las diferentes áreas de la aplicación.

---

##  Autenticación y roles

La autenticación de usuarios se gestiona mediante **Supabase Auth**.

Adoppi contempla diferentes tipos de usuario y permisos dentro de la aplicación:

* **Adoptante:** puede explorar mascotas, consultar refugios y comunicarse con ellos.
* **Refugio:** dispone de herramientas para administrar su perfil y las mascotas disponibles.
* **Administrador:** cuenta con funcionalidades administrativas adicionales.

La información complementaria de los usuarios se gestiona mediante perfiles almacenados en la base de datos.

También se contemplan mecanismos relacionados con:

* Estado de bloqueo de usuarios.
* Gestión de sesiones.
* Roles.
* Recuperación de contraseña.
* Tokens para notificaciones push.

---

## Backend

Adoppi utiliza **Supabase** como plataforma backend.

Entre los recursos utilizados se encuentran:

* **Supabase Auth** para autenticación.
* **PostgreSQL** para almacenamiento de información.
* **Supabase Storage** para archivos e imágenes.
* Perfiles de usuarios.
* Información de refugios.
* Información de mascotas.

La aplicación utiliza además **Firebase Cloud Messaging (FCM)** para la gestión de notificaciones push.

---

## Diseño UX/UI

El diseño de Adoppi está orientado a una experiencia móvil sencilla, moderna e intuitiva.

La guía visual del proyecto contempla:

* Color principal: **Morado `#7C3AED`**
* Diseño mobile-first.
* Tarjetas con esquinas redondeadas.
* Botones con bordes redondeados.
* Tipografía sans-serif.
* Navegación sencilla.
* Iconografía amigable y consistente.

El diseño y prototipado de las interfaces se realizó utilizando **Figma**.

---

## Pantallas principales

El proyecto contempla diferentes pantallas y módulos, entre ellos:

* Splash Screen.
* Inicio de sesión.
* Registro.
* Recuperación de contraseña.
* Home.
* Catálogo de mascotas.
* Perfil detallado de mascota.
* Refugios.
* Mapa de refugios.
* Perfil del refugio.
* Chat.
* Notificaciones.
* Perfil de usuario.
* Configuración.
* Panel de refugio.
* Panel administrativo.

---

## Instalación

### Requisitos

Antes de ejecutar el proyecto es necesario tener instalado:

* [Flutter](https://flutter.dev/)
* Dart SDK
* Android Studio o un entorno compatible.
* Git
* Un dispositivo Android/iOS o un emulador.

### 1. Clonar el repositorio

```bash
git clone https://github.com/JuanPhurtado18/adoppi.git
```

Entrar al proyecto:

```bash
cd adoppi
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar variables de entorno

El proyecto utiliza variables de configuración para conectarse con los servicios externos.

Crear el archivo:

```text
.env
```

y configurar las variables requeridas por la aplicación.

> **Importante:** no subir credenciales, claves privadas ni archivos `.env` al repositorio.

### 4. Ejecutar la aplicación

```bash
flutter run
```

Para comprobar los dispositivos disponibles:

```bash
flutter devices
```

---

##  Generar APK

Para generar una versión release para Android:

```bash
flutter build apk --release
```

El APK generado puede encontrarse normalmente en:

```text
build/app/outputs/flutter-apk/app-release.apk
```


Una plataforma creada para facilitar la conexión entre personas, refugios y mascotas que buscan un hogar.
