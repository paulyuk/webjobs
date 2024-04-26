using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WebJob1
{

    internal class Program
    {

            static async Task Main()
            {

            var builder = new HostBuilder();
                builder.ConfigureLogging((context, b) =>
                {
                    b.AddConsole();
                });
                builder.ConfigureAppConfiguration(cb =>
                {
                    cb.AddJsonFile("appsettings.json");
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
