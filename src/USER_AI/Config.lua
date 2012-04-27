-- グローバルコンフィグ
-- AIの全体的な設定をconfigファイルから構築する
Config = {}
(function(conf)
  -- config読み込みクラス
  -- ここでしか使わないのでlocal=private的に定義
  local ConfigLoader = {}
  ConfigLoader.new = function()
    local this = {}
    this.setting = Setting.new(CONFIG_FILE_NAME)

    this.get = function(self, key)
      return self.setting:get(key)
    end

    this.getBoolean = function(self, key)
      if self:get(key) == '1' then
        return true
      end
      return false
    end

    this.getNumber = function(self, key, default)
      local val = self:get(key)
      if val == nil then
        return default
      end
      return val * 1
    end

    return this
  end

  local loader = ConfigLoader.new()

  -- デバッグモード
  conf.DebugMode = loader:getBoolean('DebugMode')
  -- ログにTraceAIを使うか？
  conf.UseTraceAI = loader:getBoolean('UseTraceAI')

  -- 非移動のモンスターを索敵から除外するか？
  -- モンスターNPCへの突撃を防げるが、索敵効率が大幅に低下
  conf.ExcludeStandMonster = loader:getBoolean('ExcludeStandMonster')

  -- 等速移動時に実際の移動を遅らせる割合(n回ループに1回移動)
  conf.SmoothMoveDelay = loader:getNumber('SmoothMoveDelay', 4)

  -- 主人との至近距離
  conf.AroundDistance = loader:getNumber('AroundDistance', 3)
  -- 索敵範囲
  conf.SearchDistance = loader:getNumber('SearchDistance', 10)
  -- 主人との最大距離
  conf.FollowDistance = loader:getNumber('FollowDistance', 10)
end)(Config)
