@echo off & setlocal
rem Sources / Inspiration:
rem   https://www.dostips.com/DtCod
rem   https://social.technet.microsoft.com/Forums/azure/en-US/a349801f-398f-4139-8e8b-b0a92f599e2b/enable-recycle-bin-on-mapped-network-drives?forum=w8itpronetworking


REM ========== INFO  ========================
REM PLEASE RUN AS ADMIN
REM https://social.technet.microsoft.com/Forums/windows/en-US/a349801f-398f-4139-8e8b-b0a92f599e2b/enable-recycle-bin-on-mapped-network-drives?forum=w8itpronetworking
REM KF_CATEGORY
  REM KF_CATEGORY_VIRTUAL  = 1,
  REM KF_CATEGORY_FIXED    = 2,
  REM KF_CATEGORY_COMMON   = 3,
  REM KF_CATEGORY_PERUSER  = 4
REM The TechNet "KF_CATEGORY enumeration" page describes these, including that many features including redirection are not available for categories 1 and 2.


REM ========== ARGS INFO  ========================
REM   [--toreg (to write to registry directly)]
REM   [--nopause (to avoid pausing at the end)]
REM   [%1 = drive letter or network drive path]


REM ========== VARIABLES  ========================
set KF_CATEGORY=00000003
set defaultsize=99999



REM ========== MAIN FUNCTION  ========================
pushd "%~dp0"
:: elevate if needed
net file 1>NUL 2>NUL
if %errorlevel% NEQ 0 (
	powershell Start-Process -passthru -wait -FilePath "%~f0" -ArgumentList """%*""" -verb runas
	exit /b %ERRORLEVEL%
)

:parseArgs
if "%~1" EQU "--toreg" (
	set TOREG=1
	shift
	goto :parseArgs
)

if "%~1" EQU "--nopause" (
	set NOPAUSE=1
	shift
	goto :parseArgs
)

set "ARG=%~1"
if not defined ARG (
	set /p "RelativePath=Enter drive letter (eg X) or current mapped path of drive (e.g. X:\FileShare\D_Drive):"
) ELSE (
	set RelativePath=%ARG%
)
if "%RelativePath%" EQU "%RelativePath:~0,1%" (
	rem if it is a single character, it is considered a drive letter
	set RelativePath=%RelativePath%:\
)
REM replace \ with \\ (for reg value its a requirement)
Set RelativePath=%RelativePath:\=\\%

REM set /p MaxBinSize_Dec=Enter max size (in mb) (eg 11gb=11000):
set MaxBinSize_Dec=%defaultsize%
call :toHex %MaxBinSize_Dec% MaxBinSize_Hex

call :MakeGUID_VBS NewGUID

set outputREG="ForcedRecycleBin_%NewGUID%_%MaxBinSize_Dec%mb.reg"

if defined TOREG (
	echo writing to registry ...
	for %%r in (32 64) do (
		reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\%NewGUID% /v RelativePath /d "%RelativePath%" /f /reg:%%r
		reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\%NewGUID% /v Category /t REG_DWORD /d %KF_CATEGORY% /f /reg:%%r
		reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\%NewGUID% /v Name /d "forced_RecyclingBin_%NewGUID%" /f /reg:%%r
		reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\KnownFolder\%NewGUID% /v MaxCapacity /t REG_DWORD /d 0x%MaxBinSize_Hex% /f /reg:%%r
		reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\KnownFolder\%NewGUID% /v NukeOnDelete /t REG_DWORD /d 0x00000000 /f /reg:%%r
	)
) ELSE (
	echo writing to file ...
	echo Windows Registry Editor Version 5.00 > %outputREG%
	echo.>> %outputREG%
	echo.>> %outputREG%
	echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\%NewGUID%] >> %outputREG%
	echo "RelativePath"="%RelativePath%" >> %outputREG%
	echo "Category"=dword:%KF_CATEGORY% >> %outputREG%
	echo "Name"="forced_RecyclingBin_%NewGUID%" >> %outputREG%
	echo.>> %outputREG%
	echo [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\KnownFolder\%NewGUID%]  >> %outputREG%
	echo "MaxCapacity"=dword:%MaxBinSize_Hex% >> %outputREG%
	echo "NukeOnDelete"=dword:00000000 >> %outputREG%
)
echo ... done.
if not defined NOPAUSE pause
popd
exit /b %ERRORLEVEL%



REM ========== SUB FUNCTIONS  ========================
:MakeGUID_VBS
	echo set obj = CreateObject("Scriptlet.TypeLib") > TEMP_generateGUID.vbs
	echo WScript.Echo obj.GUID >> TEMP_generateGUID.vbs
	FOR /F "usebackq tokens=*" %%r in (`CSCRIPT "TEMP_generateGUID.vbs"`)DO SET RESULT=%%r
	set %1=%RESULT%
	del TEMP_generateGUID.vbs
exit /b %ERRORLEVEL%



:toDec
	:: todec hex dec -- convert a hexadecimal number to decimal
	::             -- hex [in]      - hexadecimal number to convert
	::             -- dec [out,opt] - variable to store the converted decimal number in
	SETLOCAL
	set /a dec=0x%~1
	( ENDLOCAL & REM RETURN VALUES
	    IF "%~2" NEQ "" (SET %~2=%dec%)ELSE ECHO.%dec%
	)
exit /b %ERRORLEVEL%



:toHex
	:: eg  call :toHex dec hex -- convert a decimal number to hexadecimal, i.e. -20 to FFFFFFEC or 26 to 0000001A
	::             -- dec [in]      - decimal number to convert
	::             -- hex [out,opt] - variable to store the converted hexadecimal number in
	::Thanks to 'dbenham' dostips forum users who inspired to improve this function
	:$created 20091203 :$changed 20110330 :$categories Arithmetic,Encoding
	:$source http://www.dostips.com
	SETLOCAL ENABLEDELAYEDEXPANSION
	set /a dec=%~1
	set "hex="
	set "map=0123456789ABCDEF"
	for /L %%N in (1,1,8)do (
	    set /a "d=dec&15,dec>>=4"
	    for %%D in (!d!) do set "hex=!map:~%%D,1!!hex!"
	)
	rem !!!! REMOVE LEADING ZEROS by activating the next line, e.g. will return 1A instead of 0000001A
	rem for /f "tokens=* delims=0" %%A in ("%hex%") do set "hex=%%A"&if not defined hex set "hex=0"
	( ENDLOCAL & REM RETURN VALUES
	    IF "%~2" NEQ "" (SET %~2=%hex%) ELSE ECHO.%hex%
	)
exit /b %ERRORLEVEL%
