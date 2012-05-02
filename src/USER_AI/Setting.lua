-- 設定読み書きクラス
-- 設定情報を保持しつつ、ファイルへの読み書きを暗黙的におこなう
Setting = {}
Setting.new = function(name)
  if name == nil or name == '' then
    return
  end

  local this = {}
  this.filename = name -- ファイル名
  this.setting = nil   -- 設定情報オブジェクト

  -- ファイル行のparse
  -- 「KEY=VALUE\n」の形をparseする
  this.parse = function(self, str)
    if str == nil or str == '' then
      return
    end

    local s, e, key, val = string.find(str, "^(.+)=(.+)$")
    if key == nil or val == nil then
      return
    end
    return string.trim(key), string.trim(val)
  end

  -- ファイルからの読み込み
  -- key, valueのペアをtableに格納して返す
  this.load = function(self)
    local f = io.open(self.filename, 'r')
    if f == nil then
      return {}
    end

    local ret = {}
    for line in f:lines() do
      local k, v = self:parse(string.chomp(line)) -- 改行削除
      if k ~= nil and v ~= nil then
        ret[k] = v
      end
    end
    f:close()
    return ret
  end

  -- ファイルへの書き込み
  -- 各情報を「KEY=VALUE\n」の形で書き込む
  this.save = function(self, t)
    if t == nil then
      return
    end

    local f = io.open(self.filename, "w")
    if f == nil then
      return
    end

    for k, v in pairs(t) do
      if k ~= nil and v ~= nil then
        f:write(k..'='..v..'\n')
      end
    end
    io.close(f)

    return self
  end

  -- 設定情報取得
  -- settingが読み込まれていなければファイルから読み込む
  -- keyが存在しなければnil
  this.get = function(self, key)
    if key == nil then
      return
    end

    if self.setting == nil then
      self.setting = (self:load() or {})
    end
    return self.setting[key]
  end

  -- 設定情報セット
  -- key, valueのペアが変更されていれば何もしない
  -- 変更された場合、settingの変更とsaveをおこなう
  this.set = function(self, key, val)
    if key == nil then
      return self
    end

    if self.setting == nil then
      self.setting = (self:load() or {})
    end

    if self.setting[key] == val then
      return self
    end

    self.setting[key] = val
    self:save(self.setting)

    return self
  end

  -- 設定全消去
  -- ファイルの中身もクリアするが、ファイル自体は削除しない
  this.clear = function(self)
    self.setting = {}
    self:save(self.setting)
    return self
  end

  return this
end
