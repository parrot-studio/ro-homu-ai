-- デバッグ出力
function PutsDubug(msg)
  if msg == nil or msg == '' then
    return
  end
  TraceAI(string.format("%q", msg))
end

require './AI/USER_AI/Extend'
require './AI/USER_AI/Queue'
require './AI/USER_AI/Array'
require './AI/USER_AI/Logger'
require './AI/USER_AI/Setting'

require './AI/USER_AI/Common'
require './AI/USER_AI/Config'
require './AI/USER_AI/Homunculus'
require './AI/USER_AI/Main'
