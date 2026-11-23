using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Text;
using System.Windows.Forms;

[assembly: AssemblyTitle("WinUtil Türkçe")]
[assembly: AssemblyDescription("Windows Optimizasyon ve Uygulama Kurulum Aracı (ChrisTitusTech esinlenmesi)")]
[assembly: AssemblyCompany("Erol Dizdar")]
[assembly: AssemblyProduct("WinUtil Türkçe")]

namespace WinUtilTR
{
    internal static class Program
    {
        private const string ResourceName = "winutil.ps1.gz";

        [STAThread]
        private static int Main(string[] args)
        {
            string tempScriptPath = null;
            try
            {
                bool showConsole = false;
                var forwardedArgs = new List<string>();

                foreach (string arg in args)
                {
                    if (string.Equals(arg, "-Console", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(arg, "--console", StringComparison.OrdinalIgnoreCase))
                    {
                        showConsole = true;
                        continue;
                    }

                    if (string.Equals(arg, "-Preset", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(arg, "-Config", StringComparison.OrdinalIgnoreCase))
                    {
                        showConsole = true;
                    }

                    forwardedArgs.Add(arg);
                }

                tempScriptPath = ExtractEmbeddedScript();

                string powershellExe = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.System),
                    @"WindowsPowerShell\v1.0\powershell.exe"
                );
                if (!File.Exists(powershellExe))
                {
                    powershellExe = "powershell.exe";
                }

                var argBuilder = new StringBuilder();
                argBuilder.Append("-NoProfile -ExecutionPolicy Bypass -File ");
                argBuilder.Append(QuoteArgument(tempScriptPath));

                foreach (string a in forwardedArgs)
                {
                    argBuilder.Append(' ');
                    argBuilder.Append(QuoteArgument(a));
                }

                var psi = new ProcessStartInfo
                {
                    FileName = powershellExe,
                    Arguments = argBuilder.ToString(),
                    UseShellExecute = true,
                    WindowStyle = showConsole ? ProcessWindowStyle.Normal : ProcessWindowStyle.Hidden,
                    WorkingDirectory = Environment.CurrentDirectory
                };

                using (Process proc = Process.Start(psi))
                {
                    if (proc == null)
                    {
                        MessageBox.Show(
                            "PowerShell başlatılamadı.",
                            "WinUtil Türkçe",
                            MessageBoxButtons.OK,
                            MessageBoxIcon.Error
                        );
                        return 1;
                    }

                    proc.WaitForExit();
                    return proc.ExitCode;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    "WinUtil Türkçe başlatılırken bir hata oluştu:\n\n" + ex.Message,
                    "WinUtil Türkçe - Hata",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error
                );
                return 1;
            }
            finally
            {
                if (!string.IsNullOrEmpty(tempScriptPath))
                {
                    try
                    {
                        if (File.Exists(tempScriptPath))
                        {
                            File.Delete(tempScriptPath);
                        }
                    }
                    catch
                    {
                        // WinUtil's Remove-WinUtilTempScript also cleans winutil-*.ps1 in %TEMP%
                    }
                }
            }
        }

        private static string ExtractEmbeddedScript()
        {
            Assembly asm = Assembly.GetExecutingAssembly();
            using (Stream resourceStream = asm.GetManifestResourceStream(ResourceName))
            {
                if (resourceStream == null)
                {
                    throw new InvalidOperationException("Gömülü WinUtil betiği (" + ResourceName + ") bulunamadı.");
                }

                string tempFile = Path.Combine(
                    Path.GetTempPath(),
                    "winutil-" + Guid.NewGuid().ToString("N") + ".ps1"
                );

                using (var gzip = new GZipStream(resourceStream, CompressionMode.Decompress))
                using (var output = new FileStream(tempFile, FileMode.Create, FileAccess.Write, FileShare.None))
                {
                    // Prepend UTF-8 BOM so Windows PowerShell 5.1 reads Turkish characters accurately with -File
                    byte[] utf8Bom = new byte[] { 0xEF, 0xBB, 0xBF };
                    output.Write(utf8Bom, 0, utf8Bom.Length);
                    gzip.CopyTo(output);
                }

                return tempFile;
            }
        }

        private static string QuoteArgument(string arg)
        {
            if (string.IsNullOrEmpty(arg))
            {
                return "\"\"";
            }

            bool needsQuotes = false;
            for (int i = 0; i < arg.Length; i++)
            {
                if (char.IsWhiteSpace(arg[i]) || arg[i] == '"')
                {
                    needsQuotes = true;
                    break;
                }
            }

            if (!needsQuotes)
            {
                return arg;
            }

            var sb = new StringBuilder();
            sb.Append('"');
            int backslashes = 0;
            foreach (char c in arg)
            {
                if (c == '\\')
                {
                    backslashes++;
                }
                else if (c == '"')
                {
                    sb.Append('\\', backslashes * 2 + 1);
                    sb.Append('"');
                    backslashes = 0;
                }
                else
                {
                    if (backslashes > 0)
                    {
                        sb.Append('\\', backslashes);
                        backslashes = 0;
                    }
                    sb.Append(c);
                }
            }
            if (backslashes > 0)
            {
                sb.Append('\\', backslashes * 2);
            }
            sb.Append('"');
            return sb.ToString();
        }
    }
}
