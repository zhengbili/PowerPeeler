[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [Alias('ip')]
    [string]$InputPath = '--', #'./unittest.ps1',

    [Parameter(Mandatory = $false)]
    [Alias('op')]
    [string]$OutputPath = '--', #'./out.ps1',

    [Parameter(Mandatory = $false)]
    [Alias('st')]
    [ValidateSet('Simple', 'Read', 'Analysis', 'SemanticAnalysis')]
    [string]$SettingType = 'Analysis',

    [Parameter(Mandatory = $false)]
    [Alias('cmd')]
    [switch]$IsCmd
)


switch ($SettingType) {
    'Simple' {
        $global:Rule = @{
            'CHECK_PRINTABLE_RATE'         = 1
            'IGNORE_ASSIGN_LEFT'           = $true
            'IGNORE_SIGNLE_COMMAND_OUTPUT' = $false
            'IGNORE_VARIABLE_ARGUMENT'     = $false
            'STRONG_TYPE'                  = $false
            'KEEP_USER_FUNCTION'           = $true
            'MAX_LENGTH'                   = 500000
            'ALLOW_TYPE'                   = @([int], [string], [char[]])
            'BAN_TYPE'                     = @([intptr])
        }
        break
    }
    'Read' {
        $global:Rule = @{
            'CHECK_PRINTABLE_RATE'         = 0.75
            'IGNORE_ASSIGN_LEFT'           = $true
            'IGNORE_SIGNLE_COMMAND_OUTPUT' = $true
            'IGNORE_VARIABLE_ARGUMENT'     = $true
            'STRONG_TYPE'                  = $false
            'KEEP_USER_FUNCTION'           = $false
            'MAX_LENGTH'                   = 1000
            'BAN_TYPE'                     = @([intptr])
        }
        break
    }
    'SemanticAnalysis' {
        $global:Rule = @{
            'CHECK_PRINTABLE_RATE'         = 0.5
            'IGNORE_ASSIGN_LEFT'           = $true
            'IGNORE_SIGNLE_COMMAND_OUTPUT' = $false
            'IGNORE_VARIABLE_ARGUMENT'     = $false
            'STRONG_TYPE'                  = $true
            'KEEP_USER_FUNCTION'           = $false
            'MAX_LENGTH'                   = 10000000
            'BAN_TYPE'                     = @([intptr])
        }
        break
    }
    'Analysis' {
        $global:Rule = @{
            'CHECK_PRINTABLE_RATE'         = 0.5
            'IGNORE_ASSIGN_LEFT'           = $true
            'IGNORE_SIGNLE_COMMAND_OUTPUT' = $false
            'IGNORE_VARIABLE_ARGUMENT'     = $false
            'STRONG_TYPE'                  = $true
            'KEEP_USER_FUNCTION'           = $true
            'MAX_LENGTH'                   = 10000000
            'BAN_TYPE'                     = @([intptr], [bool])
        }
        break
    }
}

function NotNaObject ($x) {
    return ($null -ne $x) -and ($null -eq $x.GetType -or $x.GetType().Name -ne 'NaNObject')
}

function GetHashCode ($node) {
    if ($node.HashCode) { return $node.HashCode; }
    return ('{0}-{1}-{2}' -f $node.Extent.StartOffset, $node.Extent.EndOffset, $node.GetHashCode())
}

function GetCmdletPosition ($curNode, $CommandElements) {
    $w = 0
    $i = 1
    while ($i -lt $CommandElements.Count) {
        if ($CommandElements[$i].GetType().Name -eq 'CommandParameterAst' -and $CommandElements[$i + 1].GetType().Name -ne 'CommandParameterAst') { $i += 2; }
        elseif ($CommandElements[$i] -eq $curNode) { return $w; }
        else { $w += 1; $i += 1; }
    }
    return -1
}

function InAssignmentLeft ($curNode) {
    while ($curNode.Parent) {
        if ($curNode.Parent.GetType().Name -eq 'AssignmentStatementAst' -and $curNode.Parent.Left -eq $curNode) { return $true }
        $curNode = $curNode.Parent
        if ($curNode.GetType().Name -eq 'IndexExpressionAst') { return $false; }
    }
    return $false
}

function Stringify ($Object, $check = $true) {
    #$global:Object2 = $Object
    if ($check -and $null -ne $Object -and $null -ne $global:Rule['ALLOW_TYPE'] -and -not $global:Rule['ALLOW_TYPE'].Contains($Object.GetType())) { throw 'Type denied!' }
    if ($check -and $null -ne $Object -and ($global:Rule['BAN_TYPE'].Contains($Object.GetType()) -or @('RuntimeAssembly') -contains $Object.GetType().Name)) { throw 'Type denied!' }
    if ($global:Rule['STRONG_TYPE']) { $t = (./ConvertTo-Expression.ps1 $Object $check -Strong -Expand -1 -Depth 3); }
    else { $t = (./ConvertTo-Expression.ps1 $Object $check -Expand -1 -Depth 3); }
    if ($check -and $t -match '\[pscustomobject\]') { throw 'pscustomobject denied!' }
    return $t
}

