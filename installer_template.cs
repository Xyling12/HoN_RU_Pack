using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Threading;
using System.Windows.Forms;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new InstallerForm());
    }
}

internal class InstallerForm : Form
{
    private RadioButton rbAuto, rbManual;
    private TextBox txtPath;
    private CheckBox cbDns;
    private Button btnBrowse, btnInstall;
    private RichTextBox rtbLog;
    private ProgressBar progress;
    private Label lblTitle, lblVersion;
    private int exitCode = 0;

    public InstallerForm()
    {
        Text = "HoN RU Pack Installer";
        Size = new Size(620, 520);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        BackColor = Color.FromArgb(26, 26, 46);
        ForeColor = Color.FromArgb(220, 220, 220);
        Font = new Font("Segoe UI", 9f);

        lblTitle = new Label { Text = "HoN RU Pack Installer", Font = new Font("Segoe UI", 16f, FontStyle.Bold), ForeColor = Color.FromArgb(200, 166, 74), AutoSize = true, Location = new Point(20, 15) };
        lblVersion = new Label { Text = "v__VERSION__", Font = new Font("Segoe UI", 10f), ForeColor = Color.FromArgb(150, 150, 170), AutoSize = true, Location = new Point(20, 48) };

        var pnl = new Panel { BackColor = Color.FromArgb(22, 33, 62), Location = new Point(15, 75), Size = new Size(574, 95), Padding = new Padding(10) };
        rbAuto = new RadioButton { Text = "Автоопределение папки игры (рекомендуется)", Checked = true, ForeColor = Color.FromArgb(220, 220, 220), AutoSize = true, Location = new Point(12, 10) };
        rbManual = new RadioButton { Text = "Указать папку вручную:", ForeColor = Color.FromArgb(220, 220, 220), AutoSize = true, Location = new Point(12, 36) };
        txtPath = new TextBox { Location = new Point(12, 62), Size = new Size(460, 23), Enabled = false, BackColor = Color.FromArgb(40, 40, 60), ForeColor = Color.White };
        btnBrowse = new Button { Text = "...", Location = new Point(478, 61), Size = new Size(40, 25), Enabled = false, FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(60, 60, 80), ForeColor = Color.White };
        pnl.Controls.AddRange(new Control[] { rbAuto, rbManual, txtPath, btnBrowse });

        bool dnsVisible = __DNS_VISIBLE__;
        if (dnsVisible)
        {
            cbDns = new CheckBox { Text = "\u26a1 Установить обход блокировки Zapret (рекомендуется для РФ)", Checked = true, ForeColor = Color.FromArgb(255, 200, 100), Font = new Font("Segoe UI", 9f, FontStyle.Bold), AutoSize = true, Location = new Point(15, 178) };
        }

        int logTop = dnsVisible ? 206 : 180;
        int logHeight = dnsVisible ? 206 : 230;
        rtbLog = new RichTextBox { Location = new Point(15, logTop), Size = new Size(574, logHeight), ReadOnly = true, BackColor = Color.FromArgb(15, 15, 30), ForeColor = Color.FromArgb(180, 255, 180), Font = new Font("Consolas", 9f), BorderStyle = BorderStyle.None };
        progress = new ProgressBar { Location = new Point(15, 420), Size = new Size(574, 22), Style = ProgressBarStyle.Marquee, MarqueeAnimationSpeed = 30, Visible = false };
        btnInstall = new Button { Text = "Установить", Location = new Point(15, 450), Size = new Size(574, 38), FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(200, 166, 74), ForeColor = Color.FromArgb(26, 26, 46), Font = new Font("Segoe UI", 11f, FontStyle.Bold) };

        Controls.AddRange(new Control[] { lblTitle, lblVersion, pnl, rtbLog, progress, btnInstall });
        if (dnsVisible) Controls.Add(cbDns);

        rbManual.CheckedChanged += (s, e) => { txtPath.Enabled = rbManual.Checked; btnBrowse.Enabled = rbManual.Checked; };
        btnBrowse.Click += (s, e) => { using (var d = new FolderBrowserDialog()) { if (d.ShowDialog() == DialogResult.OK) txtPath.Text = d.SelectedPath; } };
        btnInstall.Click += (s, e) => DoInstall();
    }

    private void Log(string msg)
    {
        if (InvokeRequired) { Invoke(new Action<string>(Log), msg); return; }
        rtbLog.AppendText(msg + "\n");
        rtbLog.ScrollToCaret();
    }

    private void DoInstall()
    {
        btnInstall.Enabled = false;
        btnInstall.Text = "Установка...";
        progress.Visible = true;
        rtbLog.Clear();

        string manualPath = rbManual.Checked ? txtPath.Text.Trim() : "";
        bool setupDns = cbDns != null && cbDns.Checked;
        var worker = new Thread(() => RunInstallThread(manualPath, setupDns));
        worker.IsBackground = true;
        worker.Start();
    }

    private void RunInstallThread(string manualPath, bool setupDns)
    {
        string tempRoot = Path.Combine(Path.GetTempPath(), "HoN_RU_Pack_Install_" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(tempRoot);
            ExtractPayload(tempRoot);
            Log("Payload extracted. Starting install...");

            string script = Path.Combine(tempRoot, "install_hon_ru_pack.ps1");
            if (!File.Exists(script)) { Log("ERROR: install script not found!"); return; }

            string args = "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\" -SourceRoot \"" + tempRoot + "\"";
            if (!string.IsNullOrWhiteSpace(manualPath)) args += " -InstallRoot \"" + manualPath + "\"";
            if (setupDns) args += " -SetupBypass";

            var psi = new ProcessStartInfo { FileName = "powershell.exe", Arguments = args, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true, CreateNoWindow = true };
            var proc = Process.Start(psi);
            proc.OutputDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) Log(e.Data); };
            proc.ErrorDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) Log("[ERR] " + e.Data); };
            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();
            proc.WaitForExit();
            exitCode = proc.ExitCode;

            Invoke(new Action(() => {
                progress.Visible = false;
                btnInstall.Enabled = true;
                if (exitCode == 0) { btnInstall.Text = "Готово \u2713"; btnInstall.BackColor = Color.FromArgb(80, 180, 80); Log("\nInstallation completed successfully!"); btnInstall.Click += (s2, e2) => Close(); }
                else { btnInstall.Text = "Ошибка \u2717"; btnInstall.BackColor = Color.FromArgb(180, 60, 60); Log("\nInstallation failed (exit code " + exitCode + ")"); btnInstall.Click += (s2, e2) => Close(); }
            }));
        }
        catch (Exception ex) { Log("ERROR: " + ex.Message); Invoke(new Action(() => { progress.Visible = false; btnInstall.Text = "Ошибка"; btnInstall.BackColor = Color.FromArgb(180, 60, 60); })); }
        finally { try { if (Directory.Exists(tempRoot)) Directory.Delete(tempRoot, true); } catch { } }
    }

    private static void ExtractPayload(string tempRoot)
    {
__PAYLOAD__
        byte[] zipBytes = Convert.FromBase64String(payloadBase64);
        string zipPath = Path.Combine(tempRoot, "payload.zip");
        File.WriteAllBytes(zipPath, zipBytes);
        ZipFile.ExtractToDirectory(zipPath, tempRoot);
    }
}
