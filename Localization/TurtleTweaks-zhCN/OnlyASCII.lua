-- https://github.com/ericschn/OnlyASCII

local feature = ns.Register({
  identifier = "OnlyASCII",
  description = "隐藏包含非 ASCII 字符的聊天（会过滤掉中文）。",
  category = "social",
  config = {},
  data = {
    OnlyASCII_ChatFrame_OnEvent = nil
  }
})

if ns.IsEnabled(feature.identifier) then
  function ChatFrame_OnEvent(event)
    local chatMsg = arg1

    if (event == "CHAT_MSG_CHANNEL" or
        event == "CHAT_MSG_YELL" or
        event == "CHAT_MSG_SAY" or
        event == "CHAT_MSG_GUILD" or
        event == "CHAT_MSG_WHISPER") and arg2 and arg1 then
      for i = 1, string.len(chatMsg) do
        local byte = string.byte(string.sub(chatMsg, i, i))
        if byte > 126 then
          return false
        end
      end
    end

    feature.data.OnlyASCII_ChatFrame_OnEvent(event)
  end
end

