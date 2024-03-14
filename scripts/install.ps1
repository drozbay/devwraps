Create-Anaconda-Environment -environmentName $global:dmlibEnvironmentName
if (-not $?) {
	exit
}
Activate-Anaconda -environmentName $global:dmlibEnvironmentName
if (-not $?) {
	exit
}
pip uninstall -y devwraps
if (-not $?) {
	exit
}
Remove-Item dist\*.whl -ErrorAction SilentlyContinue
python setup.py bdist_wheel
if (-not $?) {
	exit
}
pip install (get-item .\dist\*.whl)