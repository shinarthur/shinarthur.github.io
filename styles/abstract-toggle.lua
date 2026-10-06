-- Decides, per `::: abstract` block, whether it is collapsed behind an
-- "Abstract" button (styles/abstract-toggle.html) or simply shown.
--
--   page default   `abstract-toggle: T` / `F` in the page's front matter
--                  (true when unset)
--   one entry      `::: {.abstract toggle=F}` overrides the page default
--
-- Accepts T/F, true/false, yes/no.

local function truthy(value)
  if type(value) == "boolean" then return value end
  local s = pandoc.utils.stringify(value):lower()
  return not (s == "f" or s == "false" or s == "no" or s == "0")
end

-- An abstract holding nothing but HTML comments (the placeholder) is dropped,
-- so an entry gets no Abstract button until real text is pasted in.
local function is_placeholder(blocks)
  for _, block in ipairs(blocks) do
    if not (block.t == "RawBlock" and block.text:match("^%s*<!%-%-.-%-%->%s*$")) then
      return false
    end
  end
  return true
end

local default = true

-- Meta has to be read before the Divs are visited, hence two passes.
return {
  {
    Meta = function(meta)
      if meta["abstract-toggle"] ~= nil then
        default = truthy(meta["abstract-toggle"])
      end
    end
  },
  {
    Div = function(el)
      if not el.classes:includes("abstract") then return nil end
      if is_placeholder(el.content) then return {} end
      local on = default
      if el.attributes["toggle"] ~= nil then
        on = truthy(el.attributes["toggle"])
        el.attributes["toggle"] = nil
      end
      el.attributes["data-collapsible"] = on and "true" or "false"
      return el
    end
  }
}
