using Renci.SshNet;

namespace app;

public class SshApp(string host, int port, string username, string password, string publicKeyFile)
{
    public void Run()
    {
        Console.WriteLine($"Launching SSH connection to {host}:{port}...");

        try
        {
            RunImpl();
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

    private void RunImpl()
    {
        using (SshClient client = ComposeSshClient())
        {
            RunWithClient(client);
        }
    }

    private static void RunWithClient(SshClient client)
    {
        Console.WriteLine("Connecting to SSH server...");
        client.Connect();

        if (!client.IsConnected)
        {
            Console.WriteLine("✗ Failed to connect to SSH server.");
            return;
        }

        Console.WriteLine("✓ Successfully connected to SSH server!");

        var ok = Execute(client, "pwd");
        if (!ok) return;
    }

    private static bool Execute(SshClient client, string commandText)
    {
        SshCommand? command = client.CreateCommand(commandText);
        string? result = command.Execute();

        if (command.ExitStatus == 0)
        {
            string message = "Command executed successfully:\n\t" + result.Trim();
            Console.WriteLine(message);
            return true;
        }

        string errorMessage = $"Command '{commandText}' failed with exit code {command.ExitStatus}.";
        if (!string.IsNullOrEmpty(command.Error))
        {
            errorMessage += $"\nError: {command.Error.Trim()}";
        }

        Console.WriteLine(errorMessage);
        return false;
    }

    private SshClient ComposeSshClient()
    {
        var method = new PasswordAuthenticationMethod(username, password);
        var connectionInfo = new ConnectionInfo(host, port, username, method);
        return new SshClient(connectionInfo);
    }
}