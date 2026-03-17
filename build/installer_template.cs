using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("HoN RU Pack Installer")]
[assembly: AssemblyDescription("Russian language pack installer for Heroes of Newerth")]
[assembly: AssemblyCompany("HoN RU Community")]
[assembly: AssemblyProduct("HoN RU Pack")]
[assembly: AssemblyVersion("__VERSION_FULL__")]
[assembly: AssemblyFileVersion("__VERSION_FULL__")]

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

internal class FlatButton : Button
{
    private Color hoverColor;
    private Color normalColor;
    private Color pressColor;
    private bool hovering = false;
    private bool pressing = false;

    public FlatButton()
    {
        SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer, true);
        FlatStyle = FlatStyle.Flat;
        FlatAppearance.BorderSize = 0;
        Cursor = Cursors.Hand;
    }

    public Color HoverColor { get { return hoverColor; } set { hoverColor = value; } }
    public Color NormalColor { get { return normalColor; } set { normalColor = value; BackColor = value; } }
    public Color PressColor { get { return pressColor; } set { pressColor = value; } }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        var rect = new Rectangle(0, 0, Width - 1, Height - 1);
        Color fill = pressing ? pressColor : (hovering ? hoverColor : normalColor);
        using (var path = RoundRect(rect, 8))
        using (var brush = new SolidBrush(fill))
        {
            g.FillPath(brush, path);
        }
        TextRenderer.DrawText(g, Text, Font, ClientRectangle, ForeColor, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
    }

    protected override void OnMouseEnter(EventArgs e) { hovering = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { hovering = false; pressing = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnMouseDown(MouseEventArgs e) { pressing = true; Invalidate(); base.OnMouseDown(e); }
    protected override void OnMouseUp(MouseEventArgs e) { pressing = false; Invalidate(); base.OnMouseUp(e); }

    private static GraphicsPath RoundRect(Rectangle r, int radius)
    {
        var path = new GraphicsPath();
        int d = radius * 2;
        path.AddArc(r.X, r.Y, d, d, 180, 90);
        path.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        path.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        path.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}

internal class InstallerForm : Form
{
    [DllImport("user32.dll")]
    private static extern bool ReleaseCapture();
    [DllImport("user32.dll")]
    private static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);

    private RadioButton rbAuto, rbManual;
    private TextBox txtPath;
    private CheckBox cbHon, cbYoutube, cbDiscord, cbTelegram, cbOpenAI;
    private FlatButton btnBrowse, btnInstall;
    private Button btnClose, btnMin;
    private RichTextBox rtbLog;
    private Panel pnlHeader, pnlOptions;
    private Label lblTitle, lblVersion, lblSubtitle;
    private int exitCode = 0;

    private static readonly Color BG_DARK = Color.FromArgb(12, 12, 24);
    private static readonly Color BG_CARD = Color.FromArgb(20, 22, 40);
    private static readonly Color BG_HEADER = Color.FromArgb(16, 17, 32);
    private static readonly Color ACCENT = Color.FromArgb(200, 166, 74);
    private static readonly Color ACCENT_HOVER = Color.FromArgb(220, 186, 94);
    private static readonly Color ACCENT_PRESS = Color.FromArgb(170, 140, 60);
    private static readonly Color TEXT_PRIMARY = Color.FromArgb(230, 230, 240);
    private static readonly Color TEXT_SECONDARY = Color.FromArgb(140, 140, 170);
    private static readonly Color TEXT_ON_ACCENT = Color.FromArgb(12, 12, 24);

    public InstallerForm()
    {
        Text = "HoN RU Pack Installer";
        Size = new Size(640, 610);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.None;
        BackColor = BG_DARK;
        ForeColor = TEXT_PRIMARY;
        DoubleBuffered = true;

        // Custom title bar
        pnlHeader = new Panel { Dock = DockStyle.Top, Height = 52, BackColor = BG_HEADER };
        pnlHeader.MouseDown += (s, e) => { ReleaseCapture(); SendMessage(Handle, 0xA1, 0x2, 0); };

        lblTitle = new Label { Text = "[RU]  HoN RU Pack", Font = new Font("Segoe UI", 13f, FontStyle.Bold), ForeColor = ACCENT, AutoSize = true, Location = new Point(18, 14), BackColor = Color.Transparent };
        lblTitle.MouseDown += (s, e) => { ReleaseCapture(); SendMessage(Handle, 0xA1, 0x2, 0); };

        btnClose = new Button { Text = "\u2715", Size = new Size(46, 52), Location = new Point(594, 0), FlatStyle = FlatStyle.Flat, BackColor = Color.Transparent, ForeColor = TEXT_SECONDARY, Font = new Font("Segoe UI", 11f), Cursor = Cursors.Hand };
        btnClose.FlatAppearance.BorderSize = 0;
        btnClose.FlatAppearance.MouseOverBackColor = Color.FromArgb(180, 40, 40);
        btnClose.Click += (s, e) => Close();

        btnMin = new Button { Text = "\u2013", Size = new Size(46, 52), Location = new Point(548, 0), FlatStyle = FlatStyle.Flat, BackColor = Color.Transparent, ForeColor = TEXT_SECONDARY, Font = new Font("Segoe UI", 11f), Cursor = Cursors.Hand };
        btnMin.FlatAppearance.BorderSize = 0;
        btnMin.FlatAppearance.MouseOverBackColor = Color.FromArgb(40, 42, 60);
        btnMin.Click += (s, e) => WindowState = FormWindowState.Minimized;

        pnlHeader.Controls.AddRange(new Control[] { lblTitle, btnClose, btnMin });

        // Version + subtitle
        lblVersion = new Label { Text = "v__VERSION__", Font = new Font("Segoe UI", 9f), ForeColor = TEXT_SECONDARY, AutoSize = true, Location = new Point(20, 62) };
        lblSubtitle = new Label { Text = "\u0420\u0443\u0441\u0441\u043a\u0438\u0439 \u044f\u0437\u044b\u043a\u043e\u0432\u043e\u0439 \u043f\u0430\u043a\u0435\u0442 \u0434\u043b\u044f Heroes of Newerth", Font = new Font("Segoe UI", 9.5f), ForeColor = TEXT_SECONDARY, AutoSize = true, Location = new Point(20, 82) };

        // Options panel
        pnlOptions = new Panel { BackColor = BG_CARD, Location = new Point(18, 112), Size = new Size(604, 100) };
        pnlOptions.Paint += (s, e) => {
            using (var pen = new Pen(Color.FromArgb(40, 44, 70))) { e.Graphics.DrawRectangle(pen, 0, 0, pnlOptions.Width - 1, pnlOptions.Height - 1); }
        };

        rbAuto = new RadioButton { Text = "\u25c9  \u0410\u0432\u0442\u043e\u043e\u043f\u0440\u0435\u0434\u0435\u043b\u0435\u043d\u0438\u0435 \u043f\u0430\u043f\u043a\u0438 \u0438\u0433\u0440\u044b (\u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f)", Checked = true, ForeColor = TEXT_PRIMARY, Font = new Font("Segoe UI", 9.5f), AutoSize = true, Location = new Point(15, 14) };
        rbManual = new RadioButton { Text = "\u25cb  \u0423\u043a\u0430\u0437\u0430\u0442\u044c \u043f\u0430\u043f\u043a\u0443 \u0432\u0440\u0443\u0447\u043d\u0443\u044e:", ForeColor = TEXT_PRIMARY, Font = new Font("Segoe UI", 9.5f), AutoSize = true, Location = new Point(15, 40) };
        txtPath = new TextBox { Location = new Point(15, 68), Size = new Size(490, 24), Enabled = false, BackColor = Color.FromArgb(30, 32, 52), ForeColor = TEXT_PRIMARY, BorderStyle = BorderStyle.FixedSingle, Font = new Font("Segoe UI", 9f) };
        btnBrowse = new FlatButton { Text = "...", Location = new Point(512, 66), Size = new Size(76, 28), Enabled = false, Font = new Font("Segoe UI", 9f, FontStyle.Bold) };
        btnBrowse.NormalColor = Color.FromArgb(40, 44, 70);
        btnBrowse.HoverColor = Color.FromArgb(55, 60, 90);
        btnBrowse.PressColor = Color.FromArgb(35, 38, 60);
        btnBrowse.ForeColor = TEXT_PRIMARY;
        pnlOptions.Controls.AddRange(new Control[] { rbAuto, rbManual, txtPath, btnBrowse });

        // Bypass checkboxes (per-service routing)
        bool dnsVisible = __DNS_VISIBLE__;
        int logTop = 225;
        if (dnsVisible)
        {
            cbHon = new CheckBox
            {
                Text = "\u26a1 \u041e\u0431\u0445\u043e\u0434 \u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u043a\u0438 HoN (\u0440\u0435\u043a\u043e\u043c\u0435\u043d\u0434\u0443\u0435\u0442\u0441\u044f \u0434\u043b\u044f \u0420\u0424)",
                Checked = true,
                ForeColor = Color.FromArgb(255, 200, 100),
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                AutoSize = true,
                Location = new Point(20, 220)
            };
            cbYoutube = new CheckBox
            {
                Text = "\ud83d\udcfa YouTube \u0447\u0435\u0440\u0435\u0437 \u043e\u0431\u0445\u043e\u0434",
                Checked = false,
                ForeColor = Color.FromArgb(200, 200, 220),
                Font = new Font("Segoe UI", 9.5f),
                AutoSize = true,
                Location = new Point(20, 246)
            };
            cbDiscord = new CheckBox
            {
                Text = "\ud83d\udcac Discord \u0447\u0435\u0440\u0435\u0437 \u043e\u0431\u0445\u043e\u0434",
                Checked = false,
                ForeColor = Color.FromArgb(200, 200, 220),
                Font = new Font("Segoe UI", 9.5f),
                AutoSize = true,
                Location = new Point(20, 272)
            };
            cbTelegram = new CheckBox
            {
                Text = "\u2708 Telegram \u0447\u0435\u0440\u0435\u0437 \u043e\u0431\u0445\u043e\u0434",
                Checked = false,
                ForeColor = Color.FromArgb(200, 200, 220),
                Font = new Font("Segoe UI", 9.5f),
                AutoSize = true,
                Location = new Point(20, 298)
            };
            cbOpenAI = new CheckBox
            {
                Text = "\ud83e\udde0 ChatGPT/OpenAI \u0447\u0435\u0440\u0435\u0437 \u043e\u0431\u0445\u043e\u0434",
                Checked = false,
                ForeColor = Color.FromArgb(200, 200, 220),
                Font = new Font("Segoe UI", 9.5f),
                AutoSize = true,
                Location = new Point(20, 324)
            };
            logTop = 352;
        }

        // Log
        int logHeight = 610 - logTop - 90;
        rtbLog = new RichTextBox { Location = new Point(18, logTop), Size = new Size(604, logHeight), ReadOnly = true, BackColor = Color.FromArgb(8, 8, 18), ForeColor = Color.FromArgb(130, 220, 130), Font = new Font("Cascadia Mono,Consolas", 9f), BorderStyle = BorderStyle.None };

        // Install button
        btnInstall = new FlatButton { Text = "\u0423\u0441\u0442\u0430\u043d\u043e\u0432\u0438\u0442\u044c", Location = new Point(18, 610 - 58), Size = new Size(604, 44), Font = new Font("Segoe UI", 12f, FontStyle.Bold) };
        btnInstall.NormalColor = ACCENT;
        btnInstall.HoverColor = ACCENT_HOVER;
        btnInstall.PressColor = ACCENT_PRESS;
        btnInstall.ForeColor = TEXT_ON_ACCENT;

        Controls.AddRange(new Control[] { pnlHeader, lblVersion, lblSubtitle, pnlOptions, rtbLog, btnInstall });
        if (dnsVisible) { Controls.Add(cbHon); Controls.Add(cbYoutube); Controls.Add(cbDiscord); Controls.Add(cbTelegram); Controls.Add(cbOpenAI); }

        rbManual.CheckedChanged += (s, e) => { txtPath.Enabled = rbManual.Checked; btnBrowse.Enabled = rbManual.Checked; };
        btnBrowse.Click += (s, e) => { using (var d = new FolderBrowserDialog()) { if (d.ShowDialog() == DialogResult.OK) txtPath.Text = d.SelectedPath; } };
        btnInstall.Click += (s, e) => DoInstall();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        using (var pen = new Pen(Color.FromArgb(50, 54, 80))) { e.Graphics.DrawRectangle(pen, 0, 0, Width - 1, Height - 1); }
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
        btnInstall.Text = "\u0423\u0441\u0442\u0430\u043d\u043e\u0432\u043a\u0430...";
        rtbLog.Clear();

        string manualPath = rbManual.Checked ? txtPath.Text.Trim() : "";
        bool routeHon = cbHon != null && cbHon.Checked;
        bool routeYoutube = cbYoutube != null && cbYoutube.Checked;
        bool routeDiscord = cbDiscord != null && cbDiscord.Checked;
        bool routeTelegram = cbTelegram != null && cbTelegram.Checked;
        bool routeOpenai = cbOpenAI != null && cbOpenAI.Checked;
        var worker = new Thread(() => RunInstallThread(manualPath, routeHon, routeYoutube, routeDiscord, routeTelegram, routeOpenai));
        worker.IsBackground = true;
        worker.Start();
    }

    private void RunInstallThread(string manualPath, bool routeHon, bool routeYoutube, bool routeDiscord, bool routeTelegram, bool routeOpenai)
    {
        string tempRoot = Path.Combine(Path.GetTempPath(), "HoN_RU_Pack_Install_" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(tempRoot);
            ExtractPayload(tempRoot);
            Log("Payload extracted. Starting install...");

            string script = Path.Combine(tempRoot, "install_hon_ru_pack.ps1");
            if (!File.Exists(script)) { Log("ERROR: install script not found!"); return; }

            string args = "-NoProfile -EP Bypass -File \"" + script + "\" -SourceRoot \"" + tempRoot + "\"";
            if (!string.IsNullOrWhiteSpace(manualPath)) args += " -InstallRoot \"" + manualPath + "\"";
            if (routeHon || routeYoutube || routeDiscord || routeTelegram || routeOpenai) args += " -SetupBypass";
            if (routeHon) args += " -RouteHoN";
            if (routeYoutube) args += " -RouteYouTube";
            if (routeDiscord) args += " -RouteDiscord";
            if (routeTelegram) args += " -RouteTelegram";
            if (routeOpenai) args += " -RouteOpenAI";

            var psi = new ProcessStartInfo { FileName = "powershell.exe", Arguments = args, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true, CreateNoWindow = true };
            var proc = Process.Start(psi);
            proc.OutputDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) Log(e.Data); };
            proc.ErrorDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) Log("[ERR] " + e.Data); };
            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();
            proc.WaitForExit();
            exitCode = proc.ExitCode;

            Invoke(new Action(() => {
                btnInstall.Enabled = true;
                if (exitCode == 0)
                {
                    btnInstall.Text = "\u0413\u043e\u0442\u043e\u0432\u043e \u2713";
                    btnInstall.NormalColor = Color.FromArgb(40, 160, 80);
                    btnInstall.HoverColor = Color.FromArgb(50, 180, 90);
                    btnInstall.PressColor = Color.FromArgb(35, 140, 70);
                    btnInstall.ForeColor = Color.White;
                    Log("\n\u0423\u0441\u0442\u0430\u043d\u043e\u0432\u043a\u0430 \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u0430 \u0443\u0441\u043f\u0435\u0448\u043d\u043e!");
                    btnInstall.Click += (s2, e2) => Close();
                }
                else
                {
                    btnInstall.Text = "\u041e\u0448\u0438\u0431\u043a\u0430 \u2717";
                    btnInstall.NormalColor = Color.FromArgb(180, 50, 50);
                    btnInstall.HoverColor = Color.FromArgb(200, 60, 60);
                    btnInstall.PressColor = Color.FromArgb(150, 40, 40);
                    btnInstall.ForeColor = Color.White;
                    Log("\n\u041e\u0448\u0438\u0431\u043a\u0430 \u0443\u0441\u0442\u0430\u043d\u043e\u0432\u043a\u0438 (exit code " + exitCode + ")");
                    btnInstall.Click += (s2, e2) => Close();
                }
            }));
        }
        catch (Exception ex) { Log("ERROR: " + ex.Message); Invoke(new Action(() => { btnInstall.Text = "\u041e\u0448\u0438\u0431\u043a\u0430"; btnInstall.NormalColor = Color.FromArgb(180, 50, 50); })); }
        finally { try { if (Directory.Exists(tempRoot)) Directory.Delete(tempRoot, true); } catch { } }
    }

    private static void ExtractPayload(string tempRoot)
    {
        string zipPath = Path.Combine(tempRoot, "payload.zip");
        using (var rs = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
        using (var fs = File.Create(zipPath))
        {
            rs.CopyTo(fs);
        }
        ZipFile.ExtractToDirectory(zipPath, tempRoot);
    }
}