function ParseCmd($lines) {
    $results = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        $CmdScript = "@echo off`n..\Deobfuscation\Echo.exe " + $line
        [System.IO.File]::WriteAllText('temp.bat', $CmdScript, [System.Text.Encoding]::UTF8)
        $argv = (./temp.bat) | ConvertFrom-Json
        Remove-Item ./temp.bat
        if ($argv.Count -lt 1) { continue; }
        if (-not $argv[0].Contains('pwsh') -and -not $argv[0].Contains('powershell')) { continue; }
        $w = 1
        $command = [System.Collections.Generic.List[string]]::new()
        while ($w -lt $argv.Count) {
            $curArgv = $argv[$w].ToLower()
            if ($curArgv[0] -eq '/') { $curArgv = '-' + $curArgv.SubString(1); }
            if (($curArgv -eq '-ec') -or ('-encodedcommand'.StartsWith($curArgv) -and $curArgv.StartsWith('-e'))) {
                $command.Add([System.Text.Encoding]::GetEncoding('UTF-16').GetString([convert]::FromBase64String($argv[$w + 1])))
                $w = $argv.Count
                break
            }
            if ('-command'.StartsWith($curArgv) -and $curArgv.StartsWith('-c')) {
                $w += 1
                break
            }
            if (@('-help', '-?').Where({ $_.StartsWith($curArgv) }).Count -and @('-h', '-?').Where({ $curArgv.StartsWith($_) }).Count) {
                break
            }
            if (@('-nologo', '-noexit', '-sta', '-mta', '-noprofile', '-noninteractive').Where({ $_.StartsWith($curArgv) }).Count -and @('-nol', '-noe', '-st', '-mta', '-nop', '-noni').Where({ $curArgv.StartsWith($_) }).Count) {
                $w += 1
                continue
            } 
            if ($curArgv.StartsWith('-')) { $w += 2; continue }
            break
        }
        for (; $w -lt $argv.Count; $w += 1) { $command.Add($argv[$w]); }
        $results.Add([string]$command)
    }
    return $results
}

function DeobPowershell($Command = '', $EncodCommand = '') {
    if ($EncodCommand.Length -gt 0) { $Command = [System.Text.Encoding]::Unicode.GetString([convert]::FromBase64String($EncodCommand)); }
    $temp_file1 = "$([datetime]::Now.Ticks).tmp"
    $temp_file2 = "$([datetime]::Now.Ticks+1).tmp"
    [System.IO.File]::WriteAllText($temp_file1, $Command)
    $std_log = pwsh ./deob.ps1 -InputPath $temp_file1 -OutputPath $temp_file2
    $result = [System.IO.File]::ReadAllText($temp_file2)
    Remove-Item $temp_file1
    Remove-Item $temp_file2
    return $result
}

function ValueTraversal ($curNode) {
    $curId = (GetHashCode $curNode)
    $curOutValue = $valuelog[$iexPrefix + 'o' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
    if ($global:Rule['KEEP_USER_FUNCTION'] -and $curNode.GetType().Name -eq 'CommandAst' -and $valuelog[$iexPrefix + 'f' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
        $t = $curNode.Parent
        while ($t -ne $ast) {
            $user_function_parents.Add((GetHashCode $t)) | Out-Null
            $t = $t.Parent
        }
    }
    if ($curNode.GetType().Name -eq 'VariableExpressionAst') { 
        $t = $curNode
        while ($t -ne $ast) {
            $var_node_parents.Add((GetHashCode $t)) | Out-Null
            $t = $t.Parent
        }
    }
    if ($curNode.Value -and $null -eq $curNode.NestedExpressions -and -not @([scriptblock]).Contains($curNode.Value.GetType())) { $NodeValue[$curId] = $curNode.Value }
    if ($null -ne $curOutValue -and -not `
        ( $curOutValue.GetType() -eq [bool] -and $var_node_parents.Contains((GetHashCode $curNode))) -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.GetType().Name -like '*BlockAst') -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.Parent -and $curNode.Parent.GetType().Name -like '*BlockAst') -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.Parent -and $curNode.Parent.GetType().Name -eq 'PipelineAst' -and `
                $curNode.Parent.PipelineElements.Count -eq 1 -and $curNode.Parent.Parent -and $curNode.Parent.Parent.GetType().Name -like '*BlockAst') -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.Parent -and $curNode.Parent.GetType().Name -eq 'CommandExpressionAst' -and `
                $curNode.Parent.Parent -and $curNode.Parent.Parent.GetType().Name -eq 'PipelineAst' -and $curNode.Parent.Parent.PipelineElements.Count -eq 1 `
                -and $curNode.Parent.Parent.Parent -and $curNode.Parent.Parent.Parent.GetType().Name -like '*BlockAst')) {
        $NodeValue[$curId] = $curOutValue
    } elseif ($curNode.Parent -and $curNode.Parent.Right -eq $curNode -and $null -ne $valuelog[$iexPrefix + 'a' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
        $NodeValue[$curId] = $valuelog[$iexPrefix + 'a' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
    } elseif ($curNode.GetType().Name -eq 'TypeExpressionAst') {
        try { $NodeValue[$curId] = [type]($curNode.TypeName.FullName); } catch {}
    } elseif ($curNode.GetType().Name -eq 'CommandExpressionAst') { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Expression)]; }
    elseif ($curNode.GetType().Name -eq 'ParenExpressionAst') { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Pipeline)]; }
    elseif ($curNode.GetType().Name -eq 'PipelineAst' -and $curNode.PipelineElements.Count -eq 1) { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.PipelineElements[0])]; }
    # elseif ($curNode.GetType().Name -eq 'BinaryExpressionAst' -and $null -ne $NodeValue[(GetHashCode $curNode.Left)] -and $null -ne $NodeValue[(GetHashCode $curNode.Right)]) {
    #    if ($curNode.Operator -eq 'Plus') { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Left)] + $NodeValue[(GetHashCode $curNode.Right)]; }
    # }
    elseif ($curNode.GetType().Name -eq 'MemberExpressionAst' -and $NodeValue[(GetHashCode $curNode.Expression)] -and $NodeValue[(GetHashCode $curNode.Member)]) {
        if ($curNode.Static) { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Expression)]::($NodeValue[(GetHashCode $curNode.Member)]); }
        else { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Expression)].($NodeValue[(GetHashCode $curNode.Member)]); }
    }
}

