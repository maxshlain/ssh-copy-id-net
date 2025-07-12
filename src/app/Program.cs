// This app starts a new ssh process,
// connect to a remote server, with password authentication,
// and prints current working directory.

using app;

// Parse command line arguments
if (args.Length != 4)
{
    Console.WriteLine("Usage: app <host> <port> <username> <password>");
    Console.WriteLine("Example: app 127.0.0.1 22 admin mypassword");
    Environment.Exit(1);
}

var host = args[0];
if (!int.TryParse(args[1], out var port) || port <= 0 || port > 65535)
{
    Console.WriteLine("Error: Port must be a valid integer between 1 and 65535");
    Environment.Exit(1);
}
var user = args[2];
var password = args[3];

// Validate required parameters
if (string.IsNullOrWhiteSpace(host))
{
    Console.WriteLine("Error: Host cannot be empty");
    Environment.Exit(1);
}
if (string.IsNullOrWhiteSpace(user))
{
    Console.WriteLine("Error: Username cannot be empty");
    Environment.Exit(1);
}
if (string.IsNullOrWhiteSpace(password))
{
    Console.WriteLine("Error: Password cannot be empty");
    Environment.Exit(1);
}

var app = new SshApp(host, port, user, password);
await app.RunAsync();