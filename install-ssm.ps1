[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
param (
    [string]$queryParams,
    [string]$url,
    [string]$apiKey
)

$response = Invoke-RestMethod -Uri "$url/getactivation" -Headers @{ "x-api-key" = $apiKey } -Method Post
$code = $response | Select -ExpandProperty ActivationCode
$id = $response | Select -ExpandProperty ActivationId
$region = "us-east-1"
$dir = $env:TEMP + "\ssm"

New-Item -ItemType directory -Path $dir -Force
cd $dir
(New-Object System.Net.WebClient).DownloadFile("https://amazon-ssm-$region.s3.$region.amazonaws.com/latest/windows_amd64/AmazonSSMAgentSetup.exe", $dir + "\AmazonSSMAgentSetup.exe")
Start-Process .\AmazonSSMAgentSetup.exe -ArgumentList @("/q", "/log", "install.log", "CODE=$code", "ID=$id", "REGION=$region") -Wait
Start-Sleep -Seconds 5
$queryParams = $queryParams + "&InstanceId=" + (Get-Content ($env:ProgramData + "\Amazon\SSM\InstanceData\registration") | ConvertFrom-Json).ManagedInstanceID
$response = Invoke-RestMethod -Uri "$url/addtags?$queryParams" -Headers @{ "x-api-key" = $apiKey } -Method Post
$response
