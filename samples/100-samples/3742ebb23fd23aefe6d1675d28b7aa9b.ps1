$7ZipPath = '"C:\Users\User\Downloads\OS\7z_test\7z.exe"'
$zipFile = '"C:\Users\User\Downloads\OS\7z_test\AnyDesk.zip"'
$zipFilePassword = "12345"
$command = "& $7ZipPath e -oC:\Users\User\Downloads\OS\7z_test -y -tzip -p$zipFilePassword $zipFile"
iex $command