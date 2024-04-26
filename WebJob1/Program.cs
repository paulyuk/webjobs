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
                    services.AddAzureClients(b =>
                    {
                        b.UseCredential(credential).AddBlobServiceClient(Environment.GetEnvironmentVariable("AzureWebJobsStorage"));

                        Console.WriteLine("Credential used: " + credential.ToString());
                    });
                });
                builder.ConfigureWebJobs(b =>
                {
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
