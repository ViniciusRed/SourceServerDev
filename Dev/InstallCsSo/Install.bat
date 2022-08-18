@echo off
echo --[For more information enter https://github.com/ViniciusRed/SourceServerDev]--
setlocal
for /f "delims==; tokens=1,2 eol=;" %%G in (config.cfg) do set %%G=%%H
title Install Counter Strike Source Offensive


Goto ChangeLog
--Goto Download
Goto Install 
Goto Bkp_Bin
Goto Bin_CsSo
Goto Bin_cstrike
Goto Remove_CsSo

:ChangeLog
type %ChangeLog%

:Download
title Download CsSo
echo [Download CSSO in progress]
%SYSTEMROOT%\SYSTEM32\bitsadmin.exe /rawreturn /nowrap /transfer starter /dynamic /download /priority foreground %CsSo% "%temp%/%Name%"
