package com.syringeas3.inject
{
    import flash.utils.Dictionary;
    
    /**
     * A Specialized Dispensary object for Antidote (Dependency) Instances that are to be treated as 'Singletons'
     *  
     * @author barcher
     */
    
    public class RareAntidoteDispensary extends Dispensary
    {
        // A Dictionary of Singleton Antidotes (Dependencies)
        // where we only manage a single instance. We use the term
        // 'rare' to indicate this while keeping to the theme.
        protected var _rareMedicineCabinet:Dictionary;
        
        /**
         * CTOR 
         */    
        public function RareAntidoteDispensary(syringeId:String)
        {
            _rareMedicineCabinet = new Dictionary();
            super(syringeId);
        }
        
        /**
         * This allows us to set a pre-constructed Object (Antidote) within Syringe and treat it as a Singleton ('rare').
         * This is helpful when we already have singleton objects constructed, that we later want to share
         * via Syringe.
         *  
         * @param RequestedClass
         * a <code>Class</code> that will be used when injecting this instance
         * 
         * @param rareAntidote
         * the <code>Object</code> instance to serve as a 'Singleton' from the perspective of this Dispensary
         * 
         * @param name
         * the <code>String</code> mapping name for this implementation instance.
         * 
         * @param overwrite
         * a <code>Boolean</code>, <code>true</code> to overwrite old instances.
         */    
        public function setRareAntidote( RequestedClass:Class, rareAntidote:Object, name:String=null, overwrite:Boolean = false ) : void
        {
            if( name == "" || name == null )
                name =  Syringe.DEFAULT_VARIANT;
            
            var medicineJar:MedicineJar = _medicineCabinet[name];
            
            if(medicineJar != null)
            {
                if(overwrite == false)
                    throw new Error("Cannot setInstance for requested class: " + RequestedClass + " for mapping " + name + ", it already exists. Specify 'overwrite=true' to bypass");
                
                // EARLY OUT if we are clearing an instance
                if(_inoculationEvent == null)
                {
                    createInoculationEvent( InoculationEvent.ANTIDOTE_VARIANT_CHANGE );
                }
                
                _inoculationEvent.oldVariant                 = name;
                _inoculationEvent.oldSyndrome         = medicineJar.baseFormula;
                _inoculationEvent.oldAntidoteFormula          = medicineJar.antidoteFormula;
                _inoculationEvent.oldRareAntidoteFormula          = medicineJar.antidoteInstance;
                _inoculationEvent.oldAntidoteIsRare   = medicineJar.antidoteInstance != null;
                
                if(rareAntidote == null)
                {
                    // clear the dependency item
                    // and the singleton object
                    delete _rareMedicineCabinet[name];
                    delete _medicineCabinet[name];
                    medicineJar = null;
                }
            }
            else if(rareAntidote != null)
            {
                medicineJar = new MedicineJar(syringeId);
                _medicineCabinet[name] = medicineJar;
            }
            
            // initialize the item with our new instance
            if(medicineJar != null)
            {
                if(_inoculationEvent == null)
                {
                    createInoculationEvent( InoculationEvent.ANTIDOTE_VARIANT_CHANGE );
                }
                
                _inoculationEvent.variant                 = name;
                _inoculationEvent.syndrome         = RequestedClass;
                _inoculationEvent.antidoteFormula          = null;
                _inoculationEvent.rareAntidoteFormula          = rareAntidote;
                _inoculationEvent.antidoteIsRare   = true;
                _rareMedicineCabinet[name] = rareAntidote;
                medicineJar.fillWithAntidote( RequestedClass, rareAntidote );
            }
            
            if(_inoculationEvent != null)
            {
                dispatchInoculationEvent(Syringe.find(syringeId));
            }
        }

        /**
         * @see Dispensary.removeAntidote
         *  
         * @param name
         * 
         */        
        override public function removeFormula( variant:String ):void
        {
            super.removeFormula( variant );
            
            delete _rareMedicineCabinet[variant];
        }
        
        /**
         * Evaluate a Dependency Rule for a Singleton
         *  
         * @param name
         * @param params
         * @return 
         * a <code>Object</code>, the Singleton instance, or <code>null</code> if it does not exist
         */    
        override public function evaluate( name:String=null, params:Array = null ):Object
        {
            if( name == "" || name == null )
                name =  Syringe.DEFAULT_VARIANT;
            
            const medicineJar:MedicineJar = _medicineCabinet[name];
            
            if( medicineJar == null )
                return null;
            
            if( _rareMedicineCabinet[name] == null )
            {
                var instance:Object;
                if(medicineJar.antidoteFormula != null)
                {
                    const InoculationDef:Class = medicineJar.antidoteFormula;
                    
                    if( params == null || params.length == 0 )
                    {
                        instance = new InoculationDef();
                    }
                    else if(params.length <= Syringe.MAX_CONSTRUCTOR_EVAL_PARAMS)
                    {
                        var evalWithParamsMethod:Function = this["evaluateWithParams_" + params.length];
                        
                        params.unshift(medicineJar);
                        
                        if( evalWithParamsMethod != null )
                            instance = evalWithParamsMethod.apply( null, params );
                    }
                    else
                    {
                        throw new Error("Cannot inject items with more than " + Syringe.MAX_CONSTRUCTOR_EVAL_PARAMS + " formal constructor parameters");
                    }
                    //create a new instance
                    _rareMedicineCabinet[name] = instance
                    
                    if( !( instance is ISyndromeSubject ) )
                    {
                        var s:Syringe = Syringe.find(syringeId, false);
                        if(s != null){
                            s.inject( instance );
                        }
                    }
                }
                else if(medicineJar.antidoteInstance != null)
                {
                    instance = medicineJar.antidoteInstance;
                    _rareMedicineCabinet[name] = instance;
                }
            }
            
            return _rareMedicineCabinet[name];
        }
        
        /**
         * @see DependencyRule#onDispose()
         */    
        override protected function onDispose() : void
        {
            trace( "[INFO][DependencyInjector::DependencyRule::SingletonDependencyRuleItem]::dispose()" );
            for ( var key:String in _rareMedicineCabinet )
            {
                var inst:Object = _rareMedicineCabinet[key];
                
                // do a property check so we don't have a sad trying to access
                // a non-existent property
                //            if( inst is IManagedObject )
                //                inst.dispose();
            }
            
            _rareMedicineCabinet      = null;
            
            super.onDispose();
        }
    }
}