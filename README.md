# Azure WebJob Sample using WebJobs SDK 3.x

## Summary
This sample creates an [Azure Webjob](https://learn.microsoft.com/en-us/azure/app-service/webjobs-sdk-how-to) that is a simple queue processor for Azure Storage Queues.  It demonstrates how to use the latest [Azure WebJobs SDK 3.x](https://www.nuget.org/packages/Microsoft.Azure.WebJobs) using the more modern .NET Core style HostBuilder, however it still runs and targets .NET Framework 4.x for maximum backwards compatibility.

## Pre-requisites
1. .NET Framework 4.x (tested with 4.72 & 4.8)
2. [Azurite](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?tabs=visual-studio%2Cblob-storage)
```bash
docker run -d -p 10000:10000 -p 10001:10001 -p 10002:10002 mcr.microsoft.com/azure-storage/azurite
```
3. [Microsoft Azure Storage Explorer](https://storageexplorer.com)
4. Connect to local emulator connection in Storage Explorer -> Queues -> Add Queue container named `queue`
5. [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd?tabs=winget-windows%2Cbrew-mac%2Cscript-linux&pivots=os-windows)
6. Currently Appsettings.json does not work to initialize on .NET 4.x which is needed to use a real Azure storage account with managed idenity, so we recommend running directly using environment variables set on your OS.  Run the following in a terminal before starting your app or IDE.  

### Using Azurite local emulator

Windows
```PowerShell
setx AzureWebJobsStorage__blobServiceUri "UseDevelopmentStorage=true"
setx AzureWebJobsStorage__queueServiceUri "UseDevelopmentStorage=true"
```

Mac/Linux
```Bash
export AzureWebJobsStorage__blobServiceUri "UseDevelopmentStorage=true"
export AzureWebJobsStorage__queueServiceUri "UseDevelopmentStorage=true"
```

### Using Azure Storage with Managed Identity
If you do not have an Azure storage account yet, you can run `azd provision` first which will create all the resources and set the IAM RBAC roles that will be assigned to the managed identity of the app and of your developer machine session. Note you need to replace `MYACCOUNTNAME` with the lowercase name of your storage account.

Windows
```PowerShell
setx AzureWebJobsStorage__blobServiceUri "https://MYACCOUNTNAME.blob.core.windows.net/"
setx AzureWebJobsStorage__queueServiceUri "https://MYACCOUNTNAME.queue.core.windows.net/"
```

Mac/Linux
```Bash
export AzureWebJobsStorage__blobServiceUri "https://MYACCOUNTNAME.blob.core.windows.net/"
export AzureWebJobsStorage__queueServiceUri "https://MYACCOUNTNAME.queue.core.windows.net/"
```

## Running the app
### Visual Studio
1. Open `WebJob1.sln`
2. Press `F5`
3. Add a queue message, e.g. "Got here", to the `queue` container in Storage Explorer

### Command line
Using a new Terminal window:
1. `cd WebJob1`
2.  `dotnet run`
3. Add a queue message, e.g. "Got here", to the `queue` container in Storage Explorer

## Deploying

### AZD (RECOMMENDED, uses infrastructure as code)

To provision and deploy simply:
```bash
azd up
```

To make a simple .zip deployment package (useful for Portal and CI/CD):
```bash
azd package
```

To provision all Azure resources with configuration:
```bash
azd provision
```

To incrementally deploy .zip
```bash
azd deploy
```

### Visual Studio
1. Download the Feature Flags extension and install it (Required for VS version < 17.11)
2. Enable the Publish.EnableAzureADAuth setting (Tools...Options)
3. Restart VS
4. Open `WebJob1.sln`
5. Right-click project, Publish to Azure WebJobs (uses Azure App Service)
