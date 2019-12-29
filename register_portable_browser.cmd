@echo off & setlocal enabledelayedexpansion
rem Inspired by:
rem   https://kolbi.cz/blog/2019/01/27/register-a-portable-browser-and-make-it-the-default/
rem   https://docs.microsoft.com/en-us/windows/desktop/shell/start-menu-reg

rem ================== POSSIBLE ARGS
rem --nopause = doesn't pause
rem --noconfirm = doesn't ask for confirmation

rem --name "BrowserName" = browser name
rem --path "c:\browser\path.exe" = browser path

rem --defall = use all possible default values
rem --defdescription = use default browser description
rem --deffileextensions = use default browser supported extensions
rem --defprotocols = use default browser supported protocols

rem --description "browse the web" = browser description
rem --fileextensions "html htm" = browser supported extensions
rem --protocols "http https" = browser supported protocols


rem ================== VARIABLES
set "DEFAULT_DESCRIPTION=Browse the interweb network"
set "DEFAULT_FILEEXTENSIONS=html htm pdf"
set "DEFAULT_PROTOCOLS=http https mailto ftp"

set "FILE_CLASS_SUFFIX=File"
set "HANDLER_SUFFIX=Handler"

rem ================== SETUP
:parseArgs
if "%~1" EQU "--nopause" (
	set NOPAUSE=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--noconfirm" (
	set NOCONFIRM=1
	shift
	goto :parseArgs
)
if "%~1" EQU "--name" (
	set "ARGDEFAULT_BROWSERNAME=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--path" (
	set "ARGDEFAULT_BROWSERPATH=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--defall" (
	set "ARGDEFAULT_DESCRIPTION=%DEFAULT_DESCRIPTION%"
	set "ARGDEFAULT_FILEEXTENSIONS=%DEFAULT_FILEEXTENSIONS%"
	set "ARGDEFAULT_PROTOCOLS=%DEFAULT_PROTOCOLS%"
	shift
	goto :parseArgs
)
if "%~1" EQU "--defdescription" (
	set "ARGDEFAULT_DESCRIPTION=%DEFAULT_DESCRIPTION%"
	shift
	goto :parseArgs
)
if "%~1" EQU "--deffileextensions" (
	set "ARGDEFAULT_FILEEXTENSIONS=%DEFAULT_FILEEXTENSIONS%"
	shift
	goto :parseArgs
)
if "%~1" EQU "--defprotocols" (
	set "ARGDEFAULT_PROTOCOLS=%DEFAULT_PROTOCOLS%"
	shift
	goto :parseArgs
)
if "%~1" EQU "--description" (
	set "ARGDEFAULT_DESCRIPTION=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--fileextensions" (
	set "ARGDEFAULT_FILEEXTENSIONS=%~2"
	shift
	shift
	goto :parseArgs
)
if "%~1" EQU "--protocols" (
	set "ARGDEFAULT_PROTOCOLS=%~2"
	shift
	shift
	goto :parseArgs
)


if defined ARGDEFAULT_BROWSERNAME (set "bname=%ARGDEFAULT_BROWSERNAME%") ELSE (set /p "bname=define browser name (avoid spaces and special characters) (eg BravePortable): ")
if defined ARGDEFAULT_BROWSERPATH (set "bpath=%ARGDEFAULT_BROWSERPATH%") ELSE (set /p "bpath=define browser path (eg z:\programs\braveportable\brave-portable.exe): ")
if defined ARGDEFAULT_DESCRIPTION (set "bdescription=%ARGDEFAULT_DESCRIPTION%") ELSE (
	set /p "bdescription=define browser description (eg Browse the interweb network) (leave empty for default: %DEFAULT_DESCRIPTION%): "
)
if not defined bdescription set "bdescription=%DEFAULT_DESCRIPTION%"
if defined ARGDEFAULT_FILEEXTENSIONS (set "bfileextensions=%ARGDEFAULT_FILEEXTENSIONS%") ELSE (
	set /p "bfileextensions=define browser supported files extensions (separated by spaces) (eg html htm pdf) (leave empty for default: %DEFAULT_FILEEXTENSIONS%): "
)
if not defined bfileextensions set "bfileextensions=%DEFAULT_FILEEXTENSIONS%"
if defined ARGDEFAULT_PROTOCOLS (set "bprotocols=%ARGDEFAULT_PROTOCOLS%") ELSE (
	set /p "bprotocols=define browser supported protocols (separated by spaces) (eg http https) (leave empty for default: %DEFAULT_PROTOCOLS%): "
)
if not defined bprotocols set "bprotocols=%DEFAULT_PROTOCOLS%"

set "bname=%bname: =%"
set "bfileclass=%bname%%FILE_CLASS_SUFFIX%"
set "bhandler=%bname%%HANDLER_SUFFIX%"

echo.
echo ==================
echo.
echo browser name: %bname%
echo browser path: %bpath%
echo browser description: %bdescription%
echo browser supported files extensions: %bfileextensions%
echo browser supported protocols: %bprotocols%
echo browser supported files class (automatically determined): %bfileclass%
echo browser supported handler name (automatically determined): %bhandler%
echo.
if not defined NOCONFIRM (
	set /p "conf=confirm? (y-n) "
	if "!conf!" NEQ "y" (
		echo aborted.
		if not defined NOPAUSE pause
		exit /b 2
	)
)
echo.
echo ==================
echo.



rem ================== EXECUTION
echo fixing path for registry: doubling the slashes...
set "bpath=%bpath:\=\\%"
echo new path is: %bpath%




if not defined NOPAUSE pause
echo. & echo registering new application...
reg add "HKEY_CURRENT_USER\Software\RegisteredApplications" /v "%bname%" /d "Software\Clients\StartMenuInternet\%bname%\Capabilities" /f



if not defined NOPAUSE pause
echo. & echo declaring application capabilities and adding startmenu entry...
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%" /ve /d "%bname%" /f
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\Capabilities" /v "ApplicationDescription" /d "%bname%" /f
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\Capabilities" /v "ApplicationIcon" /d "%bpath%,0" /f
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\Capabilities" /v "ApplicationName" /d "%bname%" /f
FOR %%a IN (%bfileextensions%) DO (
	reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\Capabilities\FileAssociations" /v ".%%~a" /d "%bfileclass%" /f
)
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\Capabilities\Startmenu" /v "StartMenuInternet" /d "%bname%" /f
FOR %%a IN (%bprotocols%) DO (
	reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\Capabilities\URLAssociations" /v "%%a" /d "%bfileclass%" /f
)
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\DefaultIcon" /ve /d "%bpath%,0" /f
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\shell" /f
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\shell\open" /f
reg add "HKEY_CURRENT_USER\Software\Clients\StartMenuInternet\%bname%\shell\open\command" /ve /d "\"%bpath%\"" /f



if not defined NOPAUSE pause
echo. & echo adding handlers...
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%" /ve /d "%bhandler%" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%" /v "AppUserModelId" /d "%bname%" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\Application" /v "AppUserModelId" /d "%bname%" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\Application" /v "ApplicationIcon" /d "%bpath%,0" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\Application" /v "ApplicationName" /d "%bname%" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\Application" /v "ApplicationDescription" /d "%bdescription%" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\Application" /v "ApplicationCompany" /d "%bname%" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\DefaultIcon" /ve /d "%bpath%,0" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\shell" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\shell\open" /f
reg add "HKEY_CURRENT_USER\Software\Classes\%bfileclass%\shell\open\command" /ve /d "\"%bpath%\" \"%%1\"" /f



rem ================== END
if not defined NOPAUSE pause
echo.
echo ==================
echo All Done.
echo ==================
echo.
if not defined NOPAUSE pause
exit /b %ERRORLEVEL%