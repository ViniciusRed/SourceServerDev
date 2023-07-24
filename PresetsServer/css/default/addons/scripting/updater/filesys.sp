
/* File System Parsers */

// Strip filename from path.
void StripPathFilename(char []path)
{
	strcopy(path, FindCharInString(path, '/', true) + 1, path);
}

// Return the filename and extension from a given path.
void GetPathBasename(char []path, char []buffer, int maxlength)
{
	int check = -1;
	if ((check = FindCharInString(path, '/', true)) != -1
		|| (check = FindCharInString(path, '\\', true)) != -1)
		strcopy(buffer, maxlength, path[check+1]);
	else
		strcopy(buffer, maxlength, path);
}

// Add http protocol to url if it's missing.
void PrefixURL(char []buffer, int maxlength, const char []url)
{
	if (strncmp(url, "http://", 7) != 0 && strncmp(url, "https://", 8) != 0)
		Format(buffer, maxlength, "http://%s", url);
	else
		strcopy(buffer, maxlength, url);
}

// Split URL into hostname, location, and filename. No trailing slashes.
stock void ParseURL(const char []url, char []host, int maxHost,
		char []location, int maxLoc, char []filename, int maxName)
{
	// Strip url prefix.
	int idx = StrContains(url, "://");
	idx = (idx != -1) ? idx + 3 : 0;

	char dirs[16][64];
	int total = ExplodeString(url[idx], "/", dirs, sizeof(dirs), sizeof(dirs[]));

	// host
	Format(host, maxHost, "%s", dirs[0]);

	// location
	location[0] = '\0';
	for (int i = 1; i < total - 1; i++)
		Format(location, maxLoc, "%s/%s", location, dirs[i]);

	// filename
	Format(filename, maxName, "%s", dirs[total-1]);
}

// Converts Updater SMC file paths into paths relative to the game folder.
void ParseSMCPathForLocal(const char []path, char []buffer, int maxlength)
{
	char dirs[16][64];
	int total = ExplodeString(path, "/", dirs, sizeof(dirs), sizeof(dirs[]));

	if (StrEqual(dirs[0], "Path_SM"))
		BuildPath(Path_SM, buffer, maxlength, "");
	else // Path_Mod
		buffer[0] = '\0';

	// Construct the path and create directories if needed.
	for (int i = 1; i < total - 1; i++)
	{
		Format(buffer, maxlength, "%s%s/", buffer, dirs[i]);

		if(!DirExists(buffer))
			CreateDirectory(buffer, 511);
	}

	// Add the filename to the end of the path.
	Format(buffer, maxlength, "%s%s", buffer, dirs[total-1]);
}

// Converts Updater SMC file paths into paths relative to the plugin's update URL.
void ParseSMCPathForDownload(const char []path, char []buffer, int maxlength)
{
	char dirs[16][64];
	int total = ExplodeString(path, "/", dirs, sizeof(dirs), sizeof(dirs[]));

	// Construct the path.
	buffer[0] = '\0';
	for (int i = 1; i < total; i++)
		Format(buffer, maxlength, "%s/%s", buffer, dirs[i]);
}

// Parses a plugin's update file.
// Logs update notes and begins download if required.
// Returns true if an update was available.
static Handle SMC_Sections;
static Handle SMC_DataTrie;
static Handle SMC_DataPack;
static int SMC_LineNum;

