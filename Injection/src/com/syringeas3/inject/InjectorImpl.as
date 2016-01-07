package com.syringeas3.inject
{
    import flash.utils.getDefinitionByName;
    
    /**
     * This is the mechanism that performs Injection via Inversion Of Control.
     * It uses MetaData tags reaped from the Reflection Data of an object at runtime,
     * and decides how to provide dependencies for the requested Dependency Container.
     * 
     * @langversion 3.0
     * @playerversion Flash 9
     * @playerversion AIR 1.1
     * @productversion Flex 3
     * 
     * @author barcher
     * 
     */    
    public class InjectorImpl implements IInjector
    {
        private var _metadataTagName:String = "";
        
        /**
         * Constructor
         *  
         * @param metaTagName
         * a <code>String</code>, the MetaTag that this <code>MetaTagInjector</code> will operate on
         */        
        public function InjectorImpl(metaTagName:String)
        {
            _metadataTagName = metaTagName;
            super();
        }
        
        /**
         * Returns the MetaTag name being operated on.
         *  
         * @return 
         * a <code>String</code>
         */        
        public function get metadataTagName():String
        {
            return _metadataTagName;
        }
        		
        public function inoculate(syringeId:String, metadata:XML, patient:Object, metaTagArguments:XMLList = null, parameterData:Array = null):void
        {
            // syringe MUST already exist.
            const s:Syringe = Syringe.find( syringeId, false );
            
            if(s == null){
                throw new Error("Syringe with id: " + syringeId + " doesn't exist");
            }
            
            const pLen:int      = parameterData == null ? 0 : parameterData.length;
            var variant:String  = "";
            var Syndrome:Class      = null;
            var antidote:*      = null;
            var arg:XML         = null;
            
            if(pLen == 0)
            {
                for each(arg in metaTagArguments)
                {
                    // supports both 'name' or 'variant' for [Inject], i.e. [Inject (name="blah")] is synonymous with [Inject (variant="blah")]
                    if(arg != null && (arg.@key == "name" || arg.@key == "variant"))
                    {
                        variant = arg.@value;
                        //optimize
                        break;
                    }
                }
                const type:String = String(metadata.@type);
                
                if(type != "" && type != null)
                {
                    // check the class definition in the current ApplicationDomain (and qualified child ApplicationDomain instances)
                    Syndrome = getDefinitionByName(type) as Class;
                    
                    antidote = s.getAntidote(Syndrome, variant);
                    
                    if(antidote != null)
                        patient[String(metadata.@name)] = antidote;
                    else
                        trace("[WARN] Could Not treat Syndrome: " + Syndrome + ", with variant: " + variant + ", on target: " + patient + ", for variable: " + metadata.@name);
                }
            }
            else
            {
                var paramType:String;
                var variants:Array;
                
                for each(arg in metaTagArguments)
                {
                    // supports both 'mappings' and 'variants' as multimap recognition.
                    if(arg != null && (arg.@key == "mappings" || arg.@key == "variants"))
                    {
                        variants    = String(arg.@value).split(",");
                        //optimize
                        break;
                    }
                }
                
                const mLen:int        = variants.length;
                const fun:Function    = patient[String(metadata.@name)] as Function;
                
                if(fun != null)
                {
                    // Convert all of the parameters using direct injection
                    for(var i:int = 0; i < pLen; i++)
                    {
                        //use the mappings, and if none exist, use default
                        // NOTE: The ParameterData Array is Modified during this loop, and then passed
                        // into the function below
                        variant                = (i < mLen && variants[i] != "") ? variants[i] : Syringe.DEFAULT_VARIANT;
                        Syndrome                = parameterData[i];
                        
                        antidote            = s.getAntidote(Syndrome, variant)
                        parameterData[i]    = antidote;
                    }
                    
                    fun.apply(patient, parameterData);
                }
                else
                    trace("[WARN] Could not inoculate function: " + metadata.@name + " because it doesn't exist");
            }
        }
    }
}