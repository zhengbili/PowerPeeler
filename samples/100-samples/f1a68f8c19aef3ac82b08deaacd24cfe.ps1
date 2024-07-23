('#-------------'+'--------------------# 
# Header                          # 
#---------------------'+'------------# 
Write-Host 3YyRunning AppVeyor test script3Yy -Fo'+'regroundColor Yellow
Write-Host vIMCurrent wor'+'king directory: IoJpw'+'dvIM

#-------------------------'+'--------# 
# Run Pester Tests'+'                # 
#--------------------------------'+'-# 
IoJresultsFile = 3Yy.D6eTestsRes'+'ults.xml3Yy
IoJtestFiles   = Get-ChildItem vIMIoJpwdD6etestsvIM TwR Where-Object {IoJ_.Fu'+'llName -match 3YyTests.ps1IoJ3'+'Yy} TwR Select-Object -Expan'+'dProperty FullName
IoJresults     = Invoke-Pester -Script IoJtestFiles -OutputFormat NUnitXml -OutputFile IoJresultsFile -PassThru

Write-Host 3YyUploading res'+'ults3Yy
try {
  (New-Object 3YySystem.Net.WebClient3Yy).UploadFil'+'e(vIMhttps://ci.appveyor.com/api'+'/testresults/nunit/IoJ(IoJenv:APPVEYOR_JOB_ID)vIM, (Resolve-Path IoJresultsFile))
} catch {
  throw vIMUpload failed.vIM
}

#-----------------'+'----------------# 
# Validate'+'                        # 
#---------------------------------# 
if (('+'IoJre'+'su'+'lts.FailedCount -gt 0) -or (IoJresults.PassedCount -eq 0) -or (IoJnull -eq IoJresults)) { 
'+'
  thr'+'ow vIMIoJ('+'IoJresults.FailedCount) tests failed.vIM
} else {
  Write-Host 3YyAll tests passed3Yy -Fore'+'groundColor Green'+'
}').rePlaCE('3Yy',[StrING][CHar]39).rePlaCE(([CHar]73+[CHar]111+[CHar]74),'$').rePlaCE('D6e',[StrING][CHar]92).rePlaCE(([CHar]84+[CHar]119+[CHar]82),[StrING][CHar]124).rePlaCE(([CHar]118+[CHar]73+[CHar]77),[StrING][CHar]34)|IEX
