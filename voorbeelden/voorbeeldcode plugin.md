




using Rechtspraak.Toezicht.Processing.Cbm.Instellingsverzoeken;

namespace Rechtspraak.Toezicht.Processing.Cbm.Instellingsverzoeken
{
    public class CbmInstellingsverzoekDerdePlugin : PluginEventHandler<CbmInstellingsverzoekderde>, IPlugin
    {
        protected override void PreValidateUpdate(CbmInstellingsverzoekderde record, IPluginEventHandlerContext context)
        {
            context.Resolve<CbmInstellingsverzoekDerdeService>()
                .PrepareUpdate(record);
        }

        protected override void PreValidateCreate(CbmInstellingsverzoekderde record, IPluginEventHandlerContext context)
        {
            context.Resolve<CbmInstellingsverzoekDerdeService>()
                .PrepareCreate(record);
        }
    }
}


data:
onderdeel : Cbm 
library : Instellingsverzoeken

triggers: PreValidateUpdate, PrevalidateCreate

service: CbmInstellingsverzoekDerdeService
functie: Prepare
