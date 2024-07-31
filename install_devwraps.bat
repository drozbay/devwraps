@echo off
setlocal enabledelayedexpansion

echo Installing devwraps...

:: Check if a Python path is provided as an argument
if "%~1" == "" (
    :: If no argument, throw an error and exit
    echo Error: No Python path provided.
    echo Please provide the full path to a Python interpreter as an argument.
    exit /b 1
) else (
    :: Use the provided Python path
    set PYTHON_EXE=%~1
)

:: Ensure Cython is installed
%PYTHON_EXE% -m pip install cython

:: Compile Cython extensions
echo Compiling Cython extensions...
%PYTHON_EXE% setup.py build_ext --inplace
if %errorlevel% neq 0 (
    echo Error: Cython compilation failed.
    exit /b 1
)

:: Install devwraps
%PYTHON_EXE% -m pip install -e .

:: Verify installation
%PYTHON_EXE% -c "import devwraps; print('devwraps installed successfully')"

if %errorlevel% neq 0 (
    echo Error: devwraps installation failed.
    exit /b 1
)

echo devwraps installation complete.