using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

internal static class EldenRingUltrawideLauncher
{
    private const string GameDirectory = @"C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING\Game";
    private const string OriginalPath = GameDirectory + @"\eldenring.exe";
    private const string TemporaryPath = GameDirectory + @"\eldenring_ultrawide_tmp.exe";
    private const string StagingPath = GameDirectory + @"\.eldenring_ultrawide_tmp.exe.new";
    private const string LogPath = @"C:\EldenRingTools\elden-ring-ultrawide.log";
    private const long PatchOffset = 0x19ED05E;
    private static readonly byte[] ExpectedSignature = { 0x74, 0x4F, 0x45, 0x8B, 0x94, 0xCC };

    private static void Log(string message)
    {
        File.AppendAllText(LogPath, DateTime.Now.ToString("s") + " " + message + Environment.NewLine);
    }

    private static void DeleteTemporaryFiles()
    {
        try { if (File.Exists(StagingPath)) File.Delete(StagingPath); } catch { }
        try { if (File.Exists(TemporaryPath)) File.Delete(TemporaryPath); } catch { }
    }

    [STAThread]
    private static int Main()
    {
        bool ownsMutex;
        using (var mutex = new Mutex(true, @"Local\EldenRingUltrawideLauncher", out ownsMutex))
        {
            if (!ownsMutex)
            {
                Log("launch ignored: another launcher is already active");
                return 0;
            }

            Log("cold launch started");
            try
            {
                DeleteTemporaryFiles();

                using (var source = new FileStream(OriginalPath, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    if (source.Length <= PatchOffset + ExpectedSignature.Length)
                        throw new InvalidDataException("clean executable is smaller than the expected patch offset");

                    source.Position = PatchOffset;
                    for (int index = 0; index < ExpectedSignature.Length; index++)
                    {
                        int value = source.ReadByte();
                        if (value != ExpectedSignature[index])
                            throw new InvalidDataException("ultrawide signature mismatch; clean executable was not modified");
                    }
                }

                File.Copy(OriginalPath, StagingPath, true);
                using (var staging = new FileStream(StagingPath, FileMode.Open, FileAccess.Write, FileShare.None))
                {
                    staging.Position = PatchOffset;
                    staging.WriteByte(0xEB);
                    staging.Flush(true);
                }
                File.Move(StagingPath, TemporaryPath);
                Log("temporary executable ready: offset=0x19ED05E");

                var startInfo = new ProcessStartInfo
                {
                    FileName = TemporaryPath,
                    WorkingDirectory = GameDirectory,
                    UseShellExecute = false
                };
                using (var game = Process.Start(startInfo))
                {
                    if (game == null)
                        throw new InvalidOperationException("Windows did not return an Elden Ring process");
                    game.WaitForExit();
                    Log("game process finished: launcher_exit=" + game.ExitCode);
                }
                return 0;
            }
            catch (Exception error)
            {
                Log("ERROR: " + error.GetType().Name + ": " + error.Message);
                return 1;
            }
            finally
            {
                DeleteTemporaryFiles();
                Log("temporary executable cleaned");
                mutex.ReleaseMutex();
            }
        }
    }
}

