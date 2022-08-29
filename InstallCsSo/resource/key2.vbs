Const ForReading = 1
Const ForWriting = 2

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("C:\Scripts\Text.txt", ForReading)
strText = objFile.ReadAll
objFile.Close
strNewText = Replace(strText, "Jim ", "James")
Set objFile = objFSO.OpenTextFile("C:\Scripts\Text.txt", ForWriting)
objFile.WriteLine strNewText
objFile.Close