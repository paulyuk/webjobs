using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Azure;
using System.Runtime.Remoting.Contexts;
using Azure.Core.Extensions;
using Azure.Storage.Blobs;
using Azure.Storage.Queues;

namespace WebJob1
{

    internal class Program
    {

        static async Task Main()
        {
            var credential = new DefaultAzureCredential();
            // Create a BlobServiceClient using DefaultAzureCredential
            BlobServiceClient blobServiceClient = new BlobServiceClient(new Uri("https://stwebjobfriday1.blob.core.windows.net/"), credential);
            QueueServiceClient queueServiceClient = new QueueServiceClient(new Uri("https://stwebjobfriday1.queue.core.windows.net/"), credential);

            var builder = new HostBuilder();
                builder.ConfigureLogging((context, b) =>
                {
                    // If the key exists in settings, use it to enable Application Insights.
                    string instrumentationKey = context.Configuration["APPINSIGHTS_INSTRUMENTATIONKEY"];
                    if (!string.IsNullOrEmpty(instrumentationKey))
                    {
                        b.AddApplicationInsightsWebJobs(o => o.InstrumentationKey = instrumentationKey);
                    }

                    b.AddConsole();
                    b.SetMinimumLevel(LogLevel.Information);
                });
                builder.ConfigureAppConfiguration(b =>
                {
                    b.AddJsonFile("appsettings.json");
                });
                builder.ConfigureServices(services =>
                {
                    services.AddSingleton <TokenCredential> (credential);

                    // Workaround, adding blob and queue clients directly with proper managed identity URI and credential; throws 'Microsoft.Azure.WebJobs.Host.Indexers.FunctionIndexingException -> ArgumentNullException: Value cannot be null.Parameter name: connectionString
                    services.AddSingleton<BlobServiceClient>(blobServiceClient);
                    services.AddSingleton<QueueServiceClient>(queueServiceClient);

                    //// Standard way to add Azure clients for Blob and Queue; throws 'Microsoft.Azure.WebJobs.Host.Indexers.FunctionIndexingException -> ArgumentNullException: Value cannot be null.Parameter name: connectionString
                    //services.AddAzureClients(b =>
                    //{
                    //    var blobServiceUri = Environment.GetEnvironmentVariable("AzureWebJobsStorage__blobServiceUri");
                    //    var queueServiceUri = Environment.GetEnvironmentVariable("AzureWebJobsStorage__queueServiceUri");


                    //    b.UseCredential(credential).AddBlobServiceClient(new Uri("https://stwebjobfriday1.blob.core.windows.net/"));
                    //    b.UseCredential(credential).AddQueueServiceClient(new Uri("https://stwebjobfriday1.queue.core.windows.net/"));

                    //    Console.WriteLine("Credential used: " + credential.ToString());
                    //});

                });
                builder.ConfigureWebJobs(b =>
                {
                    b.AddAzureStorageBlobs();
                    b.AddAzureStorageQueues();
                });



            var host = builder.Build();
                using (host)
                {
                    await host.RunAsync();
                }
        }
       
    }
}
