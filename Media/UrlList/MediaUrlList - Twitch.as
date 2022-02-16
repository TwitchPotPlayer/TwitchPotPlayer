/*
	This is the source code of Twitch url list extension.
	Copyright github.com/23rd, 2018-2020.

	Media url search by Twitch follows of username.
*/

//	string GetTitle() 													-> get title for UI
//	string GetVersion													-> get version for manage
//	string GetDesc()													-> get detail information
//	string GetLoginTitle()												-> get title for login dialog
//	string GetLoginDesc()												-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 						-> server check
//	string ServerLogin(string User, string Pass) 						-> login
//	void ServerLogout() 												-> logout
//	array<dictionary> GetCategorys()									-> get category list
//	array<dictionary> GetUrlList(string Category, string Genre, string PathToken, string Query, string PageToken)	-> get url list for Category

string GetTitle() {
	return "{$CP0=Twitch$}";
}

string GetLoginTitle() {
	return "Login of Twitch";
}

string GetLoginDesc() {
	return "LEAVE PASSWORD FIELD EMPTY.";
}

string ServerCheck(string User, string Pass) {
	if (User.length() > 2 && User.find(" ") == -1 && User.find(".") == -1) {
		HostSaveString("TwitchLogin", User);
	}
	return "Test.";
}

string ServerLogin(string User, string Pass) {
	if (User.length() > 2 && User.find(" ") == -1 && User.find(".") == -1) {
		HostSaveString("TwitchLogin", User);
	}
	return "Saved!";
}

string GetVersion() {
	return "1.4";
}

string GetDesc() {
	return "Twitch";
}

string getReg() {
	return "([-a-zA-Z0-9_]+)";
}

string getApi() {
	if (!IsTwitch) {
		return "https://potplayer.herokuapp.com/helix/";
	}
	return "https://api.twitch.tv/helix/";
}

class Config {
	string fullConfig;
	string clientID;
	string clientSecret;
	string twitchLogin;
	bool useOwnCredentials = false;

	bool isTrue(string option) {
		return (HostRegExpParse(fullConfig, option + "=([0-1])") == "1");
	}

	string parse(string s) {
		return HostRegExpParse(fullConfig, s + getReg());
	}
};

Config ReadConfigFile() {
	Config config;
	string path = "Extension\\Media\\UrlList\\config.ini";
	config.fullConfig = HostFileRead(HostFileOpen(path), 500);
	config.clientSecret = config.parse("clientSecret=");
	config.clientID = config.parse("clientID=");
	config.twitchLogin = config.parse("twitchLogin=");
	config.useOwnCredentials = config.isTrue("useOwnCredentials");
	return config;
}

Config ConfigData = ReadConfigFile();
string Authorization = GetAppAccessToken();
bool IsTwitch = (Authorization != "");

JsonValue SendTwitchAPIRequest(string request) {
	string header = "Client-ID: " + ConfigData.clientID;
	header += "\nAuthorization: Bearer " + Authorization;
	if (!IsTwitch) {
		header = "";
	}
	string json = HostUrlGetString(request, "", header);

	JsonReader twitchJsonReader;
	JsonValue twitchValueRoot;

	if (twitchJsonReader.parse(json, twitchValueRoot) && twitchValueRoot.isObject()) {
		return twitchValueRoot["data"];
	}
	return twitchValueRoot;
}

string GetAppAccessToken() {
	if (!ConfigData.useOwnCredentials) {
		ConfigData.clientID = "g5zg0400k4vhrx2g6xi4hgveruamlv";
		return "v4ks0wxfnsjzp7uwrcf8niiqwj64jy";
	}
	if (ConfigData.clientID == "" || ConfigData.clientSecret == "") {
		return "";
	}
	string postData = '{"grant_type":"client_credentials",';
	postData += '"client_id":"' + ConfigData.clientID + '",';
	postData += '"client_secret":"' + ConfigData.clientSecret + '"}';

	string json = HostUrlGetString(
		"https://id.twitch.tv/oauth2/token",
		"",
		"Content-Type: application/json",
		postData);

	JsonReader twitchJsonReader;
	JsonValue twitchValueRoot;

	if (twitchJsonReader.parse(json, twitchValueRoot) &&
		twitchValueRoot.isObject()) {
		return twitchValueRoot["access_token"].asString();
	}
	return "";
}

