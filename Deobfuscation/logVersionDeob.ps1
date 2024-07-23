#阅读配置
$global:Rule = @{
    'CHECK_PRINTABLE_RATE'         = 0.9
    'IGNORE_ASSIGN_LEFT'           = $true
    'IGNORE_SIGNLE_COMMAND_OUTPUT' = $true
    'IGNORE_VARIABLE_ARGUMENT'     = $true
    'STRONG_TYPE'                  = $false
    'MAX_LENGTH'                   = 1000
}

#分析配置
$global:Rule = @{
    'CHECK_PRINTABLE_RATE'         = 0.5; #0
    'IGNORE_ASSIGN_LEFT'           = $true
    'IGNORE_SIGNLE_COMMAND_OUTPUT' = $true; #$false
    'IGNORE_VARIABLE_ARGUMENT'     = $false
    'STRONG_TYPE'                  = $true
    'MAX_LENGTH'                   = 1000000
}

function GetHashCode ($node) {
    if ($node.HashCode) {
        return $node.HashCode 
    }
    return ('{0}-{1}-{2}' -f $node.Extent.StartOffset, $node.Extent.EndOffset, $node.GetHashCode())
}

function GetCmdletPosition ($curNode, $CommandElements) {
    $w = 0
    $i = 1
    while ($i -lt $CommandElements.Count) {
        if ($CommandElements[$i].GetType().Name -eq 'CommandParameterAst' -and $CommandElements[$i + 1].GetType().Name -ne 'CommandParameterAst') {
            $i += 2 
        } elseif ($CommandElements[$i] -eq $curNode) {
            return $w 
        } else {
            $w += 1; $i += 1 
        }
    }
    return -1
}

function InAssignmentLeft ($curNode) {
    while ($curNode.Parent) {
        if ($curNode.Parent.GetType().Name -eq 'AssignmentStatementAst' -and $curNode.Parent.Left -eq $curNode) {
            return $true 
        }
        $curNode = $curNode.Parent
        if ($curNode.GetType().Name -eq 'IndexExpressionAst') {
            return $false 
        }
    }
    return $false
}

function Stringify ($Object) {
    #$global:Object2=$Object;
    if (@([scriptblock]).Contains($Object.GetType()) -or ('RuntimeAssembly') -contains $Object.GetType().Name) {
        throw 'Type denied!' 
    }
    if ($global:Rule['STRONG_TYPE']) {
        $t = (./ConvertTo-Expression.ps1 $Object -Strong -Expand -1 -Depth 3) 
    } else {
        $t = (./ConvertTo-Expression.ps1 $Object -Expand -1 -Depth 3) 
    }
    if ($t -match '\[pscustomobject\]') {
        throw 'pscustomobject denied!' 
    }
    return $t
}

function PreTraversal ($curNode) {
    $curId = (GetHashCode $curNode)
    $NodeValue[$curId] = $curNode.Value
    if ($null -ne $valuelog[$iexPrefix + 'o' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset] -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.GetType().Name -like '*BlockAst') -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.Parent -and $curNode.Parent.GetType().Name -like '*BlockAst') -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.Parent -and $curNode.Parent.GetType().Name -eq 'PipelineAst' -and `
                $curNode.Parent.PipelineElements.Count -eq 1 -and $curNode.Parent.Parent -and $curNode.Parent.Parent.GetType().Name -like '*BlockAst') -and -not `
        ($global:Rule['IGNORE_SIGNLE_COMMAND_OUTPUT'] -and $curNode.Parent -and $curNode.Parent.GetType().Name -eq 'CommandExpressionAst' -and `
                $curNode.Parent.Parent -and $curNode.Parent.Parent.GetType().Name -eq 'PipelineAst' -and $curNode.Parent.Parent.PipelineElements.Count -eq 1 `
                -and $curNode.Parent.Parent.Parent -and $curNode.Parent.Parent.Parent.GetType().Name -like '*BlockAst')) {
        $NodeValue[$curId] = $valuelog[$iexPrefix + 'o' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
    } elseif ($curNode.Parent -and $curNode.Parent.Right -eq $curNode -and $null -ne $valuelog[$iexPrefix + 'a' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
        $NodeValue[$curId] = $valuelog[$iexPrefix + 'a' + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
    } elseif ($curNode.GetType().Name -eq 'TypeExpressionAst') {
        try {
            $NodeValue[$curId] = [type]($curNode.TypeName.FullName) 
        } catch {
        }
    } elseif ($curNode.GetType().Name -eq 'CommandExpressionAst') {
        $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Expression)] 
    } elseif ($curNode.GetType().Name -eq 'ParenExpressionAst') {
        $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Pipeline)] 
    } elseif ($curNode.GetType().Name -eq 'PipelineAst' -and $curNode.PipelineElements.Count -eq 1) {
        $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.PipelineElements[0])] 
    }
    # elseif ($curNode.GetType().Name -eq 'BinaryExpressionAst' -and $null -ne $NodeValue[(GetHashCode $curNode.Left)] -and $null -ne $NodeValue[(GetHashCode $curNode.Right)]) {
    #    if ($curNode.Operator -eq 'Plus') { $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Left)] + $NodeValue[(GetHashCode $curNode.Right)]; }
    # }
    elseif ($curNode.GetType().Name -eq 'MemberExpressionAst' -and $NodeValue[(GetHashCode $curNode.Expression)] -and $NodeValue[(GetHashCode $curNode.Member)]) {
        if ($curNode.Static) {
            $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Expression)]::($NodeValue[(GetHashCode $curNode.Member)]) 
        } else {
            $NodeValue[$curId] = $NodeValue[(GetHashCode $curNode.Expression)].($NodeValue[(GetHashCode $curNode.Member)]) 
        }
    }
}

