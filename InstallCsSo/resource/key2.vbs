Const ForReading = 1
Const ForWriting = 2

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("%temp%\Key.cfg", ForReading)
strText = objFile.ReadAll
objFile.Close
strNewText = Replace(strText, "{ window.location.href = 'https://download1580.mediafire.com/fzl34irqgzqg/ut9d6b580y34dl1/csso_release_1.0.1.7z'; }", "{ CsSo=https://download1580.mediafire.com/fzl34irqgzqg/ut9d6b580y34dl1/csso_release_1.0.1.7z; }")
Set objFile = objFSO.OpenTextFile("%temp%\Key.cfg", ForWriting)
objFile.WriteLine strNewText
objFile.Close