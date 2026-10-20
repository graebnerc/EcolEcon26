--[[
  emoji-img.lua — swap the deck's emoji for Twemoji SVGs.

  The Keynote decks lean on emoji for flags and goods (🇩🇪, 🍷, …). In a
  browser they would be drawn by whatever emoji font the viewer has, and on
  Windows that means a country flag renders as two letters ("DE") and the
  England flag as a plain black flag. So every emoji listed below is replaced
  by an <img> of the matching Twemoji graphic (CC BY 4.0, jdecked/twemoji
  15.1.0), stored in img/L05/emoji/. The source stays readable: write the
  emoji itself in the .qmd.

  Raw HTML blocks are not touched by Pandoc filters — inside a raw <table>,
  use <img class="emo" src="img/L05/emoji/de.svg" alt="Germany"> directly.
--]]

local DIR = "img/L05/emoji/"

-- Longest sequence first: the England flag is a black flag plus tag
-- characters, and must be matched before anything shorter could be.
local EMOJI = {
  { "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "en", "England" },
  { "🇩🇪", "de", "Germany" },
  { "🇯🇵", "jp", "Japan" },
  { "🇺🇳", "un", "World" },
  { "🇵🇹", "pt", "Portugal" },
  { "🥨", "pretzel", "pretzels" },
  { "🍱", "bento", "bento" },
  { "🍷", "wine", "wine" },
  { "🧥", "cloth", "cloth" },
}

local function image(entry)
  return pandoc.Image({ pandoc.Str(entry[3]) }, DIR .. entry[2] .. ".svg", "",
                      pandoc.Attr("", { "emo" }, { alt = entry[3] }))
end

-- Split one string into Str and Image pieces.
local function split(s)
  local out = {}
  local rest = s
  while #rest > 0 do
    local best_i, best_e
    for _, e in ipairs(EMOJI) do
      local i = rest:find(e[1], 1, true)
      if i and (not best_i or i < best_i) then best_i, best_e = i, e end
    end
    if not best_i then
      table.insert(out, pandoc.Str(rest))
      break
    end
    if best_i > 1 then table.insert(out, pandoc.Str(rest:sub(1, best_i - 1))) end
    table.insert(out, image(best_e))
    rest = rest:sub(best_i + #best_e[1])
  end
  return out
end

function Str(el)
  for _, e in ipairs(EMOJI) do
    if el.text:find(e[1], 1, true) then return split(el.text) end
  end
end