array<dictionary> GetCategorys() {
	array<dictionary> ret;

	dictionary item1;
	item1["title"] = "{$CP1251=подписки онлайн$}{$CP0=Your Follows$}";
	item1["Category"] = "most";
	ret.insertLast(item1);
	return ret;
}

array<dictionary> GetChunkOfUsersOnline(string allFollowersIds) {
	array<dictionary> ret;

	array<dictionary> nonLatinFollowersIds;
	string nonLatinFollowersIdsString;

	// Get channels which is online right now.
	JsonValue streams = SendTwitchAPIRequest(getApi() + "streams?" + allFollowersIds);
	if (streams.isArray()) {
		//Set every online channel in list of urls.
		for (int k = 0, lenNames = streams.size(); k < lenNames; k++) {
			string isPlaylist = streams[k]["type"].asString();
			string viewers = streams[k]["viewer_count"].asString();
			string userName = streams[k]["user_name"].asString();
			string userId = streams[k]["user_id"].asString();
			string login = HostRegExpParse(userName, getReg()).length() > 3
				? userName.MakeLower()
				: "";
			string title = streams[k]["title"].asString();
			// HostPrintUTF8(login);

			//If channel plays VOD add that string.
			if (isPlaylist != "live") {
				title = "[VOD] " + title;
			}

			title += " (" + viewers + ")";
			title = userName + " | " + title;

			dictionary objectOfChannel;
			objectOfChannel["url"] = "https://twitch.tv/" + login;
			objectOfChannel["title"] = title;
			if (login == "") {
				objectOfChannel["id"] = userId;
				nonLatinFollowersIdsString += "id=" + userId + "&";
				nonLatinFollowersIds.insertLast(objectOfChannel);
			} else {
				ret.insertLast(objectOfChannel);
			}
		}
	}

	// If we have users with non-latin usernames
	// we send an additional request to the Twitch API to get their logins.
	if (nonLatinFollowersIds.length() == 0) {
		return ret;
	}

	JsonValue users = SendTwitchAPIRequest(getApi() + "users?" + nonLatinFollowersIdsString);
	if (users.isArray()) {
		for (int k = 0, lenNames = users.size(); k < lenNames; k++) {
			nonLatinFollowersIds[k]["url"] = "https://twitch.tv/" + users[k]["login"].asString();
		}
	}
	ret.insertAt(ret.length() - 1, nonLatinFollowersIds);
	return ret;
}

array<dictionary> ShowError() {
	array<dictionary> ret;
	dictionary objectOfChannel;
	objectOfChannel["url"] = "...";
	objectOfChannel["title"] = "Please go to setting extension";
	ret.insertLast(objectOfChannel);
	objectOfChannel["url"] = "...";
	objectOfChannel["title"] = "and set your Twitch login.";
	ret.insertLast(objectOfChannel);
	return ret;
}

array<dictionary> GetUrlList(string Category, string Genre, string PathToken, string Query, string PageToken) {
	// HostOpenConsole();
	// string loginFromFile = HostLoadString("TwitchLogin");
	string loginFromFile = ConfigData.twitchLogin;
	array<dictionary> ret;
	string api;

	HostPrintUTF8(loginFromFile + "...");
	if (loginFromFile.length() < 3) {
		return ShowError();
	}

	string idOfChannel = "";
	// Get user id of twitch through username.
	JsonValue yourLogin = SendTwitchAPIRequest(getApi() + "users?login=" + loginFromFile);
	if (yourLogin.isArray() && yourLogin.size() == 0) {
		return ShowError();
	}
	idOfChannel = yourLogin[0]["id"].asString();

	// Get list of id of channel that user follows.
	// API can get 100 user maximum.
	// TODO: increase number of channels via cursors, that gives in json.
	JsonValue items = SendTwitchAPIRequest(getApi() + "users/follows?first=100&from_id=" + idOfChannel);
	string userIdList = "";
	if (items.isArray()) {
		// Read every ID in list to set them in userIdList.
		for (int i = 0, len = items.size(); i < len; i++) {
			JsonValue item = items[i]["to_id"];
			userIdList += "user_id=" + item.asString() + "&";
		}
		// It should be user_id=24991404&user_id=18587270&...
		ret.insertAt(0, GetChunkOfUsersOnline(userIdList));
	}

	return ret;
}
