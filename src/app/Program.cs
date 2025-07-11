// This app starts a new ssh process,
// connect to a remote server, with password authentication,
// and prints current working directory.

using app;

var host = "127.0.0.1";
var port = 56025;
var user = "admin";
var password = "password";

var app = new SshApp(host, port, user, password);
await app.RunAsync();