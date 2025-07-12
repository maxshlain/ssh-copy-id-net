// This app starts a new ssh process,
// connect to a remote server, with password authentication,
// and prints current working directory.

using app;

SshConnectionArgs connectionArgs = ArgumentsParser.Parse(args);

SshApp app = new SshApp(
    host: connectionArgs.Host,
    port: connectionArgs.Port,
    username: connectionArgs.Username,
    password: connectionArgs.Password,
    publicKeyFile: connectionArgs.PublicKeyFile
);

app.Run();