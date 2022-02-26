#Set SubscriptionID for cmdlets to use in the current session. 
#Ensure running the script against proper subscription.
$SubscriptionID= "a8108c2b-496c-424d-8347-ecc8afb6384c"		
Set-AzContext -Subscription $SubscriptionID
	
$resourceGroupName= "morGolanResourceGroup"
$srcStorageAccountName = "storageacount4a"
$destStorageAccountName = "storageacount4b"
$srcStorageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $srcStorageAccountName).Context
$destStorageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $destStorageAccountName).Context
$srcContainer = "srccontainer"
$destContainer = "destcontainer"

#Create containers for Storage Account A and B
Try {
   
    $containerSrcCheck = Get-AzStorageContainer -Context $srcStorageAccountContext
    $containerDestCheck = Get-AzStorageContainer -Context $destStorageAccountContext
    
    if(($containerSrcCheck -eq $null) -and ($containerDestCheck -eq $null)) {
        
        #Create containers for Storage Accounts A and B
        New-AzStorageContainer -Name $srcContainer -Context $srcStorageAccountContext -Permission blob
        New-AzStorageContainer -Name $destContainer -Context $destStorageAccountContext -Permission blob

        #Fetch StorageContext
        $srcStorageKey = Get-AzStorageAccountKey -Name $srcStorageAccountName ` -ResourceGroupName $resourceGroupName 
        $srcContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName ` -StorageAccountKey $srcStorageKey.Value[0]

        #Upload 100 blobs from local to Storage Account A
        Get-ChildItem -Path C:\MSEC\blobs | Set-AzStorageBlobContent -Container $srcContainer ` -Context $srcContext -Force
        
        #Fetch SAS Tokens to execute azcopy 
        $sourcecontainerContext = New-AzStorageContainerSASToken -Context $srcStorageAccountContext -Name $srcContainer -Permission racwdl -FullUri
        $destcontainerContext = New-AzStorageContainerSASToken -Context $destStorageAccountContext -Name $destContainer -Permission racwdl -FullUri

        #Copy 100 blob from Storage Account A to Storage Account B
        azcopy copy $sourcecontainerContext $destcontainerContext --recursive
    }
}
Catch {
  Write-Host "An Error occurred:"
  Write-Host $_
}