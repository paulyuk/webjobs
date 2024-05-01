using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Azure;

namespace WebJob1
{

    internal class Program
    {

        static async Task Main()
        {
            var credential = new DefaultAzureCredential();

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
                    b.AddEnvironmentVariables();
                });
                builder.ConfigureServices(services =>
                {
                    services.AddSingleton <TokenCredential> (credential);
                    services.AddAzureClients(b =>
                    {
                        var bconn = Environment.GetEnvironmentVariable("AzureWebJobsStorage__blobServiceUri");
                        Console.WriteLine("Blob connection URI: " + bconn);

                        var qconn = Environment.GetEnvironmentVariable("AzureWebJobsStorage__queueServiceUri");
                        Console.WriteLine("Queue connection URI: " + qconn);

                        b.UseCredential(credential).AddBlobServiceClient(bconn);
                        b.UseCredential(credential).AddQueueServiceClient(qconn);

                        Console.WriteLine("Credential used: " + credential.ToString());
                    });
                });
                builder.ConfigureWebJobs(b =>
                {
                    b.AddAzureStorageCoreServices();
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
