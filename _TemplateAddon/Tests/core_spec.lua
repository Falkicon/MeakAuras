-- _TemplateAddon/Tests/core_spec.lua
-- Example test file for the Template Addon

describe("TemplateAddon", function()
    local addon
    
    setup(function()
        -- Mock GetAddOnMetadata for TOC version
        _G.GetAddOnMetadata = function(name, field)
            if field == "Version" then return "1.0.0" end
        end
        
        -- Load the addon
        -- We use a simplified load pattern for tests
        _G.LibStub = {
            NewAddon = function(self, name, ...)
                local a = { name = name }
                _G[name] = a
                return a
            end
        }
        
        -- In a real scenario, you'd load Core.lua and other files
        -- addon = dofile("Core.lua")
    end)

    before_each(function()
        WoWAPI_ResetAll()
    end)

    it("should be initialized", function()
        -- Example test
        assert.is_not_nil(LibStub)
    end)

    it("should handle events", function()
        local testVar = false
        local frame = CreateFrame("Frame")
        frame:SetScript("OnEvent", function()
            testVar = true
        end)
        frame:RegisterEvent("TEST_EVENT")
        
        WoWAPI_FireEvent("TEST_EVENT")
        
        assert.is_true(testVar)
    end)
end)

