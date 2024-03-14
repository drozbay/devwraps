# https://stackoverflow.com/questions/5648931
Function Create-Anaconda-Environment {
    param (
        [Parameter(Mandatory=$true)]
        [string]$environmentName
    )

    process {
        $anacondaPath = Get-Anaconda-Path
        $condaPath = Join-Path -Path $anacondaPath -ChildPath "Scripts\conda.exe"
        if (-not (Test-Path $condaPath)) {
            Write-Error "Cannot find conda. Is Anaconda for Python 3 installed (https://www.anaconda.com/download)?" -ErrorAction Stop
        }

        $envPath = Join-Path -Path $anacondaPath -ChildPath "envs\$environmentName"
        if (Test-Path $envPath) {
            Write-Host "Conda environment $environmentName already exists."
        } else {
            Write-Host "Creating conda environment $environmentName..."
            & $condaPath create --name $environmentName python=3.8 -y
            if ($?) {
                Write-Host "Conda environment $environmentName created successfully."
            } else {
                Write-Error "Failed to create conda environment $environmentName."
            }
        }
    }
}

Function Get-Anaconda-Path {
    process {
        $bases = "Registry::HKEY_CURRENT_USER\Software\Python\PythonCore"
        if (-not (Test-Path $bases)) {
            Write-Error "Cannot find Anaconda. Is Anaconda for Python 3 installed (https://www.anaconda.com/download)?" -ErrorAction Stop
        }

        $subs = (Get-Item -LiteralPath $bases).GetSubKeyNames()
        $addr = ""
        foreach ($sub in $subs) {
            $versionString = $sub -as [decimal]
            if ($versionString -ge 3) {
                $addr = "$bases\$sub\InstallPath"
                break
            }
        }

        if ($addr.Length -lt 1) {
            Write-Error "Anaconda for Python 3+ must be installed (Anaconda for Python 2 is not supported)" -ErrorAction Stop
        }
        else {
            $item = Get-Item -LiteralPath $addr
            $anacondaPath = $item.GetValue("")
			Write-Host "Anaconda Path: $anacondaPath"  # Display the path on the screen
            return $anacondaPath
        }
    }
}

Function Activate-Anaconda {
    param (
        [Parameter(Mandatory=$true)]
        [string]$environmentName
    )

    process {
        Write-Host "Activating Anaconda environment: $environmentName"
        $anacondaPath = Get-Anaconda-Path
        $anacondaPath = (Split-Path -Parent -Path $anacondaPath)
        $envPath = Join-Path -Path $anacondaPath -ChildPath "envs\$environmentName"

        # https://github.com/BCSharp/PSCondaEnvs
        $env:Path = "$envPath;$envPath\Library\mingw-w64\bin;$envPath\Library\usr\bin;$envPath\Library\bin;$envPath\Scripts;$envPath\bin;" + $env:Path
        $env:CONDA_DEFAULT_ENV = $environmentName
        $env:CONDA_PREFIX = $envPath
    }
}