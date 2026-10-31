# Reading player feedback

Players can open **Feedback** from the lobby or the results screen: a 1-5 rating, quick tags, and an
optional comment (filtered by Roblox's text filter before it's stored). It's optional and never
shown to other players.

Where it goes:

- **Studio:** every entry is printed in the Output as a `[Feedback]` line.
- **Creator Dashboard:** ratings arrive as the custom analytics event `FeedbackRating`
  (Analytics > Custom events).
- **DataStore `Feedback_v1`:** every entry, with its time, user id, game version, level, rating,
  tags and comment. To list them, open the place in Studio (Game Settings > Security > Enable
  Studio Access to API Services) and run this in the Command Bar:

```lua
local store = game:GetService("DataStoreService"):GetDataStore("Feedback_v1")
local pages = store:ListKeysAsync()
while true do
	for _, key in pages:GetCurrentPage() do
		print(key.KeyName, game:GetService("HttpService"):JSONEncode(store:GetAsync(key.KeyName)))
	end
	if pages.IsFinished then break end
	pages:AdvanceToNextPageAsync()
end
```

Progress (levels and coins) is saved in the `Progress_v1` DataStore. Without API access in Studio,
progress lasts the session only, and the lobby shows "(not saved)".
