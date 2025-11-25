!ifndef PRODUCT_NAME
!define PRODUCT_NAME "Smart Gamma"
!endif
!ifndef PRODUCT_VERSION
!define PRODUCT_VERSION "0.0.0.0"
!endif
!ifndef SOURCE_ROOT
!define SOURCE_ROOT "..\dist\windows-x64\smart-gamma"
!endif
!ifndef OUTPUT_EXE
!define OUTPUT_EXE "..\dist\smart-gamma-windows.exe"
!endif
!ifndef INSTALL_ROOT
!define INSTALL_ROOT "$PROGRAMDATA\obs-studio\plugins"
!endif
!ifndef INSTALL_SUBDIR
!define INSTALL_SUBDIR "smart-gamma"
!endif

Unicode true
RequestExecutionLevel user

OutFile "${OUTPUT_EXE}"
InstallDir "${INSTALL_ROOT}\${INSTALL_SUBDIR}"
InstallDirRegKey HKCU "Software\${PRODUCT_NAME}" "InstallDir"

VIProductVersion "${PRODUCT_VERSION}"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "CompanyName" "Smart Gamma"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} OBS plug-in"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"

!include "MUI2.nsh"

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_ROOT}\*.*"
  WriteRegStr HKCU "Software\${PRODUCT_NAME}" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall ${PRODUCT_NAME}.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\Uninstall ${PRODUCT_NAME}.exe"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\${PRODUCT_NAME}"
SectionEnd
