codeunit 81803 "SPT Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://vld-bc.com/blog/ai-prompt-pages-in-bc', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"SPT Suggest Payment Terms") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"SPT Suggest Payment Terms", Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Custom Billed", LearnMoreUrlTxt);
    end;
}