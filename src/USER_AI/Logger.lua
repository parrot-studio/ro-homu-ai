-- ログ出力クラス
-- 時刻と共にログを追記する
Logger = {}
Logger.new = function(name)
  if name == nil or name == '' then
    return
  end

  local this = {}
  this.filename = name
  this.lastLog = nil

  this.dateString = function()
    local t = os.date('*t')
    return string.format('%04d/%02d/%02d %02d:%02d:%02d',
    t.year, t.month, t.day, t.hour, t.min, t.sec)
  end

  -- ログ出力
  this.write = function(self, msg)
    if msg == nil or msg == '' then
      return
    end

    if msg == self.lastLog then
      return
    end

    local f = io.open(self.filename, "a")
    if f == nil then
      return
    end

    f:write(string.format('(%s) %s\n', self.dateString(), msg))
    io.close(f)
    self.lastLog = msg
  end

  return this
end