function PostTraversal ($curNode) {
    $curId = (GetHashCode $curNode)
    $parNode = $curNode.Parent
    # if ($curNode.GetType().Name -eq 'TypeExpressionAst' -and $NodeValue[$curId]) {
    #     $NodeString[$curId] = "[$($NodeValue[$curId])]";
    #     return $false;
    # }
    if ($parNode.Member -eq $curNode -and $NodeValue[$curId] -and $NodeValue[(GetHashCode $parNode.Expression)]) {
        if ($parNode.Static) {
            $t = ($NodeValue[(GetHashCode $parNode.Expression)] | Get-Member -Static | Where-Object { $_.Name -eq $NodeValue[$curId] }).Name 
        } else {
            $t = ($NodeValue[(GetHashCode $parNode.Expression)] | Get-Member | Where-Object { $_.Name -eq $NodeValue[$curId] }).Name 
        }
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
                for ($i = 0; $i -lt $valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; $i++) {
                    $t = $t.Expression 
                }
                $nodes = $Childs[(GetHashCode $parNode)]
                $nodes[$nodes.IndexOf($curNode)] = @{ HashCode = $curId; Extent = @{ StartOffset = $curNode.Extent.StartOffset; EndOffset = $t.Extent.EndOffset; } }
            }
            return $false
        } elseif (($curNode -eq $parNode.Expression) -and $valuelog[$iexPrefix + 'L' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + 'L' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]
            if ($valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                $t = $curNode
                for ($i = 0; $i -lt $valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; $i++) {
                    $t = $t.Expression 
                }
                $nodes = $Childs[(GetHashCode $parNode)]
                $nodes[$nodes.IndexOf($curNode)] = @{ HashCode = $curId; Extent = @{ StartOffset = $curNode.Extent.StartOffset; EndOffset = $t.Extent.EndOffset; } }
            }
            return $false
        } elseif (($curNode -eq $parNode.Member) -and $valuelog[$iexPrefix + 'm' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + 'm' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]
            if ($valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                $t = $parNode
                for ($i = 0; $i -lt $valuelog[$iexPrefix + 'i' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; $i++) {
                    $t = $t.Expression 
                }
                if ($valuelog[$iexPrefix + 'b' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset] -or $valuelog[$iexPrefix + 'L' + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
                    $nodes = $Childs[(GetHashCode $parNode)]
                    $nodes[$nodes.IndexOf($curNode)] = @{ HashCode = $curId; Extent = @{ StartOffset = $t.Member.Extent.StartOffset; EndOffset = $curNode.Extent.EndOffset; } }
                } else {
                    $NodeString[$curId] = 'Invoke' 
                }
            }
            return $false
        } elseif ($valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
            if ($global:Rule['IGNORE_VARIABLE_ARGUMENT'] -and $curNode.GetType().Name -eq 'VariableExpressionAst') {
                $t = $curNode.VariablePath.ToString()
                if (!($t -cmatch '^[\w]+$')) {
                    $t = '{' + $t.Replace('`', '``').Replace('{', '`{').Replace('}', '`}') + '}' 
                }
                $NodeString[$curId] = '$' + $t
                return $false
            }
            $NodeString[$curId] = $valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
            return $false
        }
    }
    if (($curNode -eq $parNode.Member) -and $NodeValue[$curId] -and $NodeValue[$curId] -cmatch '^[0-9a-zA-Z_]*$') {
        $NodeString[$curId] = $NodeValue[$curId]; return $false 
    }
    if ($curNode.GetType().Name -eq 'PipelineAst' -and $valuelog[$iexPrefix + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset] -eq 'Invoke-Expression' -and $curNode.PipelineElements[-1].CommandElements.Count -eq 1 -and `
            $valuelog[$iexPrefix + 'p' + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset]) {
        $ScriptString = Invoke-Expression $valuelog[$iexPrefix + 'p' + $curNode.PipelineElements[-1].Extent.StartOffset + ',' + $curNode.PipelineElements[-1].Extent.EndOffset]
        try {
            $global:iexPrefix += '[{0},{1}]' -f $curNode.PipelineElements[-1].Extent.StartOffset, $curNode.PipelineElements[-1].Extent.EndOffset
            $NodeString[$curId] = DeObfuscate -ScriptString $ScriptString
        } catch {
            Write-Host (Out-String -InputObject $Error[0])
            $NodeString[$curId] = $ScriptString
        }
        $global:iexPrefix = $global:iexPrefix.Remove($global:iexPrefix.length - ('[{0},{1}]' -f $curNode.PipelineElements[-1].Extent.StartOffset, $curNode.PipelineElements[-1].Extent.EndOffset).length)
        return $false
    }
    if ($curNode.GetType().Name -eq 'CommandAst' -and $valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset] -eq 'Invoke-Expression' -and `
        ($curNode.CommandElements.Count -eq 2 -or ($curNode.CommandElements.Count -eq 3 -and $valuelog[$iexPrefix + $curNode.CommandElements[1].Extent.StartOffset + ',' + $curNode.CommandElements[1].Extent.EndOffset] -eq '-Command')) `
            -and $valuelog[$iexPrefix + $curNode.CommandElements[-1].Extent.StartOffset + ',' + $curNode.CommandElements[-1].Extent.EndOffset]) {
        $ScriptString = Invoke-Expression $valuelog[$iexPrefix + $curNode.CommandElements[-1].Extent.StartOffset + ',' + $curNode.CommandElements[-1].Extent.EndOffset]
        try {
            $global:iexPrefix += '[{0},{1}]' -f $curNode.Extent.StartOffset, $curNode.Extent.EndOffset
            $NodeString[$curId] = DeObfuscate -ScriptString $ScriptString
        } catch {
            Write-Host (Out-String -InputObject $Error[0])
            $NodeString[$curId] = $ScriptString
        }
        $global:iexPrefix = $global:iexPrefix.Remove($global:iexPrefix.length - ('[{0},{1}]' -f $parNode.Extent.StartOffset, $parNode.Extent.EndOffset).length)
        return $false
    } elseif ($parNode -and $parNode.GetType().Name -eq 'CommandAst' -and $parNode.CommandElements -contains $curNode) {
        $w = $parNode.CommandElements.IndexOf($curNode)
        if ($w -eq 0 -and $valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset]; return $false 
        } elseif ($valuelog[$iexPrefix + $parNode.Extent.StartOffset + ',' + $parNode.Extent.EndOffset] -eq 'Invoke-Expression' -and `
            ((GetCmdletPosition $curNode $parNode.CommandElements) -eq 0 -or $valuelog[$iexPrefix + $parNode.CommandElements[$w - 1].Extent.StartOffset + ',' + $parNode.CommandElements[$w - 1].Extent.EndOffset] -eq '-Command') `
                -and $valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
            $ScriptString = Invoke-Expression $valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]
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
        if ($valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]) {
            $NodeString[$curId] = $valuelog[$iexPrefix + $curNode.Extent.StartOffset + ',' + $curNode.Extent.EndOffset]; return $false 
        }
    }
    if ($curNode.GetType().Name -eq 'VariableExpressionAst') {
        $t = $curNode.VariablePath.ToString()
        if (!($t -cmatch '^[\w]+$')) {
            $t = '{' + $t.Replace('`', '``').Replace('{', '`{').Replace('}', '`}') + '}' 
        }
        $NodeString[$curId] = '$' + $t
        return $false
    }
    if ($curNode.GetType().Name -ne 'StringConstantExpressionAst' -and -not ($global:Rule['IGNORE_ASSIGN_LEFT'] -and (InAssignmentLeft $curNode)) -and $null -ne $NodeValue[$curId]) {
        try {
            $NodeString[$curId] = "($(Stringify($NodeValue[$curId])))"; return $false 
        } catch {
        }
    }
    return $true
}

