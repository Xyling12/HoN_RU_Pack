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

[assembly: AssemblyTitle("HoN RU Pack Uninstaller")]
[assembly: AssemblyDescription("Uninstaller for HoN RU Pack — Russian localization for Heroes of Newerth")]
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
        Application.Run(new UninstallerForm());
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

internal class UninstallerForm : Form
{
    [DllImport("user32.dll")]
    private static extern bool ReleaseCapture();
    [DllImport("user32.dll")]
    private static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);

    private CheckBox cbRuPack, cbBypass;
    private FlatButton btnUninstall;
    private Button btnClose, btnMin;
    private RichTextBox rtbLog;
    private Panel pnlHeader, pnlOptions;
    private Label lblTitle, lblVersion, lblChoose;
    private int exitCode = 0;

    private static readonly Color BG_DARK = Color.FromArgb(12, 12, 24);
    private static readonly Color BG_CARD = Color.FromArgb(20, 22, 40);
    private static readonly Color BG_HEADER = Color.FromArgb(16, 17, 32);
    private static readonly Color ACCENT = Color.FromArgb(200, 60, 60);
    private static readonly Color ACCENT_HOVER = Color.FromArgb(220, 75, 75);
    private static readonly Color ACCENT_PRESS = Color.FromArgb(170, 45, 45);
    private static readonly Color TEXT_PRIMARY = Color.FromArgb(230, 230, 240);
    private static readonly Color TEXT_SECONDARY = Color.FromArgb(140, 140, 170);

    public UninstallerForm()
    {
        Text = "Удаление HoN RU Pack";
        Size = new Size(640, 500);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.None;
        BackColor = BG_DARK;
        ForeColor = TEXT_PRIMARY;
        DoubleBuffered = true;

        // Custom title bar
        pnlHeader = new Panel { Dock = DockStyle.Top, Height = 52, BackColor = BG_HEADER };
        pnlHeader.MouseDown += (s, e) => { ReleaseCapture(); SendMessage(Handle, 0xA1, 0x2, 0); };

        lblTitle = new Label { Text = "\u274c  \u0423\u0434\u0430\u043b\u0435\u043d\u0438\u0435 HoN RU Pack", Font = new Font("Segoe UI", 13f, FontStyle.Bold), ForeColor = ACCENT, AutoSize = true, Location = new Point(18, 14), BackColor = Color.Transparent };
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

        // Version
        lblVersion = new Label { Text = "v__VERSION__", Font = new Font("Segoe UI", 9f), ForeColor = TEXT_SECONDARY, AutoSize = true, Location = new Point(20, 62) };

        // Choose label
        lblChoose = new Label { Text = "\u0412\u044b\u0431\u0435\u0440\u0438\u0442\u0435, \u0447\u0442\u043e \u0443\u0434\u0430\u043b\u0438\u0442\u044c:", Font = new Font("Segoe UI", 10f, FontStyle.Bold), ForeColor = Color.FromArgb(255, 200, 100), AutoSize = true, Location = new Point(20, 88) };

        // Options panel
        pnlOptions = new Panel { BackColor = BG_CARD, Location = new Point(18, 116), Size = new Size(604, 100) };
        pnlOptions.Paint += (s, e) => {
            using (var pen = new Pen(Color.FromArgb(40, 44, 70))) { e.Graphics.DrawRectangle(pen, 0, 0, pnlOptions.Width - 1, pnlOptions.Height - 1); }
        };

        cbRuPack = new CheckBox
        {
            Text = "\u25cf  \u0420\u0443\u0441\u0438\u0444\u0438\u043a\u0430\u0446\u0438\u044f HoN RU Pack",
            Checked = true,
            ForeColor = TEXT_PRIMARY,
            Font = new Font("Segoe UI", 10f),
            AutoSize = true,
            Location = new Point(15, 18)
        };

        cbBypass = new CheckBox
        {
            Text = "\u26a1 \u041e\u0431\u0445\u043e\u0434 \u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u043a\u0438 (AmneziaWG)",
            Checked = true,
            ForeColor = TEXT_PRIMARY,
            Font = new Font("Segoe UI", 10f),
            AutoSize = true,
            Location = new Point(15, 56)
        };

        pnlOptions.Controls.AddRange(new Control[] { cbRuPack, cbBypass });

        // Log
        rtbLog = new RichTextBox { Location = new Point(18, 228), Size = new Size(604, 170), ReadOnly = true, BackColor = Color.FromArgb(8, 8, 18), ForeColor = Color.FromArgb(130, 220, 130), Font = new Font("Cascadia Mono,Consolas", 9f), BorderStyle = BorderStyle.None };

        // Button
        btnUninstall = new FlatButton { Text = "\u274c  \u0423\u0434\u0430\u043b\u0438\u0442\u044c", Location = new Point(18, 500 - 58), Size = new Size(604, 44), Font = new Font("Segoe UI", 12f, FontStyle.Bold) };
        btnUninstall.NormalColor = ACCENT;
        btnUninstall.HoverColor = ACCENT_HOVER;
        btnUninstall.PressColor = ACCENT_PRESS;
        btnUninstall.ForeColor = Color.White;

        Controls.AddRange(new Control[] { pnlHeader, lblVersion, lblChoose, pnlOptions, rtbLog, btnUninstall });

        cbRuPack.CheckedChanged += (s, e) => UpdateButton();
        cbBypass.CheckedChanged += (s, e) => UpdateButton();
        btnUninstall.Click += (s, e) => DoUninstall();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        using (var pen = new Pen(Color.FromArgb(50, 54, 80))) { e.Graphics.DrawRectangle(pen, 0, 0, Width - 1, Height - 1); }
    }

    private void UpdateButton()
    {
        btnUninstall.Enabled = cbRuPack.Checked || cbBypass.Checked;
    }

    private void Log(string msg)
    {
        if (InvokeRequired) { Invoke(new Action<string>(Log), msg); return; }
        rtbLog.AppendText(msg + "\n");
        rtbLog.ScrollToCaret();
    }

    private void DoUninstall()
    {
        if (!cbRuPack.Checked && !cbBypass.Checked) return;

        string what = "";
        if (cbRuPack.Checked && cbBypass.Checked) what = "\u0420\u0443\u0441\u0438\u0444\u0438\u043a\u0430\u0446\u0438\u044e \u0438 \u043e\u0431\u0445\u043e\u0434 \u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u043a\u0438";
        else if (cbRuPack.Checked) what = "\u0420\u0443\u0441\u0438\u0444\u0438\u043a\u0430\u0446\u0438\u044e HoN RU Pack";
        else what = "\u041e\u0431\u0445\u043e\u0434 \u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u043a\u0438 (AmneziaWG)";

        var result = MessageBox.Show(
            "\u0423\u0434\u0430\u043b\u0438\u0442\u044c: " + what + "?\n\n\u041f\u043e\u0441\u043b\u0435 \u0443\u0434\u0430\u043b\u0435\u043d\u0438\u044f \u043e\u0442\u043c\u0435\u043d\u0438\u0442\u044c \u044d\u0442\u043e \u0434\u0435\u0439\u0441\u0442\u0432\u0438\u0435 \u0431\u0443\u0434\u0435\u0442 \u043d\u0435\u043b\u044c\u0437\u044f.",
            "\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0435\u043d\u0438\u0435",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );
        if (result != DialogResult.Yes) return;

        btnUninstall.Enabled = false;
        btnUninstall.Text = "\u0423\u0434\u0430\u043b\u0435\u043d\u0438\u0435...";
        cbRuPack.Enabled = false;
        cbBypass.Enabled = false;
        rtbLog.Clear();

        bool removeRu = cbRuPack.Checked;
        bool removeBypass = cbBypass.Checked;
        var worker = new Thread(() => RunUninstallThread(removeRu, removeBypass));
        worker.IsBackground = true;
        worker.Start();
    }

    private void RunUninstallThread(bool removeRu, bool removeBypass)
    {
        string tempRoot = Path.Combine(Path.GetTempPath(), "HoN_RU_Pack_Uninstall_" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(tempRoot);
            ExtractPayload(tempRoot);
            Log("Пакет распакован.");

            if (removeBypass)
            {
                string bypassScript = Path.Combine(tempRoot, "remove_amneziawg.ps1");
                if (File.Exists(bypassScript))
                {
                    Log("\n--- Удаляю AmneziaWG ---");
                    RunPS(bypassScript, "");
                }
                else { Log("[Bypass] remove_amneziawg.ps1 не найден, пропускаю."); }
            }

            if (removeRu)
            {
                string uninstScript = Path.Combine(tempRoot, "uninstall_hon_ru_pack.ps1");
                if (File.Exists(uninstScript))
                {
                    Log("\n--- Удаляю HoN RU Pack ---");
                    string args = removeBypass ? "" : " -KeepFiles";
                    RunPS(uninstScript, args);
                }
                else { Log("Ошибка: сценарий удаления не найден."); exitCode = 1; }
            }

            Invoke(new Action(() => {
                btnUninstall.Enabled = true;
                if (exitCode == 0)
                {
                    btnUninstall.Text = "\u0423\u0434\u0430\u043b\u0435\u043d\u043e \u2713";
                    btnUninstall.NormalColor = Color.FromArgb(40, 160, 80);
                    btnUninstall.HoverColor = Color.FromArgb(50, 180, 90);
                    btnUninstall.PressColor = Color.FromArgb(35, 140, 70);
                    Log("\n\u0413\u043e\u0442\u043e\u0432\u043e!");
                    btnUninstall.Click += (s2, e2) => Close();
                }
                else
                {
                    btnUninstall.Text = "\u041e\u0448\u0438\u0431\u043a\u0430 \u2717";
                    btnUninstall.NormalColor = Color.FromArgb(180, 50, 50);
                    Log("\n\u041e\u0448\u0438\u0431\u043a\u0430 (код \u0432\u044b\u0445\u043e\u0434\u0430 " + exitCode + ")");
                    btnUninstall.Click += (s2, e2) => Close();
                }
            }));
        }
        catch (Exception ex) { Log("Ошибка: " + ex.Message); Invoke(new Action(() => { btnUninstall.Text = "\u041e\u0448\u0438\u0431\u043a\u0430"; })); }
        finally { try { if (Directory.Exists(tempRoot)) Directory.Delete(tempRoot, true); } catch { } }
    }

    private void RunPS(string scriptPath, string extraArgs)
    {
        string args = "-NoProfile -EP Bypass -File \"" + scriptPath + "\"" + extraArgs;
        var psi = new ProcessStartInfo { FileName = "powershell.exe", Arguments = args, UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true, CreateNoWindow = true };
        var proc = Process.Start(psi);
        proc.OutputDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) Log(e.Data); };
        proc.ErrorDataReceived += (s, e) => { if (!string.IsNullOrEmpty(e.Data)) Log("[ERR] " + e.Data); };
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
        proc.WaitForExit();
        if (proc.ExitCode != 0) exitCode = proc.ExitCode;
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
