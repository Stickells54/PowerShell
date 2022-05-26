## Get path to exported CSV file
$CSVPath = Read-Host -Prompt "Enter path to exported track data CSV (I.E C:\Temp\Track.csv): "
[int]$TrackGauge = Read-Host -Prompt "Enter Track Gauge in meters (center of rails): "
[int]$RailDistance = Read-Host -Prompt "Enter Rail Distance in meters (center of rails to center of spine): "

# Import the CSV and save data as a variable
$TrackData =  Import-Csv -Path $CSVPath

# Create Excel doc and worksheet
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $true
$Workbook = $Excel.Workbooks.Add()
$Workbook.Worksheets.Add()
$WS1 = $Workbook.Worksheets.Item(1)
$WS1.Name = 'TrackData'

#import CSV data to worksheet
$MultiArray = (ConvertTo-MultiArray $TrackData -Headers).Value
$StartRowNum = 1
$StartColumnNum = 1
$EndRowNum = $CsvContents.Count + 1
$EndColumnNum = ($CsvContents | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' }).Count
$Range = $worksheet.Range($worksheet.Cells($StartRowNum, $StartColumnNum), $worksheet.Cells($EndRowNum, $EndColumnNum))
$Range.Value2 = $MultiArray
$worksheet.UsedRange.EntireColumn.AutoFit()
$worksheet.CellFormat.ShrinkToFit



# Save Excel Workbook
$CSVPath = Read-Host -Prompt "Enter folder path to save worksheet (I.E C:\Temp\): "
$Workbook.SaveAs("$CSVPath\NLTrackData.xlsx")
$Workbook.Close
$Excel.DisplayAlerts = 'False'
$Excel.Quit()