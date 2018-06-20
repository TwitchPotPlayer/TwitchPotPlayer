/*
	Twitch media parse
*/	

//	string GetTitle() 									-> get title for UI
//	string GetVersion									-> get version for manage
//	string GetDesc()									-> get detail information
//	string GetLoginTitle()								-> get title for login dialog
//	string GetLoginDesc()								-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 		-> server check
//	string ServerLogin(string User, string Pass) 		-> login
//	void ServerLogout() 								-> logout
// 	bool PlayitemCheck(const string &in)				-> check playitem
//	array<dictionary> PlayitemParse(const string &in)	-> parse playitem
// 	bool PlaylistCheck(const string &in)				-> check playlist
//	array<dictionary> PlaylistParse(const string &in)	-> parse playlist

string GetTitle() {
	return "Twitch";
}

string GetVersion() {
	return "1";
}

string GetDesc() {
	return "https://twitch.tv/";
}

class QualityListItem {
	string url;
	string quality;
	string qualityDetail;
	string resolution;
	string bitrate;
	string format;
	int itag = 0;
	double fps = 0.0;
	int type3D = 0; // 1:sbs, 2:t&b
	bool is360 = false;

	dictionary toDictionary() {
		dictionary ret;
		
		ret["url"] = url;
		ret["quality"] = quality;
		ret["qualityDetail"] = qualityDetail;
		ret["resolution"] = resolution;
		ret["bitrate"] = bitrate;
		ret["format"] = format;
		ret["itag"] = itag;
		ret["fps"] = fps;
		ret["type3D"] = type3D;
		ret["is360"] = is360;
		return ret;
	}	
};

void Delete(string &a, int b) {
	a.erase(0, b);
}

void Swap(string &a, int b) {
	uint8 c = a[0];

	b %= a.size();
	a[0] = a[b];
	a[b] = c;
};

void Reverse(string &a) {
	int len = a.size();

	for (int i = 0; i < len / 2; ++i) {
		uint8 c = a[i];
		
		a[i] = a[len - i - 1];
		a[len - i - 1] = c;
	}
}

bool PlayitemCheck(const string &in path) {
	if (path.find("://twitch.tv") >= 0) {
		return true;
	}
	return false;
}

string PlayitemParse(const string &in path, dictionary &MetaData, array<dictionary> &QualityList) {
	// HostOpenConsole();
	
	// Any twitch API demands client id in header.
	string headerClientId = "Client-ID: 1dviqtp3q3aq68tyvj116mezs3zfdml";
	string nickname = HostRegExpParse(path, "https://twitch.tv/([-a-zA-Z0-9_]+)");

	// Firstly we need to request for api to get pretty weirdly token and sig.
	string tokenApi = "https://api.twitch.tv/api/channels/" + nickname + "/access_token?need_https=true";
	// Parameter p should be random number.
	string m3u8Api = "https://usher.ttvnw.net/api/channel/hls/" + nickname + ".m3u8?allow_source=true&p=7278365player_backend=mediaplayer&playlist_include_framerate=true&allow_audio_only=true";
	// &sig={token_sig}&token={token}
	string jsonToken = HostUrlGetString(tokenApi, "", headerClientId);

	// Get information of current stream.
	// string idChannel = HostRegExpParse(jsonToken, ":([0-9]+)");
	string jsonChannelStatus = HostUrlGetString("https://api.twitch.tv/kraken/channels/" + nickname, "", headerClientId);
	string titleStream;
	string game;
	string display_name;
	JsonReader StatusChannelReader;
	JsonValue StatusChannelRoot;
	if (StatusChannelReader.parse(jsonChannelStatus, StatusChannelRoot) && StatusChannelRoot.isObject()) {
		titleStream = StatusChannelRoot["status"].asString();
		game = StatusChannelRoot["game"].asString();
		display_name = StatusChannelRoot["display_name"].asString();
	}

	// Read weird token and sig.
	string sig;
	string token;
	JsonReader TokenReader;
	JsonValue TokenRoot;
	if (TokenReader.parse(jsonToken, TokenRoot) && TokenRoot.isObject()) {
		sig = "&sig=" + TokenRoot["sig"].asString();
		token = "&token=" + TokenRoot["token"].asString();
	}

	// Second request to get list of *.m3u8 urls.
	string jsonM3u8 = HostUrlGetString(m3u8Api + sig + token, "", headerClientId);
	jsonM3u8.replace('"', "");
	HostPrintUTF8(jsonM3u8);	


	string m3 = ".m3u8";

	string sourceQualityUrl = "https://" + HostRegExpParse(jsonM3u8, "https://([a-zA-Z-_.0-9/]+)" + m3) + m3;

	if (@QualityList !is null) {
		// Let's say there are max 20 qualities in total. If there are fewer of them, then just interrupt the cycle.
		for (int k = 0; k < 20; k++) {
			string currentQuality = HostRegExpParse(jsonM3u8, "NAME=([a-zA-Z-_.0-9/ ()]+)");
			string currentQualityUrl = "https://" + HostRegExpParse(jsonM3u8, "https://([a-zA-Z-_.0-9/]+)" + m3) + m3;

			if (currentQuality == "") {
				break;
			}

			jsonM3u8.replace(currentQualityUrl, "");
			jsonM3u8.replace("NAME=" + currentQuality, "");

			QualityListItem qualityItem;
			qualityItem.itag = k;
			qualityItem.quality = currentQuality;
			qualityItem.qualityDetail = currentQuality;
			qualityItem.url = currentQualityUrl;
			QualityList.insertLast(qualityItem.toDictionary());
		}
	}


	MetaData["title"] = titleStream;
	MetaData["content"] = titleStream + " | " + game + " | " + display_name;
	return sourceQualityUrl;
}

string FixHtmlSymbols(string inStr) {
	inStr.replace("&quot;", "\"");
	inStr.replace("&amp;", "&");
	inStr.replace("&#39;", "'");
	inStr.replace("&#039;", "'");
	inStr.replace("\\n", "\r\n");
	inStr.replace("\n", "\r\n");
	inStr.replace("\\", "");

	inStr.replace(" - YouTube", "");
	inStr.replace(" on Vimeo", "");

	return inStr;
}
