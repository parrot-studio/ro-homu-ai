-- フィーリル用動作オブジェクト
-- Homunculusを継承し、必要な部分を書き換える
Filir = {}
Filir.new = function(id)
  local this = Homunculus.new(id)

  -- とりあえず継承のテストをしているだけで、細かい動作は未実装
  -- 攻撃時のスキル使用とかはここで実装する

  return this
end
