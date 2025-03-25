# SAGE - Plataforma de Scripts Colaborativos

SAGE es una aplicación completa desarrollada en Flutter diseñada para gestionar, ejecutar y compartir scripts en un entorno colaborativo y seguro. Cuenta con autenticación de doble factor, ejecución de scripts, gestión de usuarios y un chatbot integrado potenciado por la IA DeepSeek.

![Logo de SAGE](https://via.placeholder.com/200x200)

## 🌟 Características

### Autenticación y Seguridad
- Autenticación de doble factor (TOTP) con integración de códigos QR
- Inicio de sesión seguro con nombre de usuario/contraseña + verificación TOTP
- Registro de usuarios con sistema de aprobación para nuevas cuentas
- Cambio de tema claro/oscuro y cambio de idioma (Inglés/Español)

### Gestión de Scripts
- Subir, descargar y ejecutar scripts de Python (.py) y PowerShell (.ps1)
- Editor de código integrado con resaltado de sintaxis
- Seguimiento de ejecución de scripts e historial
- Verificación de seguridad de scripts para detectar comandos potencialmente peligrosos

### Gestión de Usuarios (Admin)
- Sistema de aprobación de usuarios
- Gestión de roles (administrador/usuario)
- Capacidades de eliminación de usuarios
- Vista general de estadísticas del sistema

### Herramientas y Utilidades
- Chatbot potenciado por la IA DeepSeek para asistencia en programación
- Registros de ejecución e historial
- Funcionalidad de exportación para registros y scripts
- Estadísticas completas para scripts (recuento de ejecuciones, descargas, etc.)

## 📱 Capturas de pantalla

| Pantalla de Inicio | Panel de Scripts | Chatbot |
|-------------|-----------------|---------|
| ![Login](https://via.placeholder.com/250x500) | ![Scripts](https://via.placeholder.com/250x500) | ![Chatbot](https://via.placeholder.com/250x500) |

## 🛠️ Tecnologías

- **Flutter**: Framework multiplataforma para UI
- **Provider**: Gestión de estado
- **MySQL**: Base de datos backend
- **Ollama**: Integración de IA (modelo DeepSeek)
- **TOTP**: Autenticación de dos factores
- **QR Flutter**: Generación de códigos QR para 2FA

## ⚙️ Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tuusuario/flutter_scripts.git
   cd flutter_scripts
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar la conexión a la base de datos**
   - Abre el archivo `lib/services/database_service.dart`
   - Modifica las siguientes líneas con tus propios datos de conexión:
     ```dart
     final ConnectionSettings _settings = ConnectionSettings(
       host: 'tu_servidor_mysql',
       port: 3306,
       user: 'tu_usuario',
       password: 'tu_contraseña',
       db: 'nombre_de_base_de_datos',
     );
     ```
   - Asegúrate de que MySQL esté ejecutándose con los permisos necesarios

4. **Configurar Ollama (para el chatbot IA)**
   - Instala Ollama: [https://ollama.ai/](https://ollama.ai/)
   - Descarga el modelo DeepSeek Coder:
     ```bash
     ollama pull deepseek-coder:1.3b
     ```
   - Asegúrate de que Ollama esté ejecutándose en `localhost:11434`

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🔐 Primer inicio de sesión

La aplicación crea automáticamente un usuario administrador predeterminado durante la primera ejecución. Revisa el código en `database_service.dart` para ver los detalles de este usuario inicial.

Una vez que hayas iniciado sesión, deberás escanear el código QR TOTP con Google Authenticator o una aplicación similar.

## 🗂️ Estructura del Proyecto

- **auth/**: Pantallas relacionadas con la autenticación (inicio de sesión, registro)
- **models/**: Modelos de datos para scripts, usuarios, etc.
- **screens/**: Pantallas principales de la aplicación
- **services/**: Servicios de backend (autenticación, base de datos, ejecución de scripts)
- **utils/**: Clases de utilidad (localización, temas)
- **widgets/**: Componentes de UI reutilizables

## 🚀 Uso

### Gestión de Scripts
1. Inicia sesión usando tus credenciales + código TOTP
2. Navega a la pestaña Scripts
3. Sube, selecciona o crea un script
4. Edita scripts en el editor integrado
5. Ejecuta scripts y visualiza la salida en la ventana de terminal
6. Descarga scripts para uso offline

### Gestión de Usuarios (solo Admin)
1. Navega a la pestaña Admin
2. Aprueba nuevos registros de usuarios
3. Cambia los roles de usuario entre administrador y usuario regular
4. Elimina usuarios si es necesario

### Chatbot IA
1. Navega a la pestaña Chatbot
2. Haz preguntas relacionadas con programación
3. La IA DeepSeek proporcionará respuestas y asistencia con el código

## 🔒 Consideraciones de Seguridad

- La aplicación utiliza SHA-256 para el hash de contraseñas
- La verificación TOTP proporciona una capa adicional de seguridad
- Los scripts son verificados para detectar comandos potencialmente peligrosos antes de la ejecución
- El sistema de aprobación de administrador evita el acceso no autorizado

## 🌐 Localización

La aplicación soporta los idiomas inglés y español. Puedes alternar entre ellos usando el botón de idioma en la esquina superior derecha de la aplicación.

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Por favor, siéntete libre de enviar un Pull Request.

1. Haz un fork del repositorio
2. Crea tu rama de funcionalidad (`git checkout -b feature/nueva-funcionalidad`)
3. Haz commit de tus cambios (`git commit -m 'Añadir alguna nueva funcionalidad'`)
4. Haz push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles.

## 👨‍💻 Autores

- **Pedro Miguel** & **Eloy Ramirez Revuelta**

---

Hecho con ❤️ usando Flutter
