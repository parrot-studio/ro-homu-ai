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

  -- 先頭を取得して削除
  this.shift = function(self)
    local ret = self.list[self.head]
    if ret then
      self.list[self.head] = nil
      self.head = self.head + 1
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

  -- デバッグ用print
  this.print = function(self)
    for i,v in pairs(self.list) do
      print(i, v)
    end
  end

  return this
end
