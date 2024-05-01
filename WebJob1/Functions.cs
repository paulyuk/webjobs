using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System.IO;

namespace WebJob1
{
    public class Functions
    {
        // This function will get triggered/executed when a new message is written 
        // on an Azure Queue called queue.
        public static void ProcessQueueMessage([QueueTrigger("queue", Connection = "AzureWebJobsStorage")] string message, ILogger logger)
        {
            logger.LogInformation($"Message: {message}");
        }
    }
}
