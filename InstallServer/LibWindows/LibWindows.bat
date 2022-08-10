@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
Title Cs Source Server

:Download
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %DownloadUrl% "%~dp0/%DownloadName%"
pause
goto Download
goto Check
goto Check Server
goto Update
goto InstallServer
test