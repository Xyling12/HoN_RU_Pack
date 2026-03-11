param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$OutputExe = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputExe)) {
    $OutputExe = Join-Path $PackageRoot "dist\HoN_RU_Pack_Installer.exe"
}
if (-not (Test-Path $PackageRoot)) {
    throw "PackageRoot not found: $PackageRoot"
}

$requiredScripts = @(
    "install_hon_ru_pack.ps1",
    "hon_common.ps1",
    "hon_auto_agent.ps1",
    "set_login_banner.ps1",
    "hon_paths_override.example.ps1",
    "version.txt",
    "README.txt",
    "README_ONE_CLICK_INSTALL.txt"
)
$requiredBundle = @(
    "entities_en.str",
    "interface_en.str",
    "client_messages_en.str",
    "game_messages_en.str",
    "bot_messages_en.str"
)

$distRoot = Join-Path $PackageRoot "dist"
$stageRoot = Join-Path $distRoot "installer_payload_stage"
$stageBundle = Join-Path $stageRoot "bundle"
$payloadZip = Join-Path $distRoot "installer_payload.zip"
$sourceDump = Join-Path $distRoot "installer_program.cs"

if (Test-Path $stageRoot) { Remove-Item -Path $stageRoot -Recurse -Force }
if (Test-Path $payloadZip) { Remove-Item -Path $payloadZip -Force }
New-Item -ItemType Directory -Path $stageBundle -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path -Parent $OutputExe) -Force | Out-Null

foreach ($name in $requiredScripts) {
    $src = Join-Path $PackageRoot $name
    if (-not (Test-Path $src)) { throw "Missing required file: $src" }
    Copy-Item -Path $src -Destination (Join-Path $stageRoot $name) -Force
}
foreach ($name in $requiredBundle) {
    $src = Join-Path (Join-Path $PackageRoot "bundle") $name
    if (-not (Test-Path $src)) { throw "Missing required bundle file: $src" }
    Copy-Item -Path $src -Destination (Join-Path $stageBundle $name) -Force
}

Compress-Archive -Path (Join-Path $stageRoot "*") -DestinationPath $payloadZip -Force
$payloadBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($payloadZip))

$chunks = New-Object System.Collections.Generic.List[string]
$chunkSize = 24000
for ($offset = 0; $offset -lt $payloadBase64.Length; $offset += $chunkSize) {
    $len = [Math]::Min($chunkSize, $payloadBase64.Length - $offset)
    $chunks.Add($payloadBase64.Substring($offset, $len))
}

$payloadBuilder = New-Object System.Text.StringBuilder
[void]$payloadBuilder.AppendLine("string payloadBase64 =")
for ($i = 0; $i -lt $chunks.Count; $i++) {
    $suffix = if ($i -eq $chunks.Count - 1) { ";" } else { " +" }
    [void]$payloadBuilder.AppendLine(('    "{0}"{1}' -f $chunks[$i], $suffix))
}
$payloadCode = $payloadBuilder.ToString()

$programTemplate = @"
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;

internal static class Program
{
    private static int Main()
    {
        Console.Title = "HoN RU Pack Installer";
        string tempRoot = Path.Combine(Path.GetTempPath(), "HoN_RU_Pack_Install_" + Guid.NewGuid().ToString("N"));

        try
        {
            Directory.CreateDirectory(tempRoot);
            ExtractPayload(tempRoot);

            Console.WriteLine("HoN RU Pack Installer");
            Console.WriteLine("---------------------");
            Console.WriteLine("1) Auto detect game folder (recommended)");
            Console.WriteLine("2) Enter game folder manually");
            Console.WriteLine();
            Console.Write("Select mode [1/2]: ");
            string mode = (Console.ReadLine() ?? "").Trim();

            string installRoot = "";
            if (mode == "2")
            {
                Console.Write("Enter full game folder path (where resources0.jz is): ");
                installRoot = (Console.ReadLine() ?? "").Trim();
            }

            int code = RunInstall(tempRoot, installRoot);
            Console.WriteLine();
            if (code == 0)
            {
                Console.WriteLine("Installation completed.");
            }
            else
            {
                Console.WriteLine("Installation failed with exit code: " + code);
            }

            WaitForClose();
            return code;
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERROR: " + ex.Message);
            WaitForClose();
            return 1;
        }
        finally
        {
            TryDelete(tempRoot);
        }
    }

    private static void ExtractPayload(string tempRoot)
    {
__PAYLOAD__
        byte[] zipBytes = Convert.FromBase64String(payloadBase64);
        string zipPath = Path.Combine(tempRoot, "payload.zip");
        File.WriteAllBytes(zipPath, zipBytes);
        ZipFile.ExtractToDirectory(zipPath, tempRoot);
    }

    private static int RunInstall(string sourceRoot, string installRoot)
    {
        string script = Path.Combine(sourceRoot, "install_hon_ru_pack.ps1");
        if (!File.Exists(script))
        {
            throw new FileNotFoundException("install_hon_ru_pack.ps1 not found.", script);
        }

        string args = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\" -SourceRoot \"" + sourceRoot + "\"";
        if (!string.IsNullOrWhiteSpace(installRoot))
        {
            args += " -InstallRoot \"" + installRoot + "\"";
        }

        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = "powershell.exe";
        psi.Arguments = args;
        psi.UseShellExecute = false;
        psi.RedirectStandardOutput = true;
        psi.RedirectStandardError = true;
        psi.CreateNoWindow = false;

        Process proc = Process.Start(psi);
        if (proc == null)
        {
            throw new InvalidOperationException("Failed to start powershell installer process.");
        }

        proc.OutputDataReceived += delegate (object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data)) Console.WriteLine(e.Data);
        };
        proc.ErrorDataReceived += delegate (object sender, DataReceivedEventArgs e)
        {
            if (!string.IsNullOrEmpty(e.Data)) Console.WriteLine(e.Data);
        };

        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
        proc.WaitForExit();
        return proc.ExitCode;
    }

    private static void TryDelete(string path)
    {
        try
        {
            if (Directory.Exists(path))
            {
                Directory.Delete(path, true);
            }
        }
        catch
        {
            // ignore cleanup errors
        }
    }

    private static void WaitForClose()
    {
        Console.WriteLine("Press Enter to close...");
        try
        {
            Console.ReadLine();
        }
        catch
        {
            // ignore close wait errors in redirected sessions
        }
    }
}
"@

$programCode = $programTemplate.Replace("__PAYLOAD__", $payloadCode)
Set-Content -Path $sourceDump -Value $programCode -Encoding UTF8

if (Test-Path $OutputExe) { Remove-Item -Path $OutputExe -Force }

Add-Type `
    -TypeDefinition $programCode `
    -Language CSharp `
    -OutputAssembly $OutputExe `
    -OutputType ConsoleApplication `
    -ReferencedAssemblies @("System.IO.Compression.dll", "System.IO.Compression.FileSystem.dll")

Write-Host "Installer built: $OutputExe"
Write-Host "Payload zip: $payloadZip"
Write-Host "Source dump: $sourceDump"
