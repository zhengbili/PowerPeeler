#!/usr/bin/env bash

input_dir='../samples/100-samples'
output_dir='../samples/100-samples-res'

if [ "$(uname)" == "Darwin" ]; then
exit;
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
pwshLocation='../src/powershell-unix/bin/Release/net7.0/linux-x64/publish/pwsh'
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
exit;
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
pwshLocation='../src/powershell-win-core/bin/Release/net7.0/win7-x64/publish/pwsh.exe'
fi
for filename in $(ls $input_dir);do
echo $filename
$pwshLocation ./deob.ps1 -InputPath $input_dir/$filename -OutputPath $output_dir/$filename -SettingType Analysis
done