function PreTraversal ($curNode) {
    $curId = (GetHashCode $curNode)
    $parNode = $curNode.Parent
    $curValue = $valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
    # if ($curNode.GetType().Name -eq 'TypeExpressionAst' -and $NodeValue[$curId]) {
    #     $NodeString[$curId] = "[$($NodeValue[$curId])]";
    #     return $false;
    # }
    if ($parNode.Member -eq $curNode -and $NodeValue[$curId] -and ($NodeValue[$curId] -ne 'Invoke') -and $NodeValue[(GetHashCode $parNode.Expression)]) {
        if ($parNode.Static) { $t = ($NodeValue[(GetHashCode $parNode.Expression)] | Get-Member -Static | Where-Object { $_.Name -eq $NodeValue[$curId] }).Name; }
        else { $t = ($NodeValue[(GetHashCode $parNode.Expression)] | Get-Member | Where-Object { $_.Name -eq $NodeValue[$curId] }).Name; }
        if ($NodeValue[$curId] -eq $t -and $NodeValue[$curId] -cmatch '^[0-9a-zA-Z_]*$') {
            $NodeString[$curId] = $t
            return $false
        }
    }
    if ($parNode -and ($parNode.GetType().Name -eq 'InvokeMemberExpressionAst')) {
        if (($curNode -eq $parNode.Expression) -and $valuelog[$iexPrefix + 'b' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + 'b' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]
            if ($valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                $t = $curNode
                for ($i = 0; $i -lt $valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; $i++) { $t = $t.Expression; }
                $nodes = $Childs[(GetHashCode $parNode)]
                $nodes[$nodes.IndexOf($curNode)] = @{ HashCode = $curId; Extent = @{ StartOffset = $curNode.Extent.StartOffset; EndOffset = $t.Extent.EndOffset; } }
            }
            return $false
        } elseif (($curNode -eq $parNode.Expression) -and $valuelog[$iexPrefix + 'L' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + 'L' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]
            if ($valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                $t = $curNode
                for ($i = 0; $i -lt $valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; $i++) { $t = $t.Expression; }
                $nodes = $Childs[(GetHashCode $parNode)]
                $nodes[$nodes.IndexOf($curNode)] = @{ HashCode = $curId; Extent = @{ StartOffset = $curNode.Extent.StartOffset; EndOffset = $t.Extent.EndOffset; } }
            }
            return $false
        } elseif (($curNode -eq $parNode.Member) -and $valuelog[$iexPrefix + 'm' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + 'm' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]
            if ($valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                $t = $parNode
                for ($i = 0; $i -lt $valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; $i++) { $t = $t.Expression; }
                if ($valuelog[$iexPrefix + 'b' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset] -or $valuelog[$iexPrefix + 'L' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                    $nodes = $Childs[(GetHashCode $parNode)]
                    $nodes[$nodes.IndexOf($curNode)] = @{ HashCode = $curId; Extent = @{ StartOffset = $t.Member.Extent.StartOffset; EndOffset = $curNode.Extent.EndOffset; } }
                } else { $NodeString[$curId] = 'Invoke'; }
            }
            return $false
        } elseif ($curValue) {
            if ($global:Rule['IGNORE_VARIABLE_ARGUMENT'] -and $curNode.GetType().Name -eq 'VariableExpressionAst') {
                $t = $curNode.VariablePath.ToString()
                if (!($t -cmatch '^[\w]+$')) { $t = '{' + $t.Replace('`', '``').Replace('{', '`{').Replace('}', '`}') + '}' }
                $NodeString[$curId] = '$' + $t
                return $false
            }
            $NodeString[$curId] = $curValue
            return $false
        }
    }
    if (($curNode -eq $parNode.Member) -and $NodeValue[$curId] -and $NodeValue[$curId] -cmatch '^[0-9a-zA-Z_]*$') {
        $NodeString[$curId] = $NodeValue[$curId]
        return $false
    }
    if ($curNode.GetType().Name -eq 'PipelineAst' -and $valuelog[$iexPrefix + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset] -eq 'Invoke-Expression' -and `
            $curNode.PipelineElements[-1].CommandElements.Count -eq 1 -and $null -ne $valuelog[$iexPrefix + 'p' + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset]) {
        $ScriptString = $valuelog[$iexPrefix + 'p' + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset]
        try {
            $global:iexPrefix += '[{0},{1}]' -f $curNode.PipelineElements[-1].Extent.StartOffset, $curNode.PipelineElements[-1].Extent.EndOffset
            $NodeString[$curId] = DeObfuscate -ScriptString $ScriptString
        } catch {
            Write-Host -ForegroundColor red (Out-String -InputObject $Error[0])
            $NodeString[$curId] = $ScriptString
        }
        $global:iexPrefix = $global:iexPrefix.Remove($global:iexPrefix.length - ('[{0},{1}]' -f $curNode.PipelineElements[-1].Extent.StartOffset, $curNode.PipelineElements[-1].Extent.EndOffset).length)
        return $false
    }
    if ($curNode.GetType().Name -eq 'CommandAst' -and $curValue -eq 'Invoke-Expression' -and `
        ($curNode.CommandElements.Count -eq 2 -or ($curNode.CommandElements.Count -eq 3 -and '-Command' -eq $valuelog[$iexPrefix + $curNode.CommandElements[1].Extent.StartOffset + ',' + $curNode.CommandElements[1].Extent.EndOffset])) `
            -and $null -ne $valuelog[$iexPrefix + $curNode.CommandElements[-1].Extent.StartOffset + ',' + $curNode.CommandElements[-1].Extent.EndOffset]) {
        $ScriptString = $valuelog[$iexPrefix + $curNode.CommandElements[-1].Extent.StartOffset + ',' + $curNode.CommandElements[-1].Extent.EndOffset]
        try {
            $global:iexPrefix += '[{0},{1}]' -f $curNode.Extent.StartOffset, $curNode.Extent.EndOffset
            $NodeString[$curId] = DeObfuscate -ScriptString $ScriptString
        } catch {
            Write-Host -ForegroundColor red (Out-String -InputObject $Error[0])
            $NodeString[$curId] = $ScriptString
        }
        $global:iexPrefix = $global:iexPrefix.Remove($global:iexPrefix.length - ('[{0},{1}]' -f $parNode.Extent.StartOffset, $parNode.Extent.EndOffset).length)
        return $false
    } elseif ($curNode.GetType().Name -eq 'CommandAst' -and $curValue -and @('powershell', 'powershell.exe', 'pwsh', 'pwsh.exe').Contains($curValue.split('/')[-1].ToLower())) {
        try {
            $w = 1
            $command = [System.Collections.Generic.List[string]]@()
            $encodedcommand = ''
            while ($w -lt $curNode.CommandElements.Count) {
                $curArgv = $valuelog[$iexPrefix + $curNode.CommandElements[$w].Extent.StartOffset + ',' + $curNode.CommandElements[$w].Extent.EndOffset].ToLower()
                if ($curArgv[0] -eq '/') { $curArgv = '-' + $curArgv.SubString(1); }
                if (($curArgv -eq '-ec') -or ('-encodedcommand'.StartsWith($curArgv) -and $curArgv.StartsWith('-e'))) {
                    $encodedcommand = $valuelog[$iexPrefix + $curNode.CommandElements[$w + 1].Extent.StartOffset + ',' + $curNode.CommandElements[$w + 1].Extent.EndOffset]
                    break
                }
                if ('-command'.StartsWith($curArgv) -and $curArgv.StartsWith('-c')) {
                    $w += 1
                    break
                }
                if (@('-help', '-?').Where({ $_.StartsWith($curArgv) }).Count -and @('-h', '-?').Where({ $curArgv.StartsWith($_) }).Count) {
                    break
                }
                if (@('-nologo', '-noexit', '-sta', '-mta', '-noprofile', '-noninteractive').Where({ $_.StartsWith($curArgv) }).Count -and @('-nol', '-noe', '-st', '-mta', '-nop', '-noni').Where({ $curArgv.StartsWith($_) }).Count) {
                    $w += 1
                    continue
                } 
                if ($curArgv.StartsWith('-')) { $w += 2; continue }
                break
            }
            while (-not $encodedcommand -and $w -lt $curNode.CommandElements.Count) {
                $curArgv = $valuelog[$iexPrefix + $curNode.CommandElements[$w].Extent.StartOffset + ',' + $curNode.CommandElements[$w].Extent.EndOffset]
                $command.Add($curArgv.ToString())
                if ($curArgv.GetType() -eq [scriptblock]) { break; }
                $w += 1
            }
            Write-Host -ForegroundColor White 'Powershell command-line found: '
            Write-Host -ForegroundColor Green $command
            Write-Host -ForegroundColor Green $encodedcommand
            $env:powershellDepth = $env:powershellDepth + 1
            if ($command -or $encodedcommand) { $NodeString[$curId] = 'powershell.exe ' + (Stringify (DeobPowershell ([string]$command) $encodedcommand)).TrimStart('[string]') }
            $env:powershellDepth = $env:powershellDepth - 1
            return $false
        } catch {
            Write-Host -ForegroundColor red (Out-String -InputObject $Error[0])
        }
    } elseif ($curNode.GetType().Name -eq 'CommandAst' -and $curValue -eq 'Start-Job' -and $curNode.CommandElements.Count -eq 2) {
        try {
            $command = $valuelog[$iexPrefix + $curNode.CommandElements[1].Extent.StartOffset + ',' + $curNode.CommandElements[1].Extent.EndOffset]
            $env:powershellDepth = $env:powershellDepth + 1
            $NodeString[$curId] = 'Start-Job ' + (Stringify ([scriptblock]::Create((DeobPowershell ([string]$command) '')))).TrimStart('[scriptblock]')
            $env:powershellDepth = $env:powershellDepth - 1
            return $false
        } catch {
            Write-Host -ForegroundColor red (Out-String -InputObject $Error[0])
        }
    } elseif ($curNode.GetType().Name -eq 'CommandAst' -and $valuelog[$iexPrefix + 'f' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
        try {
            if ($funcCount[$curValue] -eq $hookTimes -and $null -ne $funcDeob[$curValue]) {
                $NodeString[$curId] += " <#`n$($funcDeob[$curValue].Replace('#>','# >'))`nresult:`n$(Stringify $valuelog[$iexPrefix + 'o' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset])`n#>"
            } else { $NodeString[$curId] += "<#$(Stringify $valuelog[$iexPrefix + 'o' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset])#>" }
            return $true
        } catch {
            Write-Host -ForegroundColor red (Out-String -InputObject $Error[0])
        }
    }
    if ($parNode -and $parNode.GetType().Name -eq 'CommandAst' -and $parNode.CommandElements -contains $curNode) {
        $w = $parNode.CommandElements.IndexOf($curNode)
        if ($w -eq 0 -and $valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            if (@('Dot', 'Ampersand').Contains($parNode.InvocationOperator.ToString())) { $NodeString[$curId] = (Stringify $valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]).TrimStart('[string]') }
            else { $NodeString[$curId] = $valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset] }
            return $false
        } elseif ($valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset] -eq 'Invoke-Expression' -and $null -ne $curValue -and `
            ((GetCmdletPosition $curNode $parNode.CommandElements) -eq 0 -or $valuelog[$iexPrefix + $parNode.CommandElements[$w - 1].Extent.StartOffset + ',' + $parNode.CommandElements[$w - 1].Extent.EndOffset] -eq '-Command') ) {
            $ScriptString = $curValue
            try {
                $global:iexPrefix += '[{0},{1}]' -f $parNode.Extent.StartOffset, $parNode.Extent.EndOffset
                $NodeString[$curId] = Stringify (DeObfuscate -ScriptString $ScriptString)
                $global:iexPrefix = $global:iexPrefix.Remove($global:iexPrefix.length - ('[{0},{1}]' -f $parNode.Extent.StartOffset, $parNode.Extent.EndOffset).length)
                return $false
            } catch {
                $global:iexPrefix = $global:iexPrefix.Remove($global:iexPrefix.length - ('[{0},{1}]' -f $parNode.Extent.StartOffset, $parNode.Extent.EndOffset).length)
            }
        }
        # if ($global:Rule['IGNORE_VARIABLE_ARGUMENT'] -and $curNode.GetType().Name -eq 'VariableExpressionAst') {
        #     $t = $curNode.VariablePath.ToString();
        #     if (!($t -cmatch '^[\w]+$')) { $t = '{' + $t.Replace('`','``').Replace('{','`{').Replace('}','`}') + '}' }
        #     $NodeString[$curId] = '$' + $t;
        #     return $false;
        # }
        if ($null -ne $curValue -and -not @([scriptblock]).Contains($curValue.GetType())) {
            if ($curNode.GetType().Name -eq 'CommandParameterAst') { $NodeString[$curId] = $curValue }
            else { $NodeString[$curId] = '(' + (Stringify $curValue) + ')' }
            return $false
        }
    }
    if ($curNode.GetType().Name -eq 'VariableExpressionAst') {
        $t = $curNode.VariablePath.ToString()
        if (!($t -cmatch '^[\w]+$')) { $t = '{' + $t.Replace('`', '``').Replace('{', '`{').Replace('}', '`}') + '}' }
        $NodeString[$curId] = '$' + $t
        return $false
    }
    if ($curNode.GetType().Name -ne 'StringConstantExpressionAst' -and -not ($global:Rule['IGNORE_ASSIGN_LEFT'] -and (InAssignmentLeft $curNode)) -and $null -ne $NodeValue[$curId]) {
        try {
            $NodeString[$curId] = "($(Stringify($NodeValue[$curId])))"
            return $false
        } catch {}
    }
    return $true
}

