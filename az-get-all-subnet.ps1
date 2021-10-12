$dataFile = New-Item -Path $env:USERPROFILE -Name "azureVnet-$(get-date -Format ddMMyyyy-hhmmss).csv" -Force

$vnetInfoCollection = @()

Get-AzSubscription | Foreach-Object {
  $sub = Set-AzContext -SubscriptionId $_.SubscriptionId
  $vnets = Get-AzVirtualNetwork

  foreach ($vnet in $vnets) {
      $vnetInfo = [PSCustomObject]@{
          Subscription = $sub.Subscription.Name
          Name = $vnet.Name
          Vnet = $vnet.AddressSpace.AddressPrefixes
          Subnets = $vnet.Subnets.AddressPrefix
      }

      $vnetInfoCollection += $vnetInfo
  }
}

$arrCountVnets = @()
$arrCountSubnets = @()

# Loop through each object and append count into the array
foreach ($object in $vnetInfoCollection) {
  $countVnet = $object.Vnet.Count
  $arrCountVnets += [int]$countVnet
  $countSubnet = $object.Subnets.Count
  $arrCountSubnets += [int]$countSubnet
}

# Get max value from array
$maxCountVnet = [int]($arrCountVnets | Measure -Maximum).Maximum
$maxCountSubnet = [int]($arrCountSubnets | Measure -Maximum).Maximum

# Loop through the result and get attribute inside each object
foreach ($object in $vnetInfoCollection) {
  $objVnet = [PSCustomObject]@{
    Subscription    = $object.Subscription
    Name = $object.Name
  }
  # create new object and append IP into the computer object
  for ($i = 0; $i -lt $maxCountVnet; $i++) {
    $keyName = "Vnet$($i)"
    $objVnet | Add-Member NoteProperty $keyName $object.Vnet[$i]
  }
  # create new object and append dns server into the computer object
  if ($object.Subnets.Count -lt 2) {
    $keyName = "Subnet0"
    $objVnet | Add-Member NoteProperty $keyName $object.Subnets
  } else {
    for ($i = 0; $i -lt $maxCountSubnet; $i++) {
      $keyName = "Subnet$($i)"
      $objVnet | Add-Member NoteProperty $keyName $object.Subnets[$i]
    }
  }
  # output data to file and put some text on the console
  $objVnet | Export-Csv -Path $dataFile.FullName -Force -Append -NoTypeInformation
  Write-Output $objVnet 
}