bool ParseUpdateFile(int index, const char []path)
{
	/* Return true if an update was available. */
	SMC_Sections = CreateArray(64);
	SMC_DataTrie = CreateTrie();
	SMC_DataPack = CreateDataPack();
	SMC_LineNum = 0;

	Handle smc = SMC_CreateParser();

	SMC_SetRawLine(smc, Updater_RawLine);
	SMC_SetReaders(smc, Updater_NewSection, Updater_KeyValue, Updater_EndSection);

	char sBuffer[MAX_URL_LENGTH];
	Handle hPack;
	bool bUpdate = false;
	SMCError err = SMC_ParseFile(smc, path);

	if (err == SMCError_Okay)
	{
		// Initialize data
		Handle hPlugin = IndexToPlugin(index);
		Handle hFiles = Updater_GetFiles(index);
		ClearArray(hFiles);

		// current version.
		char sCurrentVersion[16];

		if (!GetPluginInfo(hPlugin, PlInfo_Version, sCurrentVersion, sizeof(sCurrentVersion)))
			strcopy(sCurrentVersion, sizeof(sCurrentVersion), "Null");

		// latest version.
		char smcLatestVersion[16];

		if (GetTrieValue(SMC_DataTrie, "version->latest", hPack))
		{
			ResetPack(hPack);
			ReadPackString(hPack, smcLatestVersion, sizeof(smcLatestVersion));
		}

		// Check if we have the latest version.
		if (!StrEqual(sCurrentVersion, smcLatestVersion))
		{
			char sFilename[64];
			char sName[64];
			GetPluginFilename(hPlugin, sFilename, sizeof(sFilename));

			if (GetPluginInfo(hPlugin, PlInfo_Name, sName, sizeof(sName)))
				Updater_Log("Update available for \"%s\" (%s). Current: %s - Latest: %s", sName, sFilename, sCurrentVersion, smcLatestVersion);
			else
				Updater_Log("Update available for \"%s\". Current: %s - Latest: %s", sFilename, sCurrentVersion, smcLatestVersion);

			if (GetTrieValue(SMC_DataTrie, "information->notes", hPack))
			{
				ResetPack(hPack);

				int iCount = 0;
				while (IsPackReadable(hPack, 1))
				{
					ReadPackString(hPack, sBuffer, sizeof(sBuffer));
					Updater_Log("  [%i]  %s", iCount++, sBuffer);
				}
			}

			// Log update notes, save file list, and begin downloading.
			if (g_bGetDownload && Fwd_OnPluginDownloading(hPlugin) == Plugin_Continue)
			{
				// Get previous version.
				char smcPrevVersion[16];
				if (GetTrieValue(SMC_DataTrie, "version->previous", hPack))
				{
					ResetPack(hPack);
					ReadPackString(hPack, smcPrevVersion, sizeof(smcPrevVersion));
				}

				// Check if we only need the patch files.
				if (StrEqual(sCurrentVersion, smcPrevVersion) && GetTrieValue(SMC_DataTrie, "patch->plugin", hPack))
				{
					ParseSMCFilePack(index, hPack, hFiles);

					if (g_bGetSource && GetTrieValue(SMC_DataTrie, "patch->source", hPack))
						ParseSMCFilePack(index, hPack, hFiles);
				}
				else if (GetTrieValue(SMC_DataTrie, "files->plugin", hPack))
				{
					ParseSMCFilePack(index, hPack, hFiles);

					if (g_bGetSource && GetTrieValue(SMC_DataTrie, "files->source", hPack))
						ParseSMCFilePack(index, hPack, hFiles);
				}

				Updater_SetStatus(index, Status_Downloading);
			}
			else
			{
				// We don't want to spam the logs with the same update notification.
				Updater_SetStatus(index, Status_Updated);
			}

			bUpdate = true;
		}

#if defined DEBUG
		int iCount = 0;

		Updater_DebugLog(" ");
		Updater_DebugLog("SMC DEBUG");
		ResetPack(SMC_DataPack);

		while (IsPackReadable(SMC_DataPack, 1))
		{
			ReadPackString(SMC_DataPack, sBuffer, sizeof(sBuffer));
			Updater_DebugLog("%s", sBuffer);

			if (GetTrieValue(SMC_DataTrie, sBuffer, hPack))
			{
				iCount = 0;
				ResetPack(hPack);

				while (IsPackReadable(hPack, 1))
				{
					ReadPackString(hPack, sBuffer, sizeof(sBuffer));
					Updater_DebugLog("  [%i]  %s", iCount++, sBuffer);
				}
			}
		}
		Updater_DebugLog("END SMC DEBUG");
		Updater_DebugLog(" ");
#endif
	}
	else
	{
		Updater_Log("SMC parsing error on line %d", SMC_LineNum);

		Updater_GetURL(index, sBuffer, sizeof(sBuffer));
		Updater_Log("  [0]  URL: %s", sBuffer);

		if (SMC_GetErrorString(err, sBuffer, sizeof(sBuffer)))
		{
			Updater_Log("  [1]  ERROR: %s", sBuffer);
		}
	}

	// Clean up SMC data.
	ResetPack(SMC_DataPack);

	while (IsPackReadable(SMC_DataPack, 1))
	{
		ReadPackString(SMC_DataPack, sBuffer, sizeof(sBuffer));

		if (GetTrieValue(SMC_DataTrie, sBuffer, hPack))
		{
			CloseHandle(hPack);
		}
	}

	CloseHandle(SMC_Sections);
	CloseHandle(SMC_DataTrie);
	CloseHandle(SMC_DataPack);
	CloseHandle(smc);

	return bUpdate;
}