function PostTraversal ($curNode) {
    $curId = (GetHashCode $curNode)
    if ( $curNode.GetType().Name -eq 'PipelineAst' -and $valuelog[$iexPrefix + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset] -eq 'Foreach-Object' -and `
            $curNode.PipelineElements[-1].CommandElements[-1].GetType().Name -eq 'ScriptBlockExpressionAst') {
        $count = $foreachCount[$iexPrefix + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset]
        $BlockString = $NodeString[(GetHashCode $curNode.PipelineElements[-1].CommandElements[-1].ScriptBlock.EndBlock)]
        if ($count -eq $hookTimes -and -not $BlockString.Contains('$_')) { $NodeString[$curId] = $BlockString }
    }
    if ( $curNode.GetType().Name -eq 'FunctionDefinitionAst' ) {
        $funcDeob[$curNode.Name] = $NodeString[$curId]
        $NodeString[$curId] = $funcDef[$curNode.Name]
    }
}

function CodeFormat ($ScriptString) {
    $tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString, [ref]$null)
    $tokens = $tokens | Sort-Object { - $_.Start }
    $lineflag = $false
    $linestart = 0
    $lineend = 0
    $groupdepth = 0
    $identtype = '    '
    for ($i = 0; $i -lt $tokens.Count; $i++) {
        $token = $tokens[$i]
        if ($token.Type -eq 'GroupEnd') { $groupdepth ++ }
        if ($token.Type -eq 'GroupStart') { $groupdepth -- }
        if (($token.Type -eq 'StatementSeparator' -and $groupdepth -eq 0) -or ($token.Type -eq 'NewLine')) {
            if (!$lineflag) { $lineend = $token.Start + $token.Length; $lineflag = $true; }
        } elseif ($lineflag) {
            $lineflag = $false
            $linestart = $token.Start + $token.Length
            $ScriptString = $ScriptString.SubString(0, $linestart) + "`r`n" + $ScriptString.SubString($lineend)
        }
        if ($token.Type -eq 'Command' -and $tokens[$i + 1] -and @('NewLine', 'LineContinuation').Contains($tokens[$i + 1].Type.ToString())) {
            $ScriptString = $ScriptString.SubString(0, $tokens[$i + 1].Start + $tokens[$i + 1].Length) + $identtype * $groupdepth + $ScriptString.SubString($token.Start)
        }
    }
    return $ScriptString
}

function DeObfuscate ($ScriptString) {
    $Info = @{}
    $Ast = [scriptblock]::Create($ScriptString).Ast
    $Childs = @{}
    $NodeString = @{}
    $NodeValue = @{}
    $funcNodes = [System.Collections.Generic.List[object]]::new()
    $nodes = [object[]]$Ast.FindAll({
            param($node)
            if ($node.Parent) {
                $parId = (GetHashCode $node.Parent)
                if (!$Childs[$parId]) { $Childs[$parId] = [System.Collections.ArrayList]@(); }
                if (-not @('ParamBlockAst', 'FunctionDefinitionAst', 'DataStatementAst').Contains($node.GetType().Name)) {
                    $Childs[$parId].Add($node)
                }
            }
            $NodeString[(GetHashCode $node)] = $node.Extent.Text
            #if ($node.GetType().Name -eq 'FunctionDefinitionAst') { $funcDef[$node.Name + $node.Extent.StartOffset + ',' + $node.Extent.EndOffset] = $node.Extent.Text }
            if ($node.GetType().Name -eq 'FunctionDefinitionAst') {
                $funcDef[$node.Name] = $node.Extent.Text
                $funcNodes.Add($node)
            }
            # if ($node.GetType().Name -eq 'ParamBlockAst' -and $node.Attributes.Count) {
            #     $NodeString[(GetHashCode $node)] = $ScriptString.SubString($node.Attributes[0].Extent.StartOffset, $node.Extent.EndOffset - $node.Attributes[0].Extent.StartOffset)
            #     $Childs[$parId][-1] = @{
            #         Attributes = $node.Attributes
            #         Parameters = $node.Parameters
            #         Extent     = @{
            #             StartOffset = $node.Attributes[0].Extent.StartOffset
            #             EndOffset   = $node.Extent.EndOffset
            #             Text        = $ScriptString.SubString($node.Attributes[0].Extent.StartOffset, $node.Extent.EndOffset - $node.Attributes[0].Extent.StartOffset)
            #         }
            #         Parent     = $node.Parent
            #         HashCode   = (GetHashCode $node)
            #     }
            # }
            return $true
        }, $true)
    $Info['Root'] = (GetHashCode $Ast)
    $Info['Childs'] = [System.Collections.Generic.Dictionary[string, [string[]]]]::new()
    $Info['OriginNodeString'] = [System.Collections.Generic.Dictionary[string, string]]::new()
    $Info['ResultNodeString'] = [System.Collections.Generic.Dictionary[string, string]]::new()
    foreach ($key in $Childs.Keys) {
        try {
            $Info['Childs'][$key] = $Childs[$key] | Sort-Object { $_.Extent.StartOffset } | ForEach-Object { (GetHashCode $_) }
        } catch { $Info['Childs'][$key] = @() }
    }
    foreach ($key in $NodeString.Keys) { $Info['OriginNodeString'][$key] = $NodeString[$key]; }
    $stack = [System.Collections.Stack]@($Ast)
    if ($global:Rule['KEEP_USER_FUNCTION']) { $funcNodes | ForEach-Object { $stack.Push($_) } }
    $visited = @{}
    $user_function_parents = [System.Collections.Generic.HashSet[String]]::new()
    $var_node_parents = [System.Collections.Generic.HashSet[String]]::new()
    $nodes | ForEach-Object { $visited[(GetHashCode $_)] = $false; }
    while ($stack.Count) {
        $curNode = $stack.Pop()
        if ($visited[(GetHashCode $curNode)]) { ValueTraversal -curNode $curNode }
        else {
            $visited[(GetHashCode $curNode)] = $true
            $stack.Push($curNode)
            $Childs[(GetHashCode $curNode)] | Sort-Object { - $_.Extent.StartOffset } | ForEach-Object { $stack.Push($_); }
        }
    }
    #Write-Host $iexPrefix;
    $stack = [System.Collections.Stack]@($Ast)
    if ($global:Rule['KEEP_USER_FUNCTION']) { $funcNodes | ForEach-Object { $stack.Push($_) } }
    $nodes | ForEach-Object { $visited[(GetHashCode $_)] = $false; }
    while ($stack.Count) {
        $curNode = $stack.Pop()
        $curId = (GetHashCode $curNode)
        if ($visited[$curId]) {
            $childnodes = $Childs[$curId] | Sort-Object { - $_.Extent.StartOffset }
            try {
                $childnodes | ForEach-Object {
                    if ($_.Extent.GetType().Name -ne 'EmptyScriptExtent') {
                        $NodeString[$curId] = $NodeString[$curId].SubString(0, $_.Extent.StartOffset - $curNode.Extent.StartOffset) `
                            + $NodeString[(GetHashCode $_)] + $NodeString[$curId].SubString($_.Extent.EndOffset - $curNode.Extent.StartOffset) 
                    } }
            } catch {
                Write-Host -ForegroundColor red 'Substring Failed!'
            }
            PostTraversal -curNode $curNode
        } else {
            $visited[(GetHashCode $curNode)] = $true
            if ($user_function_parents.Contains((GetHashCode $curNode))) { $f = $true }
            else { $f = PreTraversal -curNode $curNode }
            if ($f) {
                $stack.Push($curNode)
                $Childs[$curId] | Sort-Object { $_.Extent.StartOffset } | ForEach-Object { $stack.Push($_); }
            }
        }
    }
    #Write-Host $iexPrefix;
    foreach ($key in $NodeString.Keys) { $Info['ResultNodeString'][$key] = $NodeString[$key]; }
    #$Info|ConvertTo-Json > (''+$Info['Root']+'.json')
    $s = $NodeString[(GetHashCode $Ast)]
    $s = CodeFormat -ScriptString $NodeString[(GetHashCode $Ast)]
    try {
        Import-Module ./PSScriptAnalyzer/1.21.0/PSScriptAnalyzer.psd1
        $s = Invoke-Formatter -ScriptDefinition $s -Settings ./FormatterSettings.psd1
    } catch { Write-Host -ForegroundColor red 'Invoke-Formatter Failed!' }
    return $s
}

