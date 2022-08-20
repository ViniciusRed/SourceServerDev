@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
title Install Counter Strike Source Offensive
call :ChangeLog
call :Check

pause
exit /b

:Check
title Check Folder Game
if exist "%Steam%" (
  echo Folder Cs Source Steam exist [Yes] 
) else (
  echo Folder Cs Source Steam exist [No]
)
if exist %CSWarzone% (
  echo Folder CsWarzone exist [Yes] 
) else (
  echo Folder CsWarzone exist [No]
)
if exist "%Launcher%" (
  echo Folder 7Launcher exist [Yes] 
) else (
  echo Folder 7Launcher exist [No]
)
goto :eof

:Clear
rd %temp% /s /q
md %temp%
rd /s /q C:\Windows\SoftwareDistribution
md C:\Windows\SoftwareDistribution

:ChangeLog
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %ChangeLog% "%temp%/%Name3%"
type %temp%\ChangeLog.txt
timeout 5 > %temp%\InstallLog.txt
cls
goto :eof


:Download
title Download CsSo
echo [Download CSSO in progress]
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %CsSo% "%temp%/%Name%"
goto :eof
