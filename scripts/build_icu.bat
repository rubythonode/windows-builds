@echo off
SETLOCAL
SET EL=0
echo ------ ICU -----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

:: http://blog.pcitron.fr/2014/03/25/compiling-icu-with-visual-studio-2013/
:: http://devwiki.neosys.com/index.php/Building_ICU_32/64_on_Windows

cd %PKGDIR%
CALL %ROOTDIR%\scripts\download icu4c-%ICU_VERSION2%-src.tgz
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

if EXIST icu echo found extracted sources && GOTO SRC_EXTRACTED

echo extracting
CALL bsdtar xfz %PKGDIR%\icu4c-%ICU_VERSION2%-src.tgz
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

cd icu
IF EXIST %PATCHES%\icu-%ICU_VERSION%.diff ECHO patching with %PATCHES%\icu-%ICU_VERSION%.diff && patch -N -p1 < %PATCHES%/icu-%ICU_VERSION%.diff || %SKIP_FAILED_PATCH%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

:SRC_EXTRACTED

cd %PKGDIR%\icu
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::DebugInformationFormat
::OldStyle = /Z7 (within file)
::ProgramDatabase = /Zi (pdb)
::EditAndContinue = /ZI
REM ::/p:DebugInformationFormat=EditAndContinue ^

msbuild ^
.\source\i18n\i18n.vcxproj ^
/p:ForceImportBeforeCppTargets=%ROOTDIR%\scripts\force-debug-information-for-sln.props ^
/nologo ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration=%BUILD_TYPE% ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

msbuild ^
.\source\common\common.vcxproj ^
/p:ForceImportBeforeCppTargets=%ROOTDIR%\scripts\force-debug-information-for-sln.props ^
/nologo ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration=%BUILD_TYPE% ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
::call msbuild source\data\makedata.vcxproj /m /toolsversion:%TOOLS_VERSION% /p:PlatformToolset=%PLATFORM_TOOLSET% /p:Configuration="Release" /p:Platform=%BUILDPLATFORM%
::call msbuild source\allinone\allinone.sln /m /target:common;makedata;i18n /toolsversion:%TOOLS_VERSION% /p:PlatformToolset=%PLATFORM_TOOLSET% /p:Configuration="Release" /p:Platform=%BUILDPLATFORM%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

::echo building release AND debug
::echo A boost build bug that tests for existence of *debug* version of ICU even when building release only version of boost.
::echo http://devwiki.neosys.com/index.php/Building_Boost_32/64_on_Windows

::ECHO building ... DEBUG
::CALL msbuild source\allinone\allinone.sln /t:Rebuild  /p:Configuration="Debug" /p:Platform=%BUILDPLATFORM%
::IF ERRORLEVEL 1 GOTO ERROR

GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo ----------ERROR ICU --------------

:DONE

cd %ROOTDIR%
EXIT /b %EL%
