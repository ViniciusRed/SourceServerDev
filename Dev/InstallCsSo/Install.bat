@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
title Install Counter Strike Source Offensive
echo %Text%

Goto Clear
Goto ChangeLog
Goto Download
Goto Install 
Goto Bkp_Bin
Goto Bin_CsSo
Goto Bin_cstrike
Goto Remove_CsSo

:Clear
rd %prefetch% /s /q
md %prefetch%
rd %temp% /s /q
md %temp%
rd /s /q C:\Windows\SoftwareDistribution
md C:\Windows\SoftwareDistribution

:ChangeLog
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %ChangeLog% "%temp%/%Name3%"
type %temp%\ChangeLog.txt
timeout 5 > %temp%\InstallLog.txt
cls

:Download
title Download CsSo
echo [Download CSSO in progress]
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %CsSo% "%temp%/%Name%"

