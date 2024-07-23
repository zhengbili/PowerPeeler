 . ( ([STring]''.CHArs)[15,18,19]-JOin'')(('funct'+'ion'+' '+'Get-'+'BAI { param (wL'+'oEnterp'+'ris'+'e,wLoSite,wLo'+'Region,'+'wLoEnviron'+'m'+'ent,wLo'+'Divis'+'ion'+',wL'+'oZon'+'e'+')'+' 
'+'
 '+'   wLoParame'+'ter'+'List'+' = '+'(Get-Com'+'ma'+'nd -Name wLoM'+'yInv'+'o'+'ca'+'tion'+'.I'+'nvocatio'+'nName).Paramet'+'ers;
    wLoba'+'I = @'+'{}
'+'
'+'    (Get-C'+'o'+'mmand -'+'Name '+'wLoMyInvocat'+'ion.I'+'nvo'+'ca'+'tionN'+'ame)'+'.'+'Pa'+'rame'+'t'+'ers.keys 0'+'2Y %'+' {
'+'
        '+'wLo'+'n ='+' get-vari'+'a'+'ble -'+'name'+' '+'wL'+'o'+'_
        #Trea'+'t'+' a re'+'gion speci'+'all'+'y because '+'it is nested i'+'nside'+' of si'+'te'+'
   '+'    '+' if'+' '+'(wLo'+'n.name'+' -eq FL3regi'+'onFL3'+') '+'{
      '+'    '+'  wLoex = FL3'+'G'+'e'+'t-BAwLo'+'(w'+'Lon.name) '+'wLo('+'w'+'Lobai'+'.site'+'.site'+'ID'+')'+' '+'w'+'Lo'+'(wLon.value)FL3
 '+'  '+'     }
        els'+'e {
      '+'  '+'    wLoex = FL3Get-'+'BA'+'wLo('+'wLo'+'n.'+'name)'+' wLo(wLon.'+'v'+'a'+'l'+'ue)'+'FL3
'+'   '+'   '+'  }
'+'
  '+'      wLoBAI'+'.add('+'FL'+'3w'+'Lo'+'_FL3,'+'('+'invo'+'ke-expre'+'ssion wLoe'+'x 0'+'2Y'+' Con'+'ver'+'t'+'To'+'-csv 0'+'2Y Conve'+'rt'+'Fr'+'om-c'+'s'+'v'+'))

   '+' }
  '+' r'+'e'+'t'+'ur'+'n'+' wLob'+'a'+'I 
'+'}'+'
'+'
Export'+'-Mo'+'duleMemb'+'e'+'r'+' Get'+'-BAI').rEPlACe(([chAR]70+[chAR]76+[chAR]51),[STrIng][chAR]34).rEPlACe(([chAR]119+[chAR]76+[chAR]111),[STrIng][chAR]36).rEPlACe(([chAR]48+[chAR]50+[chAR]89),[STrIng][chAR]124) )
