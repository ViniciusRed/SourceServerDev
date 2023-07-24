
/* Download Manager */

#include "updater/download_steamworks.sp"

#warning Assumed DataPackPos type for QueuePack_URL.
static DataPackPos QueuePack_URL;

void FinalizeDownload(int index)
{
	/* Strip the temporary file extension from downloaded files. */
	char newpath[PLATFORM_MAX_PATH];
	char oldpath[PLATFORM_MAX_PATH];
	Handle hFiles = Updater_GetFiles(index);

	int maxFiles = GetArraySize(hFiles);
	for (int i = 0; i < maxFiles; i++)
	{
		GetArrayString(hFiles, i, newpath, sizeof(newpath));
		Format(oldpath, sizeof(oldpath), "%s.%s", newpath, TEMP_FILE_EXT);

		// Rename doesn't overwrite on Windows. Make sure the path is clear.
		if (FileExists(newpath))
			DeleteFile(newpath);

		RenameFile(newpath, oldpath);
	}

	ClearArray(hFiles);
}

void AbortDownload(int index)
{
	/* Delete all downloaded temporary files. */
	char path[PLATFORM_MAX_PATH];
	Handle hFiles = Updater_GetFiles(index);

	int maxFiles = GetArraySize(hFiles);
	for (int i = 0; i < maxFiles; i++)
	{
		GetArrayString(hFiles, 0, path, sizeof(path));
		Format(path, sizeof(path), "%s.%s", path, TEMP_FILE_EXT);

		if (FileExists(path))
			DeleteFile(path);
	}

	ClearArray(hFiles);
}

void ProcessDownloadQueue(bool force = false)
{
	if (!force && (g_bDownloading || !GetArraySize(g_hDownloadQueue)))
		return;

	Handle hQueuePack = GetArrayCell(g_hDownloadQueue, 0);
	SetPackPosition(hQueuePack, QueuePack_URL);

	char url[MAX_URL_LENGTH];
	char dest[PLATFORM_MAX_PATH];
	ReadPackString(hQueuePack, url, sizeof(url));
	ReadPackString(hQueuePack, dest, sizeof(dest));

	if (!STEAMWORKS_AVAILABLE())
		SetFailState(EXTENSION_ERROR);

#if defined DEBUG
	Updater_DebugLog("Download started:");
	Updater_DebugLog("  [0]  URL: %s", url);
	Updater_DebugLog("  [1]  Destination: %s", dest);
#endif

	g_bDownloading = true;

	if (STEAMWORKS_AVAILABLE())
	{
		if (SteamWorks_IsLoaded())
			Download_SteamWorks(url, dest);
		else
			CreateTimer(10.0, Timer_RetryQueue);
	}
}

public Action Timer_RetryQueue(Handle timer)
{
	ProcessDownloadQueue(true);

	return Plugin_Stop;
}

void AddToDownloadQueue(int index, const char []url, const char []dest)
{
	Handle hQueuePack = CreateDataPack();
	WritePackCell(hQueuePack, index);

	QueuePack_URL = GetPackPosition(hQueuePack);
	WritePackString(hQueuePack, url);
	WritePackString(hQueuePack, dest);

	PushArrayCell(g_hDownloadQueue, hQueuePack);

	ProcessDownloadQueue();
}

void DownloadEnded(bool successful, const char []error = "")
{
	Handle hQueuePack = GetArrayCell(g_hDownloadQueue, 0);
	ResetPack(hQueuePack);

	char url[MAX_URL_LENGTH];
	char dest[PLATFORM_MAX_PATH];
	int index = ReadPackCell(hQueuePack);
	ReadPackString(hQueuePack, url, sizeof(url));
	ReadPackString(hQueuePack, dest, sizeof(dest));

	// Remove from the queue.
	CloseHandle(hQueuePack);
	RemoveFromArray(g_hDownloadQueue, 0);

#if defined DEBUG
	Updater_DebugLog("  [2]  Successful: %s", successful ? "Yes" : "No");
#endif

	switch (Updater_GetStatus(index))
	{
		case Status_Checking:
		{
			if (!successful || !ParseUpdateFile(index, dest))
			{
				Updater_SetStatus(index, Status_Idle);

#if defined DEBUG
				if (error[0] != '\0')
					Updater_DebugLog("  [2]  %s", error);
#endif
			}
		}

		case Status_Downloading:
		{
			if (successful)
			{
				// Check if this was the last file we needed.
				char lastfile[PLATFORM_MAX_PATH];
				Handle hFiles = Updater_GetFiles(index);

				GetArrayString(hFiles, GetArraySize(hFiles) - 1, lastfile, sizeof(lastfile));
				Format(lastfile, sizeof(lastfile), "%s.%s", lastfile, TEMP_FILE_EXT);

				if (StrEqual(dest, lastfile))
				{
					Handle hPlugin = IndexToPlugin(index);

					Fwd_OnPluginUpdating(hPlugin);
					FinalizeDownload(index);

					char sName[64];
					if (!GetPluginInfo(hPlugin, PlInfo_Name, sName, sizeof(sName)))
						strcopy(sName, sizeof(sName), "Null");

					Updater_Log("Successfully updated and installed \"%s\".", sName);

					Updater_SetStatus(index, Status_Updated);
					Fwd_OnPluginUpdated(hPlugin);
				}
			}
			else
			{
				// Failed during an update.
				AbortDownload(index);
				Updater_SetStatus(index, Status_Error);

				char filename[64];
				GetPluginFilename(IndexToPlugin(index), filename, sizeof(filename));
				Updater_Log("Error downloading update for plugin: %s", filename);
				Updater_Log("  [0]  URL: %s", url);
				Updater_Log("  [1]  Destination: %s", dest);

				if (error[0] != '\0')
					Updater_Log("  [2]  %s", error);
			}
		}

		case Status_Error:
		{
			// Delete any additional files that this plugin had queued.
			if (successful && FileExists(dest))
				DeleteFile(dest);
		}
	}

	g_bDownloading = false;
	ProcessDownloadQueue();
}
