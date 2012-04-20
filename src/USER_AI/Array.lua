-- サイズを持ったQueue
-- Queueのwrapperだけど、それぞれ適切な名前があるやも・・・
Array = {}
Array.new = function(size)
  if size == nil or size <= 0 then
    return
  end

  local this = {}
  this.maxSize = size
  this.list = Queue.new()

  -- リストのサイズ
  this.size = function(self)
    return self.list:size()
  end

  -- すでに満杯以上か？
  this.isOver = function(self)
    if self:size() >= self.maxSize then
      return true
    end
    return false
  end

  -- リストの最後に追加
  -- sizeオーバーなら無視
  this.add = function(self, data)
    if self:isOver() then
      return self
    end
    return self.list:add(data)
  end

  -- 先頭を取得して削除
  this.shift = function(self)
    return self.list:shift()
  end

  -- 後方を取得して削除
  this.pop = function(self)
    return self.list:pop()
  end

  -- 先頭に割り込み追加
  -- リストがフローした場合、同時に後方の要素を削除する
  this.unshift = function(self, data)
    if self:isOver() then
      self.list:pop()
    end
    self.list:unshift(data)
    return self
  end

  -- 後方から押し出し追加
  -- リストがフローした場合、同時に前方の要素を削除する
  this.push = function(self, data)
    if self:isOver() then
      self.list:shift()
    end
    self.list:add(data)
    return self
  end

  -- リストのクリア
  this.clear = function(self)
    return self.list:clear()
  end

  -- 値リスト取得
  -- headからtailまで順になったリストを返す
  this.values = function(self)
    return self.list:values()
  end

  -- 同一性確認
  -- サイズが同じで、格納されたvaluesが同一か？
  this.isEqual = function(self, other)
    return self.list:isEqual(other)
  end

  -- デバッグ用print
  this.print = function(self)
    print('maxSize:'..self.maxSize)
    self.list:print()
  end

  return this
end

-- 初期値つきnew
-- 第一引数のsizeを超えた分は無視される
Array.create = function(size, l)
  local a = Array.new(size)
  if a == nil then return end

  for i, v in pairs(l) do
    a:add(v)
  end
  return a
end
