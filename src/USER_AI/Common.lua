-- あえてグローバルで定義する定数・関数群
-- 特定のクラスに属させるのが難しいもののみをここに

-----------------------------
-- system constant
-----------------------------
AI_BASE_PATH     = './AI/USER_AI/' -- クライアントから見たAIの配置path
RES_COMMAND_SIZE = 10     -- 予約コマンドバッファサイズ
MIN_PLAYERS_ID   = 100001 -- プレイヤーIDの最低値（これより大きいIDはプレイヤー）
SMOOTH_MOVE_DELAY = 4     -- 等速移動時に実際の移動を遅らせる割合(n回ループに1回移動)

-----------------------------
-- state constant
-----------------------------
IDLE_ST              = 0
FOLLOW_ST            = 1
CHASE_ST             = 2
ATTACK_ST            = 3
MOVE_CMD_ST          = 4
STOP_CMD_ST          = 5
ATTACK_OBJECT_CMD_ST = 6
ATTACK_AREA_CMD_ST   = 7
PATROL_CMD_ST        = 8
HOLD_CMD_ST          = 9
SKILL_OBJECT_CMD_ST  = 10
SKILL_AREA_CMD_ST    = 11
FOLLOW_CMD_ST        = 12
-----------------------------

-----------------------------
-- command constant
-----------------------------
NONE_CMD          = 0
MOVE_CMD          = 1
STOP_CMD          = 2
ATTACK_OBJECT_CMD = 3
ATTACK_AREA_CMD   = 4
PATROL_CMD        = 5
HOLD_CMD          = 6
SKILL_OBJECT_CMD  = 7
SKILL_AREA_CMD    = 8
FOLLOW_CMD        = 9
-----------------------------

-----------------------------
-- motion constant
-----------------------------
MOTION_STAND    = 0  -- 立っている
MOTION_MOVE     = 1  -- 移動中
MOTION_ATTACK   = 2  -- 攻撃中
MOTION_DEAD     = 3  -- 死んで倒れる
MOTION_DAMAGE   = 4  -- ダメージを受けた時
MOTION_BENDDOWN = 5  -- かがむ（アイテムを拾う、罠を置く）
MOTION_SIT      = 6  -- 座っている
MOTION_SKILL    = 7  -- スキル攻撃中
MOTION_CASTING  = 8  -- 詠唱
MOTION_ATTACK2  = 9  -- 攻撃中
-----------------------------

-----------------------------
-- GetV constant
-----------------------------
V_OWNER       = 0  -- 主人のID
V_POSITION    = 1  -- 位置
V_TYPE        = 2  -- （未実装）
V_MOTION      = 3  -- モーション
V_ATTACKRANGE = 4  -- 射程（事実上未実装）
V_TARGET      = 5  -- ターゲット
V_SKILLATTACKRANGE = 6 -- スキル射程（事実上未実装）
V_HOMUNTYPE   = 7  -- ホムタイプ（実際はキャラのタイプ全て）
V_HP          = 8  -- 対象のHP
V_SP          = 9  -- 対象のSP
V_MAXHP       = 10 -- 対象のMHP
V_MAXSP       = 11 -- 対象のMSP
-----------------------------

-----------------------------
-- Homunculus type constants
-----------------------------
-- 2:亜種 H:進化
LIF           = 1
AMISTR        = 2
FILIR         = 3
VANILMIRTH    = 4
LIF2          = 5
AMISTR2       = 6
FILIR2        = 7
VANILMIRTH2   = 8
LIF_H         = 9
AMISTR_H      = 10
FILIR_H       = 11
VANILMIRTH_H  = 12
LIF_H2        = 13
AMISTR_H2     = 14
FILIR_H2      = 15
VANILMIRTH_H2 = 16
-----------------------------

-----------------------------
-- skill id constant
-----------------------------
SKILL_MOONLIGHT   = 8009
SKILL_FLEETMOVE   = 8010
SKILL_OVEREDSPEED = 8011
-----------------------------

-----------------------------
-- setting key constant
-----------------------------
SETTING_FILE_NAME = AI_BASE_PATH..'setting.txt' -- 設定保存ファイル名

SETTING_KEY_FIRST_ATTACK = 'FirstAttack' -- 先制設定キー
SETTING_KEY_AUTO_SKILL   = 'AutoSkill'   -- 自動スキル設定キー
-----------------------------

-----------------------------
-- Global Function
-----------------------------

-- デバッグ出力
-- 後々グローバルコンフィグで切り替え可能に
function PutsDubug(msg)
  if msg == nil or msg == '' then
    return
  end
  TraceAI(string.format("%q", msg))
end

-- ラストの改行を除去
function Chomp(s)
  if s == nil then
    return
  end
  local str, count = string.gsub(s, "[\r\n]+$", "")
  return str
end
