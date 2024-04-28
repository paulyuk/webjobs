using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Azure.Storage.Queues;

namespace WebJob1
{

    internal class Program
    {

        static async Task Main()
        {
            //uses Azure.Identity SDK 1.11.0 to match the version used in the WebJob extension template
            var credential = new DefaultAzureCredential();

            // Create a QueueServiceClient using DefaultAzureCredential
            // Uses Azure.Storage.Queues SDK 12.14.0 to match the version used in the WebJob extension template
            var queueServiceClient = new QueueServiceClient(new Uri("https://stwebjobfriday1.queue.core.windows.net/"), credential);

            var builder = new HostBuilder();

                builder.ConfigureServices(services =>
                {
                    // Test DefaultAzureCredential and ManagedIdentityCredential before adding to services
                    services.AddSingleton <TokenCredential> (credential);
                    Console.WriteLine("Credential used: " + credential.ToString()); // should return "Azure.Identity.DefaultAzureCredential"

                    services.AddSingleton<QueueServiceClient>(queueServiceClient);

                    // Test queueServiceClient before adding to services
                    var q = queueServiceClient.GetQueues();
                    foreach (var queue in q)
                    {
                        Console.WriteLine("Queue Test: Found queue with name'" + queue.Name + "'"); // should return "queue"
                    }
                });


                builder.ConfigureWebJobs(b =>
                {
                    b.AddAzureStorageQueues();
                });

            var host = builder.Build();
                using (host)
                {
                    Console.WriteLine("Starting host..."); 

                //throws exception here; Microsoft.Azure.WebJobs.Host.Indexers.FunctionIndexingException: 'Error indexing method 'Functions.ProcessQueueMessage'';
                //ArgumentNullException: Value cannot be null.
                //Parameter name: connectionString
                    await host.RunAsync();
                }
        }
       
    }
}
