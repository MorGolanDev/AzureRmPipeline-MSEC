#Set SubscriptionID for cmdlets to use in the current session. 
#Ensure running the script against proper subscription.
$SubscriptionID= "a8108c2b-496c-424d-8347-ecc8afb6384c"		
Set-AzContext -Subscription $SubscriptionID
	
$resourceGroupName= "morGolanResourceGroup"
$srcStorageAccountName = "storageacount4a"
$destStorageAccountName = "storageacount4b"
$srcStorageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $srcStorageAccountName).Context
$destStorageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $destStorageAccountName).Context
$srcContainer = "srcStorageAccountContainer"
$destContainer = "destStorageAccountContainer"

#Create containers for Storage Account A and B.
Try
{
   $containerSrcCheck = Get-AzStorageContainer -Context $srcStorageAccountContext
   $containerDestCheck = Get-AzStorageContainer -Context $destStorageAccountContext
   Write-Output $containerSrcCheck
   Write-Output $containerDestCheck
}
Catch
{
    #Catch any error
    #The containers are exist
}
Finally
{
    if(($containerSrcCheck -eq $null) -and ($containerDestCheck -eq $null)){
        New-AzStorageContainer -Name $srcContainer -Context $srcStorageAccountContext -Permission blob
        New-AzStorageContainer -Name $destContainer -Context $destStorageAccountContext -Permission blob
    }
}
        
$srcStorageKey = Get-AzStorageAccountKey -Name $srcStorageAccountName `
-ResourceGroupName $resourceGroupName 
$srcContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName `
-StorageAccountKey $srcStorageKey.Value[0] 
#Upload 100 blobs
Get-ChildItem -Path C:\MSEC\blobs | Set-AzStorageBlobContent -Container $srcContainer `
-Context $srcContext -Force
$sourcecontainerContext = New-AzStorageContainerSASToken -Context $srcStorageAccountContext -Name sourcecontainer -Permission racwdl -FullUri
$destcontainerContext = New-AzStorageContainerSASToken -Context $destStorageAccountContext -Name destcontainer -Permission racwdl -FullUri
Write-Output $sourcecontainerContext
Write-Output $destcontainerContext

#Copy 100 blob
azcopy copy "https://storageacount4a.blob.core.windows.net/sourcecontainer?"+$sourcecontainerContext "https://storageacount4b.blob.core.windows.net/destcontainer?"+$destcontainerContext --recursive