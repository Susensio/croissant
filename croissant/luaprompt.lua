local Class  = require "hump.class"
local colors = require "term.colors"
local Prompt = require "sirocco.prompt"

local Lexer = require "croissant.lexer"

local LuaPrompt
LuaPrompt = Class {

    __includes = Prompt,

    init = function(self, options)
        options = options or {}

        Prompt.init(self, {
            prompt = options.prompt or "> ", -- "🥐  ",
            validator = LuaPrompt.validateLua,
            required = false
        })

        self.lexer = Lexer()
        -- Buffer whithout colors
        self.highlightedBuffer = ""

        self.tokenColors = options.colors or {
            constant   = colors.bright .. colors.yellow,
            string     = colors.green,
            comment    = colors.bright .. colors.black,
            number     = colors.yellow,
            operator   = colors.yellow,
            keywords   = colors.bright .. colors.magenta,
            identifier = colors.blue,
        }
    end

}

function LuaPrompt:registerKeybinding()
    Prompt.registerKeybinding(self)

    local promptBackspace = self.keybinding["\127"]
    self.keybinding["\127"] = function()
        promptBackspace()

        self:renderHighlighted()

        self.message = nil
    end
end

function LuaPrompt:renderHighlighted()
    self.highlightedBuffer = ""
    local lastIndex
    for kind, text, index in self.lexer:tokenize(self.buffer) do
        self.highlightedBuffer = self.highlightedBuffer
            .. (self.tokenColors[kind] or "")
            .. text
            .. colors.reset

        lastIndex = index
    end

    self.highlightedBuffer = self.highlightedBuffer
        .. self.buffer:sub(lastIndex)
end

function LuaPrompt:complete()
end

function LuaPrompt.validateLua(code)
    local fn, err = load("return " .. code, "croissant")
    if not fn then
        fn, err = load(code, "croissant")
    end

    return fn, (err and colors.red .. err .. colors.reset)
end

function LuaPrompt:processInput(input)
    Prompt.processInput(self, input)

    self:renderHighlighted()
end

function LuaPrompt:render()
    -- Swap with highlighted buffer for render
    local buffer = self.buffer
    self.buffer = self.highlightedBuffer

    Prompt.render(self)

    -- Restore buffer
    self.buffer = buffer
end

function LuaPrompt:processedResult()
    return self.buffer
end

return LuaPrompt