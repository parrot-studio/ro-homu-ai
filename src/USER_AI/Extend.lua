-- 標準ライブラリを拡張

-- ラストの改行を除去
if string.chomp == nil then
  string.chomp = function(s)
    if s == nil then
      return
    end
    local str, count = string.gsub(s, "[\r\n]+$", "")
    return str
  end
end

-- 前後の空白除去
if string.trim == nil then
  string.trim = function(s)
    if s == nil then
      return
    end
    local str, count = string.gsub(s, "^%s*(.-)%s*$", "%1")
    return str
  end
end
