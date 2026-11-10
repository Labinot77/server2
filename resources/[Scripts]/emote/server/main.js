FW = exports['fw-core'].GetCoreObject()

const db = {
  execute: (...args) => exports["oxmysql"].execute(...args),
};

const DEFAULT_META = {
  animSet: "default",
  expression: "default",
  quickEmotes: ["sit"],
};

function getPlayerId(src) {
  return FW.Functions.GetPlayerData(src).CitizenId
}

NPX.Procedures.register("emotes:getMeta", () => ({
  ...DEFAULT_META,
  quickEmotes: [...DEFAULT_META.quickEmotes],
}));

NPX.Procedures.register("emotes:setFavorite", (src, favorite) => {
  const playerId = getPlayerId(src);
  if (!playerId) return false;
  const { category, index, type, value } = favorite;

  db.execute(
    "SELECT id, emote_value FROM player_emotes WHERE citizenid = ? AND emote_category = ? AND emote_index = ? AND emote_type = ?",
    [playerId, category, index, type],
    (rows) => {
      if (rows && rows.length > 0) {
        const row = rows[0];
        if (row.emote_value === value) {
          db.execute("DELETE FROM player_emotes WHERE id = ?", [row.id], () => {
            console.log("Deleted emote entry");
          });
        } else {
          db.execute(
            "UPDATE player_emotes SET emote_value = ? WHERE id = ?",
            [value, row.id],
            () => {
              console.log("Updated emote entry");
            },
          );
        }
      } else {
        db.execute(
          "INSERT INTO player_emotes (citizenid, emote_category, emote_index, emote_type, emote_value) VALUES (?, ?, ?, ?, ?)",
          [playerId, category, index, type, value],
          () => {
            console.log("Inserted new emote entry");
          },
        );
      }
    },
  );

  return true;
});

NPX.Procedures.register("emotes:getFavorites", (src) => {
  const playerId = getPlayerId(src);
  if (!playerId) return null;

  return new Promise((resolve) => {
    db.execute("SELECT * FROM player_emotes WHERE citizenid = ?", [playerId], (rows) => {
      resolve(
        (rows || []).map((row) => ({
          category: row.emote_category,
          index: row.emote_index,
          type: row.emote_type,
          value: row.emote_value,
        })),
      );
    });
  });
});
