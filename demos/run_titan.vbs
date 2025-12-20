Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "D:\Projects\Titan\bin\titan.exe D:\Projects\Titan\demos\gprint_wait.ttn", 1, False
WScript.Sleep 500
WshShell.SendKeys "RUN{ENTER}"
