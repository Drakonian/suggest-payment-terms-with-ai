codeunit 81801 "SPT Generate Proposal"
{
    trigger OnRun()
    begin
        GeneratePaymentTermProposal();
    end;

    procedure SetUserPrompt(InputUserPrompt: Text)
    begin
        UserPrompt := InputUserPrompt;
    end;

    procedure GetResult(var LocalTempPaymentTerms: Record "Payment Terms" temporary): Boolean
    begin
        if TempPaymentTerms.IsEmpty() then
            exit(false);

        LocalTempPaymentTerms.Copy(TempPaymentTerms, true);

        exit(true);
    end;

    local procedure GeneratePaymentTermProposal()
    var
        SuggestPaymentTermsSetup: Record "SPT PT AI Setup";
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        SuggestPaymentTerms: Codeunit "SPT Create Payment Terms";
    begin
        SuggestPaymentTermsSetup.Get();
        SuggestPaymentTermsSetup.TestField("Endpoint URL");
        SuggestPaymentTermsSetup.TestField("Model Name");

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions",
            SuggestPaymentTermsSetup."Endpoint URL", SuggestPaymentTermsSetup."Model Name", SuggestPaymentTermsSetup.GetSecret());

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"SPT Suggest Payment Terms");

        AOAIChatMessages.AddSystemMessage(GetSystemPrompt());
        AOAIChatMessages.AddUserMessage(UserPrompt);

        AOAIChatMessages.AddTool(SuggestPaymentTerms);
        AOAIChatMessages.SetToolInvokePreference("AOAI Tool Invoke Preference"::Automatic);
        AOAIChatMessages.SetToolChoice('auto');

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if not AOAIOperationResponse.IsSuccess() then
            Error(AOAIOperationResponse.GetError());

        SuggestPaymentTerms.GetPaymentTerms(TempPaymentTerms);
    end;

    local procedure GetSystemPrompt(): Text
    var
        SystemPrompt: TextBuilder;
    begin
        SystemPrompt.AppendLine('The user will describe Payment Terms. Your task is to prepare the payment terms with the described date formulas for Microsoft Dynamics 365 Business Central.');
        SystemPrompt.AppendLine();
        SystemPrompt.AppendLine('**Important:**');
        SystemPrompt.AppendLine('- If the user refers to a fixed day-of-month (e.g., "12th", "20th"), convert that into a valid Business Central date formula using the rule: For day n, use "-CM+(n-1)D". For instance, "12th" becomes "-CM+11D" and "20th" becomes "-CM+19D".');
        SystemPrompt.AppendLine('- If the user refers to a relative number of days (e.g., "20 days from invoice date"), use that number directly (e.g., "20D").');
        SystemPrompt.AppendLine('- Validate the computed date formulas with examples for invoice dates before and after the computed dates.');
        SystemPrompt.AppendLine('- Follow the valid Business Central syntax (e.g., 3D, -CM+7D, 1W, CW+1D).');
        SystemPrompt.AppendLine();
        SystemPrompt.AppendLine('Call the function "create_paymentterms" to create the payment terms.');
        exit(SystemPrompt.ToText());
    end;

    var
        TempPaymentTerms: Record "Payment Terms" temporary;
        UserPrompt: Text;
}