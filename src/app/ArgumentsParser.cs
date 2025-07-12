namespace app;

public class ArgumentsParser
{
    public static SshConnectionArgs Parse(string[] args)
    {
        if (args.Length != 4 && args.Length != 5)
        {
            ShowUsage();
            Environment.Exit(1);
        }

        var host = args[0];
        var portString = args[1];
        var username = args[2];
        var password = args[3];
        var publicKeyFile = args.Length == 5 ? args[4] : null;

        // Validate and parse port
        if (!int.TryParse(portString, out var port) || port <= 0 || port > 65535)
        {
            Console.WriteLine("Error: Port must be a valid integer between 1 and 65535");
            Environment.Exit(1);
        }

        // Validate required parameters
        ValidateParameter(host, "Host");
        ValidateParameter(username, "Username");
        ValidateParameter(password, "Password");

        // Validate public key file if provided
        if (!string.IsNullOrWhiteSpace(publicKeyFile) && !File.Exists(publicKeyFile))
        {
            Console.WriteLine($"Error: Public key file '{publicKeyFile}' does not exist");
            Environment.Exit(1);
        }

        return new SshConnectionArgs
        {
            Host = host,
            Port = port,
            Username = username,
            Password = password,
            PublicKeyFile = publicKeyFile
        };
    }

    private static void ValidateParameter(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            Console.WriteLine($"Error: {parameterName} cannot be empty");
            Environment.Exit(1);
        }
    }

    private static void ShowUsage()
    {
        Console.WriteLine("Usage: app <host> <port> <username> <password> [public_key_file]");
        Console.WriteLine();
        Console.WriteLine("Parameters:");
        Console.WriteLine("  host             - SSH server hostname or IP address");
        Console.WriteLine("  port             - SSH server port (1-65535)");
        Console.WriteLine("  username         - SSH username");
        Console.WriteLine("  password         - SSH password");
        Console.WriteLine("  public_key_file  - (Optional) Path to public key file for key-based authentication");
        Console.WriteLine();
        Console.WriteLine("Examples:");
        Console.WriteLine("  app 127.0.0.1 22 admin mypassword");
        Console.WriteLine("  app example.com 2222 user secretpass ~/.ssh/id_rsa");
        Console.WriteLine("  app 192.168.1.100 22 deploy mypass /home/user/.ssh/deploy_key");
    }
}