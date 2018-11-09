using Modules = Microsoft.PowerShell.CrossCompatibility.Data.Modules;

namespace Microsoft.PowerShell.CrossCompatibility.Query
{
    public class FunctionData : CommandData
    {
        public FunctionData(Modules.FunctionData functionData, string name)
            : base(functionData, name)
        {
        }

        public override bool IsCmdletBinding => ((Modules.FunctionData)_commandData).CmdletBinding;
    }
}