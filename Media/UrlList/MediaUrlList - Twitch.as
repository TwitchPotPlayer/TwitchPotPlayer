/*
	This is the source code of Twitch url list extension.
	Copyright github.com/23rd, 2018-2019.

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
	return "1.1";
}

string GetDesc() {
	return "Twitch";
}

string GetLoginName(string id, string header){
	string jsonOfUserID = HostUrlGetString("https://api.twitch.tv/helix/users?id=" + id, "", header);
	JsonReader TwitchOnlineReader;
	JsonValue TwitchOnlineRoot;
	if (TwitchOnlineReader.parse(jsonOfUserID, TwitchOnlineRoot) && TwitchOnlineRoot.isObject()) {
		JsonValue data = TwitchOnlineRoot["data"];
		return data[0]["login"].asString();
	}
	return "failed";
}

array<dictionary> GetCategorys() {
	array<dictionary> ret;
	
	dictionary item1;
	item1["title"] = "{$CP1251=подписки онлайн$}{$CP0=Your Follows$}";
	item1["Category"] = "most";
	ret.insertLast(item1);
	return ret;
}

array<dictionary> GetChunkOfUsersOnline(string allFollowersIds, string header) {
	array<dictionary> ret;
	// Get channels which is online right now.
	string jsonOfUserOnline = HostUrlGetString("https://api.twitch.tv/helix/streams?" + allFollowersIds, "", header);

	// Read json of online channels.
	JsonReader TwitchOnlineReader;
	JsonValue TwitchOnlineRoot;
	if (TwitchOnlineReader.parse(jsonOfUserOnline, TwitchOnlineRoot) && TwitchOnlineRoot.isObject()) {
		JsonValue streams = TwitchOnlineRoot["data"];
		if (streams.isArray()) {
			//Set every online channel in list of urls.
			for (int k = 0, lenNames = streams.size(); k < lenNames; k++) {
				string isPlaylist = streams[k]["type"].asString();
				string viewers = streams[k]["viewer_count"].asString();
				string user_name = streams[k]["user_name"].asString();
				string user_id = streams[k]["user_id"].asString();
				string login = GetLoginName(user_id, header);
				string title = streams[k]["title"].asString();
				// HostPrintUTF8(login);

				//If channel plays VOD add that string.
				if (isPlaylist != "live") {
					title = "[VOD] " + title;
				}

				title += " (" + viewers + ")";
				title = user_name + " | " + title;

				dictionary objectOfChannel;
				objectOfChannel["url"] = "https://twitch.tv/" + login;
				objectOfChannel["title"] = title;
				ret.insertLast(objectOfChannel);
			}
		}
	}

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
	string loginFromFile = HostFileRead(HostFileOpen("Extention\\Media\\UrlList\\TwitchLogin.txt"), 500);
	array<dictionary> ret;
	string api;

	HostPrintUTF8(loginFromFile + "...");
	if (loginFromFile.length() < 3) {
		return ShowError();
	}
	
	string getNameOfID = "https://api.twitch.tv/helix/users?";
	string idOfChannel = "";
	string header = "Client-ID: 1dviqtp3q3aq68tyvj116mezs3zfdml";

	// Get user id of twitch through username.
	string jsonOfYou = HostUrlGetString(getNameOfID + "login=" + loginFromFile, "", header);
	JsonReader TwitchYouReader;
	JsonValue TwitchYouRoot;
	if (TwitchYouReader.parse(jsonOfYou, TwitchYouRoot) && TwitchYouRoot.isObject()) {
		if (TwitchYouRoot["status"].asInt() == 400) {
			return ShowError();
		}
		if (TwitchYouRoot["data"].isArray() && TwitchYouRoot["data"].size() == 0) {
			return ShowError();
		}
		idOfChannel = TwitchYouRoot["data"][0]["id"].asString();
	}

	// Get list of id of channel that user follows.
	// API can get 100 user maximum. 
	// TODO: increase number of channels via cursors, that gives in json.
	api = "https://api.twitch.tv/helix/users/follows?first=100&from_id=" + idOfChannel;
	string json = HostUrlGetString(api, "", header);

	JsonReader TwitchReader;
	JsonValue TwitchRoot;

	if (TwitchReader.parse(json, TwitchRoot) && TwitchRoot.isObject()) {
		JsonValue items = TwitchRoot["data"];
		string user_id_list = "";

		if (items.isArray()) {
			// Read every ID in list to set them in user_id_list.
			for (int i = 0, len = items.size(); i < len; i++) {
				JsonValue item = items[i]["to_id"];
				user_id_list += "user_id=" + item.asString() + "&";
			}
			// It should be user_id=24991404&user_id=18587270&...
			ret.insertAt(0, GetChunkOfUsersOnline(user_id_list, header));
		}
	}

	return ret;
}
