// This app starts a new ssh process,
// connect to a remote server, with password authentication,
// and prints current working directory.

using app;

SshConnectionArgs connectionArgs = ArgumentsParser.Parse(args);
SshApp app = new SshApp(connectionArgs.Host, connectionArgs.Port, connectionArgs.Username, connectionArgs.Password);
app.RunAsync();