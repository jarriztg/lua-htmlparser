local ElementNode = require("ElementNode")
local voidelements = require("voidelements")

local HtmlParser = {}

local function parse(text)
  local root = ElementNode:new(text)

  local node, descend, tpos, opentags = root, true, 1, {}
  while true do
    local openstart, name
    openstart, tpos, name = string.find(root._text, "<(%w+)[^>]*>", tpos)
    if not name then break end
    local tag = ElementNode:new(name, node, descend, openstart, tpos)
    node = tag

    local tagst, apos = tag:gettext(), 1
    while true do
      local start, k, quote, v
      start, apos, k, quote = string.find(tagst, "%s+([^%s=]+)=(['\"]?)", apos)
      if not k then break end
      local pattern = "=([^%s'\">]*)"
      if quote ~= '' then
        pattern = quote .. "([^" .. quote .. "]*)" .. quote
      end
      start, apos, v = string.find(tagst, pattern, apos)
      tag:addattribute(k, v)
    end

    if voidelements[string.lower(tag.name)] then
      descend = false
      tag:close()
    else
      opentags[tag.name] = tag
    end

    local closeend = tpos
    while true do
      local closestart, closing, closename
      closestart, closeend, closing, closename = string.find(root._text, "[^<]*<(/?)(%w+)", closeend)
      closing = closing and closing ~= ''
      if not closing then break end
      tag = opentags[closename]
      opentags[closename] = nil
      closestart = string.find(root._text, "<", closestart)
      tag:close(closestart, closeend + 1)
      node = tag.parent
      descend = true
    end
  end

  return root
end
HtmlParser.parse = parse

return HtmlParser

