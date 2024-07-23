$env:sandboxNativeBlacklist = @("shutdown.exe", "restart.exe", "certutil.exe", "bitsadmin.exe", "curl.exe", "wget.exe", "cmd.exe", "pwsh.exe", "powershell.exe");
$env:sandboxCmdletBlacklist = @("start-sleep", "restart-computer", "invoke-webrequest", "invoke-restMethod") #,  "test-connection","start-process");
$env:sandboxDotnetBlacklist = @("sleep", "exit", "shellexecute", "createthread"  ,"start");
$env:sandboxIexObfuscations = @("((Get-Variable'*mdr*').Name[3,11,2]-Join'')", "((GV'*mdr*').Name[3,11,2]-Join'')", "((Variable'*mdr*').Name[3,11,2]-Join'')", "(([STring]''.indEXof)[149,399,62]-joIn'')");
