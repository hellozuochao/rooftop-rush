local Modal = {}
local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
function Modal.Get()
    return pg:GetAttribute("ActivePanel") or ""
end
function Modal.Open(name)
    pg:SetAttribute("ActivePanel", name)
end
function Modal.Close(name)
    if Modal.Get() == name then
        Modal.Open("")
    end
end
function Modal.Bind(name, frame, onOpen)
    local function refresh()
        frame.Visible = Modal.Get() == name
        if frame.Visible and onOpen then
            onOpen()
        end
    end
    pg:GetAttributeChangedSignal("ActivePanel"):Connect(refresh)
    refresh()
end
return Modal
