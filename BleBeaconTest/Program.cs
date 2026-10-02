
using System;
using System.Drawing;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Storage.Streams;

internal static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new BeaconForm());
    }
}

public class BeaconForm : Form
{
    private readonly Button startButton;
    private readonly Button stopButton;
    private readonly Label statusLabel;
    private readonly Label serverLabel;

    private BluetoothLEAdvertisementPublisher? publisher;
    private readonly HttpListener commandListener = new();
    private bool closing;

    // Development token. Django must send the same token.
    private static readonly string CommandToken =
    Environment.GetEnvironmentVariable("BLE_CONTROL_TOKEN") ?? "";

    public BeaconForm()
    {
        Text = "QR Attendance - BLE Beacon";
        Size = new Size(440, 300);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;

        var titleLabel = new Label
        {
            Text = "QR Attendance BLE Beacon",
            Font = new Font("Segoe UI", 15, FontStyle.Bold),
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Location = new Point(20, 20),
            Size = new Size(380, 35)
        };

        statusLabel = new Label
        {
            Text = "BLE Status: Stopped",
            Font = new Font("Segoe UI", 10),
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Location = new Point(20, 65),
            Size = new Size(380, 25)
        };

        serverLabel = new Label
        {
            Text = "Command server: Starting...",
            Font = new Font("Segoe UI", 9),
            AutoSize = false,
            TextAlign = ContentAlignment.MiddleCenter,
            Location = new Point(20, 95),
            Size = new Size(380, 25)
        };

        startButton = new Button
        {
            Text = "Start BLE",
            Location = new Point(65, 150),
            Size = new Size(130, 42)
        };

        stopButton = new Button
        {
            Text = "Stop BLE",
            Location = new Point(225, 150),
            Size = new Size(130, 42),
            Enabled = false
        };

        startButton.Click += StartBeacon;
        stopButton.Click += StopBeacon;

        Controls.Add(titleLabel);
        Controls.Add(statusLabel);
        Controls.Add(serverLabel);
        Controls.Add(startButton);
        Controls.Add(stopButton);

        Shown += (sender, args) =>
        {
            _ = StartCommandServerAsync();
        };
    }

    // Start the local command server.
    private async Task StartCommandServerAsync()
    {
        try
        {
            commandListener.Prefixes.Add(
                "http://127.0.0.1:8765/");

            commandListener.Start();

            SetServerStatus("Command server: Ready");

            while (commandListener.IsListening)
            {
                var context =
                    await commandListener.GetContextAsync();

                _ = HandleCommandAsync(context);
            }
        }
        catch (HttpListenerException) when (closing)
        {
            // Expected when the application closes.
        }
        catch (ObjectDisposedException) when (closing)
        {
            // Expected when the application closes.
        }
        catch (Exception ex)
        {
            SetServerStatus("Command server failed");

            if (!closing && !IsDisposed)
            {
                MessageBox.Show(
                    ex.Message,
                    "Command Server Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
            }
        }
    }

    // Process commands sent by Django.
    private async Task HandleCommandAsync(
        HttpListenerContext context)
    {
        var request = context.Request;
        var response = context.Response;

        try
        {
            // Only accept POST requests.
            if (request.HttpMethod != "POST")
            {
                await SendResponseAsync(
                    response, 405, "POST required");
                return;
            }

            // Require the shared token.
            string suppliedToken =
                request.Headers["X-BLE-Token"] ?? "";

            if (!string.Equals(
                    suppliedToken,
                    CommandToken,
                    StringComparison.Ordinal))
            {
                await SendResponseAsync(
                    response, 401, "Unauthorized");
                return;
            }

            string path = request.Url?
                .AbsolutePath.TrimEnd('/')
                .ToLowerInvariant() ?? "";

            bool success = false;

            // Run BLE operations on the Windows UI thread.
            if (!closing && !IsDisposed)
            {
                Invoke(new Action(() =>
                {
                    if (path == "/start")
                    {
                        StartBeacon(null, EventArgs.Empty);
                        success = publisher != null;
                    }
                    else if (path == "/stop")
                    {
                        StopBeacon(null, EventArgs.Empty);
                        success = publisher == null;
                    }
                }));
            }

            if (path != "/start" && path != "/stop")
            {
                await SendResponseAsync(
                    response, 404, "Unknown command");
                return;
            }

            if (success)
            {
                await SendResponseAsync(
                    response, 200, "OK");
            }
            else
            {
                await SendResponseAsync(
                    response, 500,
                    "BLE operation failed");
            }
        }
        catch (Exception)
        {
            try
            {
                await SendResponseAsync(
                    response, 500, "Command failed");
            }
            catch
            {
                // The client may already have disconnected.
            }
        }
    }

    private static async Task SendResponseAsync(
        HttpListenerResponse response,
        int statusCode,
        string message)
    {
        byte[] bytes = Encoding.UTF8.GetBytes(message);

        response.StatusCode = statusCode;
        response.ContentType = "text/plain";
        response.ContentLength64 = bytes.Length;

        await response.OutputStream.WriteAsync(
            bytes, 0, bytes.Length);

        response.Close();
    }

    private void SetServerStatus(string message)
    {
        if (IsDisposed || !IsHandleCreated)
            return;

        BeginInvoke(new Action(() =>
        {
            if (!IsDisposed)
                serverLabel.Text = message;
        }));
    }

    private void StartBeacon(object? sender, EventArgs e)
    {
        if (publisher != null)
        {
            statusLabel.Text = "BLE beacon is already running";
            return;
        }

        try
        {
            var advertisement =
                new BluetoothLEAdvertisement();

            var manufacturerData =
                new BluetoothLEManufacturerData
                {
                    CompanyId = 0xFFFE
                };

            using (var writer = new DataWriter())
            {
                writer.WriteBytes(
                    new byte[]
                    {
                        0x51, 0x52, 0x41, 0x54
                    });

                manufacturerData.Data =
                    writer.DetachBuffer();
            }

            advertisement.ManufacturerData.Add(
                manufacturerData);

            publisher =
                new BluetoothLEAdvertisementPublisher(
                    advertisement);

            publisher.StatusChanged += (s, args) =>
            {
                if (IsDisposed || !IsHandleCreated)
                    return;

                BeginInvoke(new Action(() =>
                {
                    if (!IsDisposed)
                    {
                        statusLabel.Text =
                            $"BLE status: {args.Status}";
                    }
                }));
            };

            publisher.Start();

            statusLabel.Text = "Starting BLE beacon...";
            startButton.Enabled = false;
            stopButton.Enabled = true;
        }
        catch (Exception ex)
        {
            try
            {
                publisher?.Stop();
            }
            catch
            {
                // Ignore cleanup errors.
            }

            publisher = null;

            statusLabel.Text = "Failed to start BLE";
            startButton.Enabled = true;
            stopButton.Enabled = false;

            MessageBox.Show(
                ex.Message,
                "BLE Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }

    private void StopBeacon(object? sender, EventArgs e)
    {
        try
        {
            publisher?.Stop();
            statusLabel.Text = "BLE Status: Stopped";
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                ex.Message,
                "BLE Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
        finally
        {
            publisher = null;
            startButton.Enabled = true;
            stopButton.Enabled = false;
        }
    }

    protected override void OnFormClosing(
        FormClosingEventArgs e)
    {
        closing = true;

        try
        {
            commandListener.Stop();
            commandListener.Close();
        }
        catch
        {
            // The server may not have started.
        }

        try
        {
            publisher?.Stop();
        }
        catch
        {
            // Clean up on exit.
        }

        publisher = null;

        base.OnFormClosing(e);
    }
}