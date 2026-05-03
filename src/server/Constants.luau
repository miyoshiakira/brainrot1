local Constants = {
    -- テーブルとして定義（大文字で書くのが慣習）
    MAX_SLOTS = 10,
    CHARACTER_MODEL_NAME = "DisplayMonster",
}

return table.freeze(Constants) -- table.freeze を使うと書き換え不能に！