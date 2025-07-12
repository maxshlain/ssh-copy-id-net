using Renci.SshNet;

namespace app;

public class SshApp(string host, int port, string user, string password)
{
    public void RunAsync()
    {
        Console.WriteLine($"Launching SSH connection to {host}:{port}...");

        try
        {
            RunAsyncImpl();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"✗ SSH connection failed: {ex.Message}");

            // Provide specific error handling for common issues
            if (ex.Message.Contains("Authentication"))
            {
                Console.WriteLine("Please check your username and password.");
            }
            else if (ex.Message.Contains("Connection"))
            {
                Console.WriteLine("Please check the host and port configuration.");
            }

            Console.WriteLine(ex);
        }
    }

    private void RunAsyncImpl()
    {
        // Create connection info with password authentication
        var connectionInfo = new ConnectionInfo(host, port, user,
            new PasswordAuthenticationMethod(user, password));

        // Create SSH client
        using var client = new SshClient(connectionInfo);

        Console.WriteLine("Connecting to SSH server...");
        client.Connect();

        if (!client.IsConnected)
        {
            Console.WriteLine("✗ Failed to connect to SSH server.");
            return;
        }

        Console.WriteLine("✓ Successfully connected to SSH server!");

        var command = client.CreateCommand("pwd");
        var result = command.Execute();

        if (command.ExitStatus != 0)
        {
            Console.WriteLine($"Failed to execute 'pwd' command. Exit code: {command.ExitStatus}");
            if (!string.IsNullOrEmpty(command.Error))
            {
                Console.WriteLine($"Error: {command.Error}");
            }
            return;
        }

        Console.WriteLine($"Current working directory: {result.Trim()}");
    }
}