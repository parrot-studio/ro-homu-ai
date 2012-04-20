-- ホムンクルスタイプ取得
-- ホム選択時の単純な判定用で、細かい判定はHomunculus内へ
function GetHomunculusType(id)
  return GetV(V_HOMUNTYPE, id)
end

-- typeやその他の条件を加味して、適切なAIを選択
function CreateHomunculus(id)
  local type = GetHomunculusType(id)
  local homu = Homunculus

  -- ここにホム選択ロジック
  if type == FILIR or type == FILIR2 or type == FILIR_H or type == FILIR_H2 then
    require(AI_BASE_PATH..'Filir.lua')
    homu = Filir -- フィーリルを選択
  end

  -- newして返す
  return homu.new(id)
end

-- main AI()
MyHomu = nil
function AI(myid)
  -- ホム初期化
  if MyHomu == nil then
    MyHomu = CreateHomunculus(myid)
  end

  -- 処理実行
  MyHomu:action()
end
