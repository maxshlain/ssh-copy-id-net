namespace app;

public class ConnectionTester(string host, int port, string username)
{
    public bool CanLoginWithAnyInstalledKey()
    {
        try
        {
            return CanLoginWithAnyInstalledKeyImpl();
        }
        catch (Exception)
        {
            // Any exception means we can't connect
            return false;
        }
    }

    private bool CanLoginWithAnyInstalledKeyImpl()
    {
        using var process = new System.Diagnostics.Process();
        process.StartInfo.FileName = "ssh";
        process.StartInfo.Arguments = $"-p {port} -o ConnectTimeout=3 -o BatchMode=yes {username}@{host} whoami";
        process.StartInfo.UseShellExecute = false;
        process.StartInfo.RedirectStandardOutput = true;
        process.StartInfo.RedirectStandardError = true;
        process.StartInfo.CreateNoWindow = true;

        process.Start();
            
        // Wait up to 5 seconds for the process to complete
        bool finished = process.WaitForExit(5000);
            
        if (!finished)
        {
            // Process timed out, kill it
            try
            {
                process.Kill();
            }
            catch
            {
                // Ignore errors when killing the process
            }

            return false;
        }

        // Return true if exit code is 0 (success)
        return process.ExitCode == 0;
    }
}