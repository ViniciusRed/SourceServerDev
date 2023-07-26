
/* PluginPack Helpers */

#warning PluginPack_* has changed type to DataPackPos, could cause errors?
static DataPackPos PluginPack_Plugin;
static DataPackPos PluginPack_Files;
static DataPackPos PluginPack_Status;
static DataPackPos PluginPack_URL;

int GetMaxPlugins()
{
	return GetArraySize(g_hPluginPacks);
}

bool IsValidPlugin(Handle plugin)
{
	/* Check if the plugin handle is pointing to a valid plugin. */
	Handle hIterator = GetPluginIterator();
	bool bIsValid = false;

	while (MorePlugins(hIterator))
	{
		if (plugin == ReadPlugin(hIterator))
		{
			bIsValid = true;
			break;
		}
	}

	CloseHandle(hIterator);
	return bIsValid;
}

int PluginToIndex(Handle plugin)
{
	Handle hPluginPack = INVALID_HANDLE;

	int maxPlugins = GetMaxPlugins();
	for (int i = 0; i < maxPlugins; i++)
	{
		hPluginPack = GetArrayCell(g_hPluginPacks, i);
		SetPackPosition(hPluginPack, PluginPack_Plugin);

		if (plugin == view_as<Handle>(ReadPackCell(hPluginPack)))
			return i;
	}

	return -1;
}

Handle IndexToPlugin(int index)
{
	Handle hPluginPack = view_as<Handle>(GetArrayCell(g_hPluginPacks, index));
	SetPackPosition(hPluginPack, PluginPack_Plugin);
	return view_as<Handle>(ReadPackCell(hPluginPack));
}

void Updater_AddPlugin(Handle plugin, const char []url)
{
	int index = PluginToIndex(plugin);

	if (index != -1)
	{
		// Remove plugin from removal queue.
		int maxPlugins = GetArraySize(g_hRemoveQueue);
		for (int i = 0; i < maxPlugins; i++)
		{
			if (plugin == GetArrayCell(g_hRemoveQueue, i))
			{
				RemoveFromArray(g_hRemoveQueue, i);
				break;
			}
		}

		// Update the url.
		Updater_SetURL(index, url);
	}
	else
	{
		Handle hPluginPack = CreateDataPack();
		Handle hFiles = CreateArray(PLATFORM_MAX_PATH);

		PluginPack_Plugin = GetPackPosition(hPluginPack);
		WritePackCell(hPluginPack, view_as<int>(plugin));

		PluginPack_Files = GetPackPosition(hPluginPack);
		WritePackCell(hPluginPack, view_as<int>(hFiles));

		PluginPack_Status = GetPackPosition(hPluginPack);
		WritePackCell(hPluginPack, view_as<int>(Status_Idle));

		PluginPack_URL = GetPackPosition(hPluginPack);
		WritePackString(hPluginPack, url);

		PushArrayCell(g_hPluginPacks, hPluginPack);
	}
}

void Updater_QueueRemovePlugin(Handle plugin)
{
	/* Flag a plugin for removal. */
	int maxPlugins = GetArraySize(g_hRemoveQueue);
	for (int i = 0; i < maxPlugins; i++)
	{
		// Make sure it wasn't previously flagged.
		if (plugin == GetArrayCell(g_hRemoveQueue, i))
		{
			return;
		}
	}

	PushArrayCell(g_hRemoveQueue, plugin);
	Updater_FreeMemory();
}

void Updater_RemovePlugin(int index)
{
	/* Warning: Removing a plugin will shift indexes. */
	CloseHandle(Updater_GetFiles(index)); // hFiles
	CloseHandle(GetArrayCell(g_hPluginPacks, index)); // hPluginPack
	RemoveFromArray(g_hPluginPacks, index);
}

Handle Updater_GetFiles(int index)
{
	Handle hPluginPack = GetArrayCell(g_hPluginPacks, index);
	SetPackPosition(hPluginPack, PluginPack_Files);
	return view_as<Handle>(ReadPackCell(hPluginPack));
}

UpdateStatus Updater_GetStatus(int index)
{
	Handle hPluginPack = GetArrayCell(g_hPluginPacks, index);
	SetPackPosition(hPluginPack, PluginPack_Status);
	return view_as<UpdateStatus>(ReadPackCell(hPluginPack));
}

void Updater_SetStatus(int index, UpdateStatus status)
{
	Handle hPluginPack = GetArrayCell(g_hPluginPacks, index);
	SetPackPosition(hPluginPack, PluginPack_Status);
	WritePackCell(hPluginPack, view_as<int>(status));
}

void Updater_GetURL(int index, char []buffer, int size)
{
	Handle hPluginPack = GetArrayCell(g_hPluginPacks, index);
	SetPackPosition(hPluginPack, PluginPack_URL);
	ReadPackString(hPluginPack, buffer, size);
}

void Updater_SetURL(int index, const char []url)
{
	Handle hPluginPack = GetArrayCell(g_hPluginPacks, index);
	SetPackPosition(hPluginPack, PluginPack_URL);
	WritePackString(hPluginPack, url);
}

/* Stocks */
// Todo: Call this after a successful download of an update when there are no players.
stock void ReloadPlugin(Handle plugin = INVALID_HANDLE)
{
	char filename[64];
	GetPluginFilename(plugin, filename, sizeof(filename));
	ServerCommand("sm plugins reload %s", filename);
}

stock void UnloadPlugin(Handle plugin = INVALID_HANDLE)
{
	char filename[64];
	GetPluginFilename(plugin, filename, sizeof(filename));
	ServerCommand("sm plugins unload %s", filename);
}

stock void DisablePlugin(Handle plugin = INVALID_HANDLE)
{
	char filename[64];
	char path_disabled[PLATFORM_MAX_PATH];
	char path_plugin[PLATFORM_MAX_PATH];

	GetPluginFilename(plugin, filename, sizeof(filename));
	BuildPath(Path_SM, path_disabled, sizeof(path_disabled), "plugins/disabled/%s", filename);
	BuildPath(Path_SM, path_plugin, sizeof(path_plugin), "plugins/%s", filename);

	if (FileExists(path_disabled))
		DeleteFile(path_disabled);

	if (!RenameFile(path_disabled, path_plugin))
		DeleteFile(path_plugin);

	ServerCommand("sm plugins unload %s", filename);
}
