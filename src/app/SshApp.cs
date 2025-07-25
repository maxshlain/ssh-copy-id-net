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

    private string PrintBanner()
    {
        return @$"
    You can connect to your server with
        ssh -p {port} {username}@{host}
";
    }

    private void RunImpl()
    {
        var tester = new ConnectionTester(host, port, username);
        if (tester.CanLoginWithAnyInstalledKey())
        {
            Console.WriteLine("✓ SSH server is reachable with key-based authentication.");
            Console.WriteLine(PrintBanner());
            return;
        }

        using (SshClient client = ComposeSshClientWithPassword())
        {
            RunWithClient(client);
        }
        
        if (tester.CanLoginWithAnyInstalledKey())
        {
            Console.WriteLine("✓ SSH server is reachable with key-based authentication.");
            Console.WriteLine(PrintBanner());
            return;
        }
        
        Console.WriteLine("✗ Failed to set up key-based authentication. Please check the logs above for details.");
    }

    private void RunWithClient(SshClient client)
    {
        Console.WriteLine("Connecting to SSH server...");
        client.Connect();

        if (!client.IsConnected)
        {
            Console.WriteLine("✗ Failed to connect to SSH server.");
            return;
        }

        Console.WriteLine("✓ Successfully connected to SSH server!");

        var description = "create remote .ssh directory if it doesn't exist...";
        var commandText = "mkdir -p ~/.ssh";
        var ok = Execute(client, commandText, description);
        if (!ok) return;

        description = "set correct permissions for .ssh directory...";
        commandText = "chmod 700 ~/.ssh";
        ok = Execute(client, commandText, description);
        if (!ok) return;

        description = "copy public key to remote .ssh directory...\"";
        string publicKeyContent = File.ReadAllText(publicKeyFile).Trim();
        commandText = $"echo \"{publicKeyContent}\" >> ~/.ssh/authorized_keys";
        ok = Execute(client, commandText, description);
        if (!ok) return;

        description = "set correct permissions for authorized_keys file...";
        commandText = "chmod 600 ~/.ssh/authorized_keys";
        ok = Execute(client, commandText, description);
        if (!ok) return;
    }

    private static bool Execute(SshClient client, string commandText, string description)
    {
        SshCommand? command = client.CreateCommand(commandText);
        string? result = command.Execute();

        if (command.ExitStatus == 0)
        {
            string message = $"✓ Successfully {description}";
            string stdout = result?.Trim() ?? string.Empty;
            if (!string.IsNullOrEmpty(stdout))
            {
                message += $"\nOutput: {stdout}";
            }

            Console.WriteLine(message);
            return true;
        }

        string errorMessage = $"✗ Failed to {description}";
        if (!string.IsNullOrEmpty(command.Error))
        {
            errorMessage += $"\nError: {command.Error.Trim()}";
        }

        Console.WriteLine(errorMessage);
        return false;
    }

    private SshClient ComposeSshClientWithPassword()
    {
        var method = new PasswordAuthenticationMethod(username, password);
        var connectionInfo = new ConnectionInfo(host, port, username, method);
        return new SshClient(connectionInfo);
    }
}