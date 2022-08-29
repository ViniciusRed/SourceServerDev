Const ForReading = 1
Const ForWriting = 2

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("%temp%\Key.cfg", ForReading)
strText = objFile.ReadAll
objFile.Close
strNewText = Replace(strText, "keyin", "keyout")
Set objFile = objFSO.OpenTextFile("%temp%\Key.cfg", ForWriting)
objFile.WriteLine strNewText
objFile.Close