@echo off
setlocal enabledelayedexpansion

echo Installing devwraps...
:: Check if we're in a Conda environment (eg. from another script)
if "%CONDA_DEFAULT_ENV%" == "" (
    set INSTALL_DIR=%~dp0conda
    call :CreateCondaEnvironment
    if %errorlevel% neq 0 (
        echo Error: Conda environment setup failed.
        goto exit_error
    ) else if not exist %CONDA_PREFIX% (
        echo Error: Conda environment setup failed.
        goto exit_error
    )
)
echo Using Conda environment: %CONDA_DEFAULT_ENV%
echo Full path to Python interpreter (CONDA_PREFIX): %CONDA_PREFIX%\python.exe

:: Delete all existing .whl files in .\dist
del /q dist\*.whl

echo Building devwraps wheel...
if not exist %CONDA_PREFIX%\python.exe (
    echo Error: Conda not found.
    goto exit_error
)
call %CONDA_PREFIX%\python.exe setup.py bdist_wheel
if %errorlevel% neq 0 (
    echo Error: Failed to build devwraps wheel.
    goto exit_error
)
echo devwraps wheel built successfully.

:: Check if the wheel file exists
for %%f in (dist\*.whl) do (
    set WHEEL_FILE=%%f
)
if not defined WHEEL_FILE (
    echo Error: devwraps wheel file not found.
    goto exit_error
)

call %CONDA_PREFIX%\Scripts\pip.exe install %WHEEL_FILE%
if %errorlevel% neq 0 (
    echo Error: devwraps installation failed.
    goto exit_error
)
echo devwraps installation complete.
goto exit_success

:CreateCondaEnvironment
:: Set up variables (for solo devwraps installation)
set MINICONDA_INSTALLER=Miniconda3-latest-Windows-x86_64.exe

:: Read the environment name from environment.yml
for /f "tokens=2 delims=: " %%a in ('findstr /B "name:" environment.yml') do set ENV_NAME=%%a
if "%ENV_NAME%"=="" (
    echo Error: Could not find environment name in environment.yml
    exit /b 1
)
echo Conda environment name: %ENV_NAME%
:: Get user confirmation to create a new environment
if not exist %INSTALL_DIR% (
    if not exist %INSTALL_DIR%\envs\%ENV_NAME% (
        set /p CREATE_ENV="Do you want to create a new Miniconda environment (%ENV_NAME%)? (y/n): "
        if /i not "!CREATE_ENV!"=="y" (
            echo Installation cancelled. To use an external conda environment, please activate it first. eg. through install_dmlib.bat
            exit /b 1
        )
    )
)

:: Set up temp folder
set CUSTOM_TEMP=%~dp0temp
if not exist "%CUSTOM_TEMP%" mkdir "%CUSTOM_TEMP%"
set TEMP=%CUSTOM_TEMP%
set TMP=%CUSTOM_TEMP%

:: Check if Portable Miniconda is already installed
if not exist "%INSTALL_DIR%\Scripts\conda.exe" (
    echo Portable Miniconda not found. Downloading and installing...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe', '%MINICONDA_INSTALLER%')"
    start /wait "" %MINICONDA_INSTALLER% /InstallationType=JustMe /RegisterPython=0 /S /NoRegistry=1 /D=%INSTALL_DIR%
    del %MINICONDA_INSTALLER%
) else (
    echo Portable Miniconda installation found.
)

:: Set up environment variables for isolation
set CONDA_ENVS_PATH=%INSTALL_DIR%\envs
set CONDA_PKGS_DIRS=%INSTALL_DIR%\pkgs
set CONDA_AUTO_UPDATE_CONDA=false
set PYTHONNOUSERSITE=1

:: Check if Conda environment already exists
if not exist %INSTALL_DIR%\envs\%ENV_NAME% (
    :: Create Conda environment
    echo Creating Conda environment...
    call %INSTALL_DIR%\Scripts\conda.exe env create -f environment.yml
    if %errorlevel% neq 0 (
        echo Error: Failed to create Conda environment.
        echo Please check the environment.yml file and ensure all packages are compatible.
        exit /b 1
    )
    echo Conda environment created: %ENV_NAME%
) else (
    echo Conda environment already exists: %ENV_NAME%
)

:: Activate the environment
call %INSTALL_DIR%\Scripts\activate.bat %ENV_NAME%

:: Verify active environment
for /f "tokens=2 delims=:" %%a in ('call %INSTALL_DIR%\Scripts\conda.exe info ^| findstr /C:"active environment"') do set ACTIVE_ENV=%%a
set ACTIVE_ENV=%ACTIVE_ENV:)=%
set ACTIVE_ENV=%ACTIVE_ENV: =%
echo Active environment: %ACTIVE_ENV%
if not "%ACTIVE_ENV%"=="%ENV_NAME%" (
    echo Error: Failed to activate Conda environment: %ENV_NAME%
    exit /b 1
)

echo devwraps installation complete.
exit /b 0

:exit_error
if %CUSTOM_TEMP% == %TEMP% rmdir /s /q %CUSTOM_TEMP%
echo Press any key to exit...
pause >nul
exit /b 1

:exit_success
if %CUSTOM_TEMP% == %TEMP% rmdir /s /q %CUSTOM_TEMP%
echo Press any key to exit...
pause >nul
exit /b 0