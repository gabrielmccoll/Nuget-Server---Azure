$name = "NugetServer"
$location = "westeurope"
#$subscriptionid = "?????"
#Set-AzureRmContext -SubscriptionId $subscriptionid
New-AzureRMResourceGroup -Name $name -Location $location 
New-AzureRmAppServicePlan -ResourceGroupName $name -Name $name -Location $location -Tier "Free"
New-AzureRmWebApp -ResourceGroupName $name -Name "$name-WA" -Location $location -AppServicePlan $name