void ParseSMCFilePack(int index, Handle hPack, Handle hFiles)
{
	// Prepare URL
	char urlprefix[MAX_URL_LENGTH];
	char url[MAX_URL_LENGTH];
	char dest[PLATFORM_MAX_PATH];
	char sBuffer[MAX_URL_LENGTH];
	Updater_GetURL(index, urlprefix, sizeof(urlprefix));
	StripPathFilename(urlprefix);

	ResetPack(hPack);

	while (IsPackReadable(hPack, 1))
	{
		ReadPackString(hPack, sBuffer, sizeof(sBuffer));

		// Merge url.
		ParseSMCPathForDownload(sBuffer, url, sizeof(url));
		Format(url, sizeof(url), "%s%s", urlprefix, url);

		// Make sure the current plugin path matches the update.
		ParseSMCPathForLocal(sBuffer, dest, sizeof(dest));

		char sLocalBase[64];
		char sPluginBase[64];
		char sFilename[64];
		GetPathBasename(dest, sLocalBase, sizeof(sLocalBase));
		GetPathBasename(sFilename, sPluginBase, sizeof(sPluginBase));

		if (StrEqual(sLocalBase, sPluginBase))
		{
			StripPathFilename(dest);
			Format(dest, sizeof(dest), "%s/%s", dest, sFilename);
		}

		// Save the file location for later.
		PushArrayString(hFiles, dest);

		// Add temporary file extension.
		Format(dest, sizeof(dest), "%s.%s", dest, TEMP_FILE_EXT);

		// Begin downloading file.
		AddToDownloadQueue(index, url, dest);
	}
}

public SMCResult Updater_RawLine(Handle smc, const char []line, int lineno)
{
	SMC_LineNum = lineno;
	return SMCParse_Continue;
}

public SMCResult Updater_NewSection(Handle smc, const char []name, bool opt_quotes)
{
	PushArrayString(SMC_Sections, name);
	return SMCParse_Continue;
}

public SMCResult Updater_KeyValue(Handle smc, const char []key,
					const char []value, bool key_quotes,
					bool value_quotes)
{
	char sCurSection[MAX_URL_LENGTH];
	char sKey[MAX_URL_LENGTH];
	Handle hPack;

	GetArrayString(SMC_Sections, GetArraySize(SMC_Sections)-1, sCurSection, sizeof(sCurSection));
	FormatEx(sKey, sizeof(sKey), "%s->%s", sCurSection, key);
	StringToLower(sKey);

	if (!GetTrieValue(SMC_DataTrie, sKey, hPack))
	{
		hPack = CreateDataPack();
		SetTrieValue(SMC_DataTrie, sKey, hPack);
		WritePackString(SMC_DataPack, sKey);
	}

	WritePackString(hPack, value);
	return SMCParse_Continue;
}

public SMCResult Updater_EndSection(Handle smc)
{
	if (GetArraySize(SMC_Sections))
		RemoveFromArray(SMC_Sections, GetArraySize(SMC_Sections)-1);

	return SMCParse_Continue;
}

stock void StringToLower(char []input)
{
	int length = strlen(input);

	for (int i = 0; i < length; i++)
		input[i] = CharToLower(input[i]);
}
