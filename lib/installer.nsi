; Script generado por el asistente NSIS Modern UI
!include "MUI2.nsh"

; Información de la aplicación
!define APPNAME "Scripts Colaborativos"
!define COMPANYNAME "Tu Compañía"
!define DESCRIPTION "Plataforma de Scripts Colaborativos"
!define VERSION "1.0.0"
!define COPYRIGHT "© 2025 Tu Compañía"
!define INSTALLER_NAME "ScriptsColaborativos-Setup.exe"
!define MAIN_APP_EXE "flutter_scripts.exe"
!define INSTALL_DIR "$PROGRAMFILES64\${APPNAME}"
!define FLUTTER_BUILD_DIR "..\build\windows\x64\Release\runner"

; Configuración básica
Name "${APPNAME}"
OutFile "${INSTALLER_NAME}"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKLM "Software\${APPNAME}" ""
RequestExecutionLevel admin

; Configuración del aspecto visual
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${MAIN_APP_EXE}"

; Páginas del instalador
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Páginas de desinstalación
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Idioma
!insertmacro MUI_LANGUAGE "Spanish"

; Sección principal de instalación
Section "!${APPNAME}" SecMain
  SectionIn RO
  
  ; Establece la carpeta de salida
  SetOutPath "$INSTDIR"
  
  ; Incluye todos los archivos de la aplicación
  File /r "${FLUTTER_BUILD_DIR}\*.*"
  
  ; Crea accesos directos
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\Desinstalar.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
  
  ; Escribe la información de desinstalación
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\${MAIN_APP_EXE}$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
  
  ; Crea desinstalador
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

; Sección para crear acceso directo en el inicio (opcional)
Section "Iniciar con Windows" SecStartup
  CreateShortcut "$SMSTARTUP\${APPNAME}.lnk" "$INSTDIR\${MAIN_APP_EXE}"
SectionEnd

; Descripciones de secciones
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "Instala ${APPNAME} en tu sistema."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartup} "Inicia ${APPNAME} automáticamente cuando inicias Windows."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Sección de desinstalación
Section "Uninstall"
  ; Elimina archivos y carpetas
  RMDir /r "$INSTDIR"
  
  ; Elimina accesos directos
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\Desinstalar.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"
  Delete "$SMSTARTUP\${APPNAME}.lnk"
  
  ; Elimina información del registro
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
  DeleteRegKey HKLM "Software\${APPNAME}"
SectionEnd