function CodeFormat ($ScriptString) {
    $tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString, [ref]$null)
    $tokens = $tokens | Sort-Object { - $_.start }
    $lineflag = $false
    $linestart = 0
    $lineend = 0
    for ($i = 0; $i -lt $tokens.Count; $i++) {
        $token = $tokens[$i]
        if (($token.type -eq 'StatementSeparator') -or ($token.type -eq 'NewLine')) {
            if (!$lineflag) {
                $lineend = $token.start + $token.length; $lineflag = $true 
            }
        } elseif ($lineflag) {
            $lineflag = $false
            $linestart = $token.start + $token.length
            $ScriptString = $ScriptString.SubString(0, $linestart) + "`r`n" + $ScriptString.SubString($lineend)
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
    $nodes = [object[]]$Ast.FindAll({
            param($node)
            if ($node.Parent) {
                $parId = (GetHashCode $node.Parent)
                if (!$Childs[$parId]) {
                    $Childs[$parId] = [System.Collections.ArrayList]@() 
                }
                if ($node.GetType().Name -ne 'ParamBlockAst') {
                    $Childs[$parId].Add($node)
                }
            }
            $NodeString[(GetHashCode $node)] = $node.Extent.Text
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
    $Info['Childs'] = [System.Collections.Generic.Dictionary[string, [string[]]]]@{}
    $Info['OriginNodeString'] = [System.Collections.Generic.Dictionary[string, string]]@{}
    $Info['ResultNodeString'] = [System.Collections.Generic.Dictionary[string, string]]@{}
    foreach ($key in $Childs.Keys) {
        $Info['Childs'][$key] = $Childs[$key] | Sort-Object { $_.Extent.StartOffset } | ForEach-Object { (GetHashCode $_) } 
    }
    foreach ($key in $NodeString.Keys) {
        $Info['OriginNodeString'][$key] = $NodeString[$key] 
    }
    $stack = [System.Collections.Stack]@($Ast)
    $visited = @{}
    $nodes | ForEach-Object { $visited[(GetHashCode $_)] = $false; }
    while ($stack.Count) {
        $curNode = $stack.Pop()
        if ($visited[(GetHashCode $curNode)]) {
            PreTraversal -curNode $curNode 
        } else {
            $visited[(GetHashCode $curNode)] = $true
            $stack.Push($curNode)
            $Childs[(GetHashCode $curNode)] | Sort-Object { - $_.Extent.StartOffset } | ForEach-Object { $stack.Push($_); }
        }
    }
    #Write-Host $iexPrefix;
    $stack = [System.Collections.Stack]@($Ast)
    $nodes | ForEach-Object { $visited[(GetHashCode $_)] = $false; }
    while ($stack.Count) {
        $curNode = $stack.Pop()
        #Write-Host $curNode.Extent.Text.SubString(0,100);
        $curId = (GetHashCode $curNode)
        if ($visited[$curId]) {
            $childnodes = $Childs[$curId] | Sort-Object { - $_.Extent.StartOffset }
            try {
                $childnodes | ForEach-Object {
                    if ($_.Extent.GetType().Name -ne 'EmptyScriptExtent') {
                        $NodeString[$curId] = $NodeString[$curId].SubString(0, $_.Extent.StartOffset - $curNode.Extent.StartOffset) `
                            + $NodeString[(GetHashCode $_)] + $NodeString[$curId].SubString($_.Extent.EndOffset - $curNode.Extent.StartOffset) 
                    } }
                # if($NodeString[$curId].Contains('UzYuBvkv99')){
                #     Write-Host $curId
                #     Write-Host (Out-String -InputObject $curNode) #.SubString(0,100)
                #     Write-Host ($NodeString[$curId] + ' '*100) #.SubString(0,100)
                #     Write-Host
                # }
            } catch {
                Write-Host 'Substring Failed!'
            }
        } else {
            $visited[(GetHashCode $curNode)] = $true
            $f = PostTraversal -curNode $curNode
            if ($f) {
                $stack.Push($curNode)
                $Childs[$curId] | Sort-Object { $_.Extent.StartOffset } | ForEach-Object { $stack.Push($_); }
            }
        }
    }
    #Write-Host $iexPrefix;
    foreach ($key in $NodeString.Keys) {
        $Info['ResultNodeString'][$key] = $NodeString[$key] 
    }
    #$Info|ConvertTo-Json > (''+$Info['Root']+'.json')
    $s = $NodeString[(GetHashCode $Ast)]
    $s = CodeFormat -ScriptString $NodeString[(GetHashCode $Ast)]
    try {
        $s = Invoke-Formatter -ScriptDefinition $s -Settings ./FormatterSettings.psd1
    } catch {
        Write-Host 'Invoke-Formatter Failed!' 
    }
    return $s
}

class NaObject {
}
$NaObject = [NaObject]::new()
$Formatter = [Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new()
[System.IO.Directory]::SetCurrentDirectory($PWD)

if ($IsLinux) {
    $pwshLocation = '../src2/powershell-unix/bin/Debug/net7.0/linux-x64/publish/pwsh' 
} else {
    $pwshLocation = '../src2/powershell-win-core/bin/Debug/net7.0/win7-x64/publish/pwsh.exe' 
}
$filenames = Get-ChildItem unittest.ps1
$filenames = Get-ChildItem ..\samples\all\ca28502d0796fa764a109a549fc14c3b
$result_dir = 'D:/all-res/'
$times0 = @{}
$times1 = @{}
$errorfiles = [System.Collections.Generic.List[string]]@()
#$ErrorActionPreference='Inquire';
#Import-Module ../Deobfuscation/PSScriptAnalyzer/1.21.0/PSScriptAnalyzer.psd1

foreach ($filename in $filenames) {
    #foreach ($filename in $filenames[($filenames.Name.IndexOf('-1') + 1)..($filenames.length)]) {
    Write-Host $filename.Name
    $t0 = Get-Date
    if (Test-Path ../sandbox/log.txt) {
        Remove-Item ../sandbox/log.txt 
    }
    Copy-Item ($filename.FullName) test.ps1
    <#
    # $script0=Start-Job {cd  ./invoke-deobfuscation/Code/;Import-Module ./Invoke-DeObfuscation.psd1;DeObfuscatedMain -ScriptPath0 ../../test.ps1}|Wait-Job -Timeout 30|Receive-Job
    # if($script0){$script0 > test.ps1}
    # else{Write-Host "静态反混淆失败！"}
    $exe = Start-Process -FilePath $pwshLocation -ArgumentList '../Deobfuscation/test.ps1' -WorkingDirectory '../sandbox/' -PassThru;# -WindowStyle 'Hidden'
    try{Wait-Process -Id $exe.Id -Timeout 30 -ErrorAction 'Stop';}
    catch{
        Write-Host "Sandbox Timeout!";
        $exe.Kill();
        sleep 1;
    }
    if(((Get-Process).ProcessName|Where-Object{$_ -eq 'pwsh'}).Count -gt 1){
        Write-Host 'Bug!';
    }
    if(Test-Path ../sandbox/log.txt){Copy-Item ../sandbox/log.txt ($result_dir + $filename.Name + '.log1')}
    $exe = Start-Process -FilePath $pwshLocation -ArgumentList '../Deobfuscation/test.ps1' -WorkingDirectory '../sandbox/' -PassThru;# -WindowStyle 'Hidden'
    try{Wait-Process -Id $exe.Id -Timeout 30 -ErrorAction 'Stop';}
    catch{
        Write-Host "Sandbox Timeout!";
        $exe.Kill();
        sleep 1;
    }
    if(((Get-Process).ProcessName|Where-Object{$_ -eq 'pwsh'}).Count -gt 1){
        Write-Host 'Bug!';
    }
    if(Test-Path ../sandbox/log.txt){Copy-Item ../sandbox/log.txt ($result_dir + $filename.Name + '.log2')}
    #>
    $t1 = Get-Date

    try {
        $lines = @()
        if (Test-Path ($result_dir + $filename.Name + '.log')) {
            $lines += Get-Content ($result_dir + $filename.Name + '.log')
        }
        if (Test-Path ($result_dir + $filename.Name + '.log1')) {
            $lines += Get-Content ($result_dir + $filename.Name + '.log1')
        }
        if (Test-Path ($result_dir + $filename.Name + '.log2')) {
            $lines += Get-Content ($result_dir + $filename.Name + '.log2')
        }
        $valuelog = @{}
        foreach ($line in $lines) {
            if ($line.length -ge 10000000) {
                continue 
            }
            try {
                $info = ConvertFrom-Json $line 
            } catch {
                continue 
            }
            if ($info.output) {
                $key = 'o' + $info.StartOffset + ',' + $info.EndOffset 
            } else {
                $key = $info.astType + $info.StartOffset + ',' + $info.EndOffset 
            }
            if ($valuelog[$key] -and $valuelog[$key] -ne $line) {
                $valuelog[$key] = $NaObject 
            } else {
                $valuelog[$key] = $line 
            }
        }
        $infos = $valuelog.Values
        $valuelog = @{}
        foreach ($info in $infos) {
            try {
                $info = ConvertFrom-Json $info 
            } catch {
                continue 
            }
            $prefix = ''
            if ($info.iexOffset) {
                $prefix = -join ($info.iexOffset | Sort-Object { - $info.iexOffset.IndexOf($_) } | ForEach-Object { '[{0},{1}]' -f $_[0], $_[1] }) 
            }
            if ($info.output) {
                if ($info.output.Value.StartsWith('<')) {
                    $t = [Management.Automation.PSSerializer]::DeSerialize($info.output.Value)
                    if ($info.output.valueType -eq 'System.RuntimeType') {
                        try {
                            $t = [type]($t.FullName) 
                        } catch {
                        } 
                    }
                    #try { $t = $t -as [type]$info.output.valueType; } catch { continue; }
                } else {
                    $t = $Formatter.DeSerialize([System.IO.MemoryStream]::new([System.Convert]::FromBase64String($info.output.Value))) 
                }
                try {
                    Stringify ($t) | Out-Null; $valuelog[$prefix + 'o' + $info.StartOffset + ',' + $info.EndOffset] = $t 
                } catch {
                }
            } elseif ($info.astType -eq 'AssignmentStatementAst' -and $info.Value) {
                if ($info.Value.StartsWith('<')) {
                    $t = [Management.Automation.PSSerializer]::DeSerialize($info.Value)
                    if ($info.valueType -eq 'System.RuntimeType') {
                        try {
                            $t = [type]($t.FullName) 
                        } catch {
                        } 
                    }
                    #try { $t = $t -as [type]$info.valueType; } catch { continue; }
                } else {
                    $t = $Formatter.DeSerialize([System.IO.MemoryStream]::new([System.Convert]::FromBase64String($info.Value))) 
                }
                try {
                    Stringify ($t) | Out-Null; $valuelog[$prefix + 'a' + $info.StartOffset + ',' + $info.EndOffset] = $t 
                } catch {
                }
            } elseif ($info.astType -eq 'InvokeMemberExpressionAst') {
                if ($info.baseObject -and $valuelog[$prefix + 'b' + $info.StartOffset + ',' + $info.EndOffset] -ne $NAObject) {
                    if ($info.baseObject.StartsWith('<')) {
                        $t = [Management.Automation.PSSerializer]::DeSerialize($info.baseObject)
                        if ($info.baseObjectType -eq 'System.RuntimeType') {
                            try {
                                $t = [type]($t.FullName) 
                            } catch {
                            } 
                        }
                    } else {
                        $t = $Formatter.DeSerialize([System.IO.MemoryStream]::new([System.Convert]::FromBase64String($info.baseObject))) 
                    }
                    try {
                        $s = Stringify ($t)
                        $valuelog[$prefix + 'b' + $info.StartOffset + ',' + $info.EndOffset] = '(' + $s + ')'
                    } catch {
                        $valuelog[$prefix + 'b' + $info.StartOffset + ',' + $info.EndOffset] = $NaObject 
                    }
                }
                if ($info.library) {
                    try {
                        $valuelog[$prefix + 'L' + $info.StartOffset + ',' + $info.EndOffset] = "[$([type]$info.library)]" 
                    } catch {
                    }
                }
                if ($info.method) {
                    $valuelog[$prefix + 'm' + $info.StartOffset + ',' + $info.EndOffset] = $info.method 
                }
                if ($info.invokeCount) {
                    $valuelog[$prefix + 'i' + $info.StartOffset + ',' + $info.EndOffset] = $info.invokeCount 
                }
                foreach ($argue in $info.argues) {
                    if ($argue.Value.StartsWith('<')) {
                        $t = [Management.Automation.PSSerializer]::DeSerialize($argue.Value)
                        if ($argue.valueType -eq 'System.RuntimeType') {
                            try {
                                $t = [type]($t.FullName) 
                            } catch {
                            } 
                        }
                        #try { $t = $t -as [type]$argue.valueType; } catch { continue; }
                    } else {
                        $t = $Formatter.DeSerialize([System.IO.MemoryStream]::new([System.Convert]::FromBase64String($argue.Value))) 
                    }
                    try {
                        $s = Stringify ($t) 
                    } catch {
                        continue 
                    }
                    if ($argue.valueType) {
                        $valuelog[$prefix + $argue.StartOffset + ',' + $argue.EndOffset] = '(' + $s + ')' 
                    }
                }
            } elseif ($info.astType -eq 'CommandAst' -and $info.commandType -eq 'Cmdlet') {
                $valuelog[$prefix + $info.StartOffset + ',' + $info.EndOffset] = $info.commandName
                if ($info.pipeInput) {
                    if ($info.pipeInput.StartsWith('<')) {
                        $t = [Management.Automation.PSSerializer]::DeSerialize($info.pipeInput)
                        if ($info.pipeInputType -eq 'System.RuntimeType') {
                            try {
                                $t = [type]($t.FullName) 
                            } catch {
                            } 
                        }
                        #try { $t = $t -as [type]$info.pipeInputType; } catch { continue; }
                    } else {
                        $t = $Formatter.DeSerialize([System.IO.MemoryStream]::new([System.Convert]::FromBase64String($info.pipeInput))) 
                    }
                    try {
                        $s = Stringify ($t)
                        $valuelog[$prefix + 'p' + $info.StartOffset + ',' + $info.EndOffset] = '(' + $s + ')'
                    } catch {
                        $valuelog[$prefix + 'p' + $info.StartOffset + ',' + $info.EndOffset] = 0 
                    }
                }
                foreach ($argue in $info.argues) {
                    if ($argue.Value.StartsWith('<')) {
                        $t = [Management.Automation.PSSerializer]::DeSerialize($argue.Value)
                        if ($argue.valueType -eq 'System.RuntimeType') {
                            try {
                                $t = [type]($t.FullName) 
                            } catch {
                            } 
                        }
                        #try { $t = $t -as [type]$argue.valueType; } catch { continue; }
                    } else {
                        $t = $Formatter.DeSerialize([System.IO.MemoryStream]::new([System.Convert]::FromBase64String($argue.Value))) 
                    }
                    try {
                        $s = Stringify ($t) 
                    } catch {
                        continue 
                    }
                    if ($argue.type -eq 'parameter') {
                        $valuelog[$prefix + $argue.StartOffset + ',' + $argue.EndOffset] = '-' + $t 
                    }
                    if ($argue.type -eq 'arguement') {
                        $valuelog[$prefix + $argue.StartOffset + ',' + $argue.EndOffset] = '(' + $s + ')' 
                    }
                }
            }
        }
        $keys = $valuelog.Keys | Where-Object { $valuelog[$_] -is [NaObject] -or "$($valuelog[$_])".Contains('System.Management.Automation.Deobfuscation.NaNObject') }
        foreach ($key in $keys) {
            $valuelog[$key] = $null 
        }
        $global:iexPrefix = ''
        $script_txt = DeObfuscate -ScriptString ([System.IO.File]::ReadAllText('test.ps1'))
        $script_txt > out.ps1
        # $script1=Start-Job {cd  ./invoke-deobfuscation/Code/;Import-Module ./Invoke-DeObfuscation.psd1;DeObfuscatedMain -ScriptPath0 ../../out.ps1}|Wait-Job -Timeout 30|Receive-Job
        # if($script1){$script_txt = $script1;}
        # else{Write-Host "静态反混淆失败！"}
        [System.IO.File]::WriteAllText($result_dir + $filename.Name, $script_txt)
        $t2 = Get-Date
        $times0[$filename.Name] = $t1 - $t0
        $times1[$filename.Name] = $t2 - $t1
    } catch {
        Write-Host (Out-String -InputObject $Error[0])
        $errorfiles.Add($filename.Name)
    }

    #Write-Host $filename.Name,([System.Text.RegularExpressions.Rgex]::Matches($script_txt,"ip:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"));
}
