#!/usr/bin/env pwsh
# compile sandbox
cd Powershell
Import-Module ./build.psm1
Start-PSBootstrap
Start-PSBuild -Configuration Release
cd ..

# install dependencies
Install-Module -Name PSScriptAnalyzer

# compile dependencies
cd Deobfuscation
dotnet build DeobfuscationHelper.csproj
#dotnet build CmdParser.csproj
dotnet build Echo.csproj
cp bin/Debug/net7.0/DeobfuscationHelper.dll ./
#cp bin/Debug/net7.0/CmdParser.dll ./
#cp bin/Debug/net7.0/CmdParser.exe ./
#cp bin/Debug/net7.0/CmdParser.runtimeconfig.json ./
cp bin/Debug/net7.0/Echo.dll ./
try{Copy-Item bin/Debug/net7.0/Echo.exe ./ -ErrorAction SilenceContinue}catch{cp bin/Debug/net7.0/Echo ./}
cp bin/Debug/net7.0/Echo.runtimeconfig.json ./
rm -r bin
rm -r obj
cd ..
