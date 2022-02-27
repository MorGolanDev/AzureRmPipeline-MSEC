
#Global Variables
$subscriptionId= "a8108c2b-496c-424d-8347-ecc8afb6384c"
$resourceGroupName= "morGolanResourceGroup"
$srcStorageAccountName = "storageaccount4a"
$destStorageAccountName = "storageaccount4b"
$srcStorageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $srcStorageAccountName).Context
$destStorageAccountContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $destStorageAccountName).Context
$srcContainer = "srccontainer"
$destContainer = "destcontainer"

Try {
    #Ensure the script run against our subscription
    Set-AzContext -Subscription $subscriptionId
    
    $containerSrcCheck = Get-AzStorageContainer -Context $srcStorageAccountContext
    $containerDestCheck = Get-AzStorageContainer -Context $destStorageAccountContext
    
    if(($containerSrcCheck -eq $null) -and ($containerDestCheck -eq $null)) {
        
        #Create containers for Storage Accounts A and B
        New-AzStorageContainer -Name $srcContainer -Context $srcStorageAccountContext -Permission blob
        New-AzStorageContainer -Name $destContainer -Context $destStorageAccountContext -Permission blob

        #Fetch StorageContext
        $srcStorageKey = Get-AzStorageAccountKey -Name $srcStorageAccountName ` -ResourceGroupName $resourceGroupName
        $srcContext = New-AzStorageContext -StorageAccountName $srcStorageAccountName ` -StorageAccountKey $srcStorageKey.Value[0]

        #Create 100 text blobs
        $path = "C:\blobs"
        If(!(Test-Path $path)) {
            New-Item -Path $path -ItemType "directory"
            1..100 | foreach { New-Item -Path $path\$_.txt }
        }
    
        #Upload 100 blobs to Storage Account A
        Get-ChildItem -Path $path | Set-AzStorageBlobContent -Container $srcContainer ` -Context $srcContext -Force
        
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