$ttt0 = Get-Date

class NaObject {}
$NaObject = [NaObject]::new()
[System.IO.Directory]::SetCurrentDirectory($PWD)
# load sandbox settings
Import-Module ./SandboxSettings.ps1

if ($InputPath -eq '--') { [System.IO.File]::WriteAllText('test.ps1', (Read-Host 'Script')); }
else { Copy-Item $InputPath test.ps1 }

# if ($IsCmd) {
#     [void][System.Reflection.Assembly]::UnsafeLoadFrom((Get-ChildItem ./CmdParser.dll).FullName)
#     $results, $errors = [CmdParser]::parse('test.ps1')
#     Write-Host $errors
#     #$CmdScript = ($results | ForEach-Object { 'powershell.exe ' + (Stringify $_).TrimStart('[string]') }) -join "`n`n"
#     $CmdScript = "#parsed from cmd`n`n" + ($results -join "`n`n")
#     [System.IO.File]::WriteAllText('test.ps1', $CmdScript)
# }

if ($IsCmd) {
    $results = ParseCmd([System.IO.File]::ReadAllText('test.ps1').Split("`n"))
    $CmdScript = "#parsed from cmd`n`n" + ($results -join "`n`n")
    [System.IO.File]::WriteAllText('test.ps1', $CmdScript)
}

#<#
# $script0=Start-Job {cd  ./invoke-deobfuscation/Code/;Import-Module ./Invoke-DeObfuscation.psd1;DeObfuscatedMain -ScriptPath0 ../../test.ps1}|Wait-Job -Timeout 30|Receive-Job
# if($script0){$script0 > test.ps1}
# else{Write-Host -ForegroundColor red "Script Recovery Failed!"}
$OriginScript = [System.IO.File]::ReadAllText('test.ps1')
$infos = @()
$hookTimes = 1
for ($i = 0; $i -lt $hookTimes; $i++) {
    $PowerShell = [powershell]::Create()
    [void]$PowerShell.AddScript([scriptblock]::Create($OriginScript))
    $PowerShell.InvokeDeobfuscation(30)
    $PowerShell.EndDeobfuscation()
    if ($Powershell.isTimeOut()) { Write-Host -ForegroundColor red 'Sandbox timeout!' }
    $infos += $PowerShell.ObtainLogs()
}
# Write-Host (Get-Date)
# Start-Sleep 30
# Write-Host (Get-Date)
$valuelog = @{}
$foreachCount = @{}
$funcCount = @{}
$funcDef = @{}
$funcDeob = @{}
foreach ($info in $infos) {
    if ($info.output -and $info.astType -eq 'ExpandableStringExpressionAst') { continue; }
    $prefix = ''
    if ($info.iexOffset) { $prefix = -join ($info.iexOffset | Sort-Object { - $info.iexOffset.IndexOf($_) } | ForEach-Object { '[{0},{1}]' -f $_[0], $_[1] }); }
    if ($info.output) { $key = $prefix + 'o' + $info.startOffset + ',' + $info.endOffset; }
    else { $key = $prefix + $info.astType + $info.startOffset + ',' + $info.endOffset; }
    try {
        if ($valuelog[$key] -and ([System.Management.Automation.PSSerializer]::Serialize($valuelog[$key])) -ne ([System.Management.Automation.PSSerializer]::Serialize($info))) { $valuelog[$key] = $NaObject; }
        else { $valuelog[$key] = $info; }
    } catch {
        if ($valuelog[$key] -and (Stringify $valuelog[$key] $false) -ne (Stringify $info $false)) { $valuelog[$key] = $NaObject; }
        else { $valuelog[$key] = $info; }
    } 
    if ($info.commandName -eq 'ForEach-Object') { $foreachCount[$prefix + $info.startOffset + ',' + $info.endOffset] += 1 }
    if ($info.commandType -eq 'Function') { $funcCount[$info.commandName] += 1 }
}
$infos = $valuelog.Values | Where-Object { $_ -ne $NaObject }
$valuelog = @{}
foreach ($info in $infos) {
    $prefix = ''
    if ($info.iexOffset) { $prefix = -join ($info.iexOffset | Sort-Object { - $info.iexOffset.IndexOf($_) } | ForEach-Object { '[{0},{1}]' -f $_[0], $_[1] }); }
    if ($info.output) {
        #if ($info.astType -eq 'UnaryExpressionAst') { continue; }
        #if ($info.astType -eq 'CommandAst' -and $info.commandType -eq 'Function') { continue; }
        $t = $info.output.value
        try { Stringify ($t) | Out-Null; $valuelog[$prefix + 'o' + $info.startOffset + ',' + $info.endOffset] = $t; } catch {}
    } elseif ($info.astType -eq 'AssignmentStatementAst' -and (NotNaObject $info.value)) {
        $t = $info.value
        try { Stringify ($t) | Out-Null; $valuelog[$prefix + 'a' + $info.startOffset + ',' + $info.endOffset] = $t; } catch {}
    } elseif ($info.astType -eq 'InvokeMemberExpressionAst') {
        if ((NotNaObject $info.baseObject) -and $valuelog[$prefix + 'b' + $info.startOffset + ',' + $info.endOffset] -ne $NAObject) {
            $t = $info.baseObject
            try {
                $s = Stringify ($t)
                $valuelog[$prefix + 'b' + $info.startOffset + ',' + $info.endOffset] = '(' + $s + ')'
            } catch { $valuelog[$prefix + 'b' + $info.startOffset + ',' + $info.endOffset] = $NaObject; }
        }
        if ($info.library) {
            try { $valuelog[$prefix + 'L' + $info.startOffset + ',' + $info.endOffset] = "[$([type]$info.library)]"; }
            catch {}
        }
        if ($info.method) { $valuelog[$prefix + 'm' + $info.startOffset + ',' + $info.endOffset] = $info.method; }
        if ($info.invokeCount) { $valuelog[$prefix + 'i' + $info.startOffset + ',' + $info.endOffset] = $info.invokeCount; }
        foreach ($argue in $info.argues) {
            $t = $argue.value
            try {
                $s = Stringify ($t)
                $valuelog[$prefix + $argue.startOffset + ',' + $argue.endOffset] = '(' + $s + ')'
            } catch {}
        }
    } elseif ($info.astType -eq 'CommandAst') { # -and $info.commandType -eq 'Cmdlet') {
        $valuelog[$prefix + $info.startOffset + ',' + $info.endOffset] = $info.commandName
        if ($info.commandType -eq 'Function') { $valuelog[$prefix + 'f' + $info.startOffset + ',' + $info.endOffset] = $true }
        if ((NotNaObject $info.pipeInput)) {
            $t = $info.pipeInput
            try { Stringify ($t) | Out-Null; $valuelog[$prefix + 'p' + $info.startOffset + ',' + $info.endOffset] = $t }
            catch {}
        }
        foreach ($argue in $info.argues) {
            $t = $argue.value
            try { $s = Stringify ($t); } catch { continue; }
            if ($argue.type -eq 'parameter') { $valuelog[$prefix + $argue.startOffset + ',' + $argue.endOffset] = '-' + $t; }
            if ($argue.type -eq 'arguement') { $valuelog[$prefix + $argue.startOffset + ',' + $argue.endOffset] = $t; }
        }
    }
}
$keys = $valuelog.Keys | Where-Object { $valuelog[$_] -is [NaObject] -or "$($valuelog[$_])".Contains('System.Management.Automation.Deobfuscation.NaNObject') }
foreach ($key in $keys) { $valuelog[$key] = $null; }
$global:iexPrefix = ''
$script_txt = DeObfuscate -ScriptString $OriginScript
# $script1=Start-Job {cd  ./invoke-deobfuscation/Code/;Import-Module ./Invoke-DeObfuscation.psd1;DeObfuscatedMain -ScriptPath0 ../../out.ps1}|Wait-Job -Timeout 30|Receive-Job
# if($script1){$script_txt = $script1;}
# else{Write-Host -ForegroundColor red "Script Recovery Failed!"}
if ($OutputPath -eq '--') { Write-Output $script_txt }
else { [System.IO.File]::WriteAllText($OutputPath, $script_txt) }


$ttt1 = Get-Date
#$ttt1 - $ttt0