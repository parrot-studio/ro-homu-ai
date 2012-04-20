-- UtilのListがあまりに美しくないので、オブジェクト的に書き直し
-- 公式のtable系関数が使えないので、ロジックでの実装
Queue = {}
Queue.new = function()
  local this = {}
  this.list = {}
  this.head = 0
  this.tail = 0

  -- キューの最後に追加
  this.add = function(self, data)
    self.list[self.tail] = data
    self.tail = this.tail + 1
    return self
  end

  -- キューの最後に追加
  -- Arrayとの互換性のために定義
  this.push = function(self, data)
    self:add(data)
  end

  -- 先頭を取得して削除
  this.shift = function(self)
    local ret = self.list[self.head]
    if ret then
      self.list[self.head] = nil
      self.head = self.head + 1
    end
    return ret
  end

  -- 後方を取得して削除
  this.pop = function(self)
    local ret = self.list[self.tail-1]
    if ret then
      self.list[self.tail-1] = nil
      self.tail = self.tail - 1
    end
    return ret
  end

  -- 先頭に割り込み追加
  this.unshift = function(self, data)
    self.head = self.head - 1
    self.list[self.head] = data
    return self
  end

  -- キューのサイズ
  this.size = function(self)
    return self.tail - self.head
  end

  -- キューのクリア
  this.clear = function(self)
    self.list = {}
    self.head = 0
    self.tail = 0
    return self
  end

  -- 値リスト取得
  -- headからtailまで順になったリストを返す
  this.values = function(self)
    local size = self:size()
    if size == 0 then return {} end
    if size == 1 then return { self.list[self.head] } end

    local ret = {}
    for i = 1, self:size() do
      ret[i] = self.list[self.head+i-1]
    end
    return ret
  end

  -- 同一性確認
  -- サイズが同じで、格納されたvaluesが同一か？
  this.isEqual = function(self, other)
    if other == nil then return false end
    if self:size() ~= other:size() then return false end
    if self:size() == 0 then return true end -- サイズが同一で0＝両方空

    local svs = self:values()
    local ovs = other:values()
    local ret = true
    for i = 1, self:size() do
      if svs[i] ~= ovs[i] then
        ret = false
        break
      end
    end

    return ret
  end

  -- デバッグ用print
  this.print = function(self)
    for i,v in pairs(self.list) do
      print(i, v)
    end
  end

  return this
end

-- 初期値つきnew
Queue.create = function(l)
  local q = Queue.new()
  for i, v in pairs(l) do
    q:add(v)
  end
  return q
end
