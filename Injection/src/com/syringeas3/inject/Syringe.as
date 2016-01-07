package com.syringeas3.inject
{
    import flash.events.EventDispatcher;
    import flash.system.ApplicationDomain;
    import flash.utils.Dictionary;
    import flash.utils.describeType;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
    import mx.utils.DescribeTypeCache;
    
    /**
     * This is a Dependency Injector, and should be accessed as a singleton. 
     * This is really the only Compile Singleton that should exist in the application. 
     * Other "Singleton" or "manager" type objects should be registered and accessed via the Syringe
     * rather than accessed via a Class Based Static function.
     * 
     * @author barcher
     */    
    public class Syringe extends EventDispatcher
    {
        //==============================================================================================================
        // Constants
        //==============================================================================================================
        

        /**
         * Default Metadata Tag name for our MetaDataInjectors 
         */        
        public static const TAGNAME_INJECT:String                                                                       = "Inject";
        /**
         * Synonymous with 'Inject' tag in behavior, used to help beginners learn where as Inject is more industry standard. Neither are discouraged! 
         */        
        public static const TAGNAME_TREAT:String                                                                        = "Treat";
        
        /**
         * Default Injection Mapping name 'default' 
         */        
        public static const DEFAULT_VARIANT:String                                                                      = "default";
        
        /**
         *  maximum number of Constructor Params that are supported for Injection.
         * In order to support more, you must add more functions below with the 'evaluateWithParams_' prefix, as done below.
         */        
        public static const MAX_CONSTRUCTOR_EVAL_PARAMS:int                                                             = 8;
        //==============================================================================================================
        // Private / Protected Members
        //==============================================================================================================
        // debugging members
        private var _debug:Boolean                                                                                      = false;
        private var _suppressWarnings:Boolean                                                                           = false;
        
        // helps to identify 'Syringe' instance if there are many. If find() is called with 'null' for the 'id' parameter
        // this value is set to 'default', and 'default' is used when calling 'find()' with 'null'.
        private var _id:String                                                                                          = null;
        // singleton instance of the dependency injector
        private static var _syringeInstancePool:Dictionary                                                              = null;
        
        // Excluded Metatags that should NOT be processed when performing Meta-Tag based injection
        private var _excludedTags:Dictionary                                                                            = null;
        private var _injectionHandlerList:Array                                                                         = [];
        // Set of registered metatag injectors, by TagName
        private var _functionInjectors:Dictionary                                                                       = null;
        private var _variableInjectors:Dictionary                                                                       = null;
        private var _classInjectors:Dictionary                                                                          = null;
        // Serves Antidote or AntidoteForumla for a Syndrome
        private var _dispensaries:Dictionary                                                                            = null;
        
        // Serves RareAntidote or RareAntidoteForumla for a Syndrome
        private var _rareAntidoteDispensaries:Dictionary                                                                = null;
        //==============================================================================================================
        // IManagedObject Properties
        //==============================================================================================================
        private var _isPrimed:Boolean                                                                                   = false;
        private var _isDisposed:Boolean                                                                                 = false;
        private var _isBeingDisposed:Boolean                                                                            = false;
        
        // debugging flag (global)
        public static var DEBUG:Boolean                                                                                 = true;
        
        /**
         * Syringe Instance Finder. Used to access a Syringe instance by id
         * There can be multiple Syringe objects that manage Antidotes for Syndromes.
         * 
         * <code>
         * var s1:Syringe = Syringe.find('deadlyDiseaseRemedies');
         * var s2:Syringe = Syrgine.find('childhoodDiseaseRemedies');
         *  
         * var Disease:Class;
         * 
         * var formula:Class = s1.getAntidote( Disease, "myVariant");
         * if(formula == null){
         *  // oh no, there's no AntidoteFormula (i.e. no Class or Instance to satisfy the Dependency)
         * }
         * else
         * {
         *   // great, there's an AntidoteFormula stored in 'formula'
         * }
         * </code>
         * @return 
         * a <code>Syringe</code> instance.
         */        
        public static function find(id:String = null, autoCreate:Boolean = true):Syringe
        {
            // create a singleton instance if not already created.
            if( _syringeInstancePool == null ){
                _syringeInstancePool = new Dictionary();
            }
            
            if(id == null){
                id = DEFAULT_VARIANT;
            }
            
            // syringe instance matching the input id.
            // if no id is passed, we use the 'default' syringe instance
            var s:Syringe = _syringeInstancePool[id];
            
            if(s == null && autoCreate)
            {
                s = new Syringe( SyringeCTORPermissionToken, id );
                s.debug = DEBUG;
                s.prime();
                _syringeInstancePool[id] = s;
            }
            return s;
        }
        
        private static function syringeOut(id:String, tag:String, msg:String):void
        {
            trace("[Syringe(" + id + ")]::" + tag + (msg != "" ? " - " + msg : msg ));
        }
        /**
         * Destroy a Syringe instance, and all of its Dependencies managed by its Dispensary. This will unmap all Dependencies and break links.
         * This allows us to rebuild the Syringe with all new Dependeny Implementations
         */        
        public static function destroy( id:String = null ):void
        {
            // destroy the singleton instance if created
            if( _syringeInstancePool != null )
            {
                var s:Syringe;
                if(id == null){
                    // dispose all Syringe Injectors stored by the instance pool
                    for(var key:Object in _syringeInstancePool)
                    {
                        s = _syringeInstancePool[key];
                        
                        if( s.isPrimed )
                            s.dispose();
                    }
                    
                    _syringeInstancePool = null;
                }
                else
                {
                    s = _syringeInstancePool[id];
                    
                    if(s != null){
                        s.dispose();
                        delete _syringeInstancePool[id];
                    }
                }
            }
        }
        
        /**
         * Singleton Constructor
         *  
         * @param se
         * a private object to disallow public construction of this object from anywhere other than
         * this class
         */        
        public function Syringe( seClass:Class, id:String )
        {
            // set the id
            _id = id;
            if( seClass != SyringeCTORPermissionToken )
                throw new Error( "Cannot Construct Dependency Injector" );
            
            addEventListener( InoculationEvent.ANTIDOTE_VARIANT_CHANGE, onDependencyMappingChanged );
        }
        
        /**
         * Read only access to the id. 
         * @return 
         * a <code>String</code>
         */
        public function get id():String
        {
            return _id;
        }
        
        
        /**
         * Register for changes in Dependency for specified mappings. 
         *  
         * @param o
         * a <code>Object</code> that will "observe" the event
         * 
         * @param mappings
         * an <code>Array</code> of mappings that we care about. This can be a subset of actually existing 
         * mappings, and we'll only observe the event if our mappings contain the mapping name that changed.
         * 
         * @param callback
         * an optional <code>Function</code> that the Dependency injector will call back rather than calling 'inject' on the observer
         */        
        public function handleInoculations( observer:Object, Syndrome:Class, variants:Array, callback:Function = null ) : void
        {
            var dLen:int = _injectionHandlerList.length;
            var listItem:Object;
            for(var i:int = 0; i < dLen; i++)
            {
                listItem = _injectionHandlerList[i];
                
                if(listItem.observer == observer)
                {
                    listItem.mappings = listItem.mappings.concat(variants);
                    return;
                }
            }
            
            _injectionHandlerList[_injectionHandlerList.length] = { observer:observer, dependency:Syndrome, mappings:variants, callback:callback };
        }
        
        /**
         * Stop listening for any dependency changes for this observer, regardless of which mappings it is listenging for changes on.
         *  
         * @param o
         * a <code>Object</code> observer that is currently listening for dependency changes.
         */        
        public function ignoreInoculations( o:Object ) : void
        {
            // TODO - improve this functionality
            var dLen:int = _injectionHandlerList.length;
            var listItem:Object;
            for(var i:int = 0; i < dLen; i++)
            {
                listItem = _injectionHandlerList[i];
                
                if(listItem.observer == o)
                {
                    _injectionHandlerList.splice(i, 1);
                    break;
                }
            }
        }
        
        /**
         * Suppress warnings ( Used for release mode )
         *  
         * @return 
         * a <code>Boolean</code>
         */        
        public function get suppressWarnings():Boolean
        {
            return _suppressWarnings;
        }
        
        public function set suppressWarnings( value:Boolean ):void
        {
            _suppressWarnings = value;
        }
        
        /**
         */        
        public function get debug():Boolean
        {
            return _debug && DEBUG;
        }
        public function set debug( value:Boolean ):void
        {
            _debug = value;
        }
        
        /**
         */        
        public function get isBeingDisposed():Boolean
        {
            return _isBeingDisposed;
        }
        
        /**
         */        
        public function get isPrimed():Boolean
        {
            return _isPrimed;
        }
        
        /**
         */        
        public function get isDisposed():Boolean
        {
            return _isDisposed;
        }
        
        /**
         * Allows the dependency injector to skip certain metadata tags during injection to speed up the process
         * as well as avoid unneccessary mapping operations 
         */
        public function excludeMetaTagDuringInjection( tagValue: String ) : void
        {
            _excludedTags[tagValue] = 1;
        }
        
        /**
         * Allows the dependency injector to include certain metatags during injection.
         *  
         * @param tagValue
         * a <code>String</code>, the name of the MetaTag to include, i.e. 'Inject' for an [Inject] metadata tag.
         */        
        public function includeMetaTagDuringInjection( tagValue: String ) : void
        {
            delete _excludedTags[tagValue];
        }
        
        /**
         */
        public function prime():void
        {
            if( !_isPrimed )
            {
                if(_debug){
                    syringeOut(_id, "prime()", "");
                }
                _isDisposed     = false;
                _isBeingDisposed = false;
                _isPrimed       = true;
                
                _dispensaries                                   = new Dictionary();
                _rareAntidoteDispensaries                          = new Dictionary();
                
                _functionInjectors                  = new Dictionary();
                _variableInjectors                  = new Dictionary();
                _classInjectors                     = new Dictionary();
                _excludedTags                                   = new Dictionary();
                
                // don't attempt to parse built in MetaTags, this slows down
                // injection heavily and unneccessarily
                _excludedTags["Event"]                          = 1;
                _excludedTags["Frame"]                          = 1;
                _excludedTags["Deprecated"]                     = 1;
                _excludedTags["Bindable"]                       = 1;
                _excludedTags["__go_to_ctor_definition_help"]   = 1;
                _excludedTags["__go_to_definition_help"]        = 1;
                _excludedTags["AccessibilityClass"]             = 1;
                _excludedTags["Alternative"]                    = 1;
                _excludedTags["Bindable"]                       = 1;
                _excludedTags["DefaultProperty"]                = 1;
                _excludedTags["Embed"]                          = 1;
                _excludedTags["Exclude"]                        = 1;
                _excludedTags["ExcludeClass"]                   = 1;
                _excludedTags["IconFile"]                       = 1;
                _excludedTags["Inspectable"]                    = 1;
                _excludedTags["Managed"]                        = 1;
                _excludedTags["RemoteClass"]                    = 1;
                _excludedTags["Style"]                          = 1;
                _excludedTags["SkinState"]                      = 1;
                
                
                // Create an Injector for the "Inject" tag, this is the basic dependency injection mechanic
                // for all "instance" based injections
                var injectTagInjector:InjectorImpl   = new InjectorImpl( TAGNAME_INJECT );
                addClassInjector( injectTagInjector );
                addVariableInjector( injectTagInjector );
                addFunctionInjector( injectTagInjector );
                
                // Supports '[Treat]' meta tags, which behaves the same as '[Inject]'
                injectTagInjector  = new InjectorImpl( TAGNAME_TREAT );
                addClassInjector( injectTagInjector );
                addVariableInjector( injectTagInjector );
                addFunctionInjector( injectTagInjector );
                
                onInit();
            }
        }
        
        /**
         */       
        public function dispose():void
        {
            if( _isPrimed && !_isBeingDisposed && !_isDisposed )
            {
                if(_debug){
                    syringeOut(_id, "dispose()", "");
                }
                _isBeingDisposed                = true;
                
                onDispose();
                
                // reset dependencies
                _dispensaries                   = new Dictionary();
                _rareAntidoteDispensaries       = new Dictionary();
                _variableInjectors              = new Dictionary();
                _classInjectors                 = new Dictionary();
                _functionInjectors              = new Dictionary();
                
                _isPrimed                       = false;
                _isDisposed                     = true;
            }
        }
        
        /**
         * Public API to Extend and Register Metatag Injectors that will act upon class instances
         * as their dependencies are being satisfied.
         * 
         * @param value
         * a <code>IMetadataTagInjector</code> instance
         */
        public function addVariableInjector( injector:IInjector ):void
        {
            if( injector == null )
                return;
            
            if(_debug){
                syringeOut(_id, "registerVariableLevelMetaTagInjector()", "injector: " + injector);
            }
            
            if( _variableInjectors[injector.metadataTagName] == null )
                _variableInjectors[injector.metadataTagName] = injector;
            
            else if( _suppressWarnings == false )
                trace( "[WARN]Cannot Register duplicate injector: " + injector.metadataTagName );
        }
        
        /**
         * Public API to Extend and Register Metatag Injectors that will act upon class instances
         * as their dependencies are being satisfied.
         * @param value
         */
        
        public function addClassInjector( injector:IInjector ):void
        {
            if( injector == null )
                return;
            
            if(_debug){
                syringeOut(_id, "registerClassLevelMetaTagInjector()", "injector: " + injector);
            }
            
            if( _classInjectors[injector.metadataTagName] == null )
                _classInjectors[injector.metadataTagName] = injector;
                
            else if( _suppressWarnings == false )
                trace( "[WARN]Cannot Register duplicate injector: " + injector.metadataTagName );
        }
        
        /**
         * Public API to Extend and Register Metatag Injectors that will act upon class instances
         * as their dependencies are being satisfied.
         * @param value
         */
        public function addFunctionInjector( injector:IInjector ):void
        {
            if( injector == null )
                return;
            
            if(_debug){
                syringeOut(_id, "registerFunctionLevelMetaTagInjector()", "injector: " + injector);
            }
            
            if( _functionInjectors[injector.metadataTagName] == null )
                _functionInjectors[injector.metadataTagName] = injector;
                
            else if( _suppressWarnings == false )
                trace( "[WARN]Cannot Register duplicate injector: " + injector.metadataTagName );
        }
        
        /**
         * Returns <code>true</code> if the specified <code>Klass</code> is mapped under the specified <code>name</code>
         *  
         * @param Syndrome
         * a <code>Class</code> or <code>Interface</code> that is specified as the 'Syndrome', which needs to be 'treated' (have its Dependency supplied).
         * 
         * @param name
         * a <code>String</code>, the mapping <code>name</code>
         * 
         * @return 
         * a <code>Boolean</code>, <code>true</code> if a mapping exists. If false, there is no 'cure' for the Syndrome, and if the Syndrome is a Class (not an interface)
         * It will be used as its own 'Antidote' (Dependency).
         */        
        public function canTreat( Syndrome:Class, variant:String=null ):Boolean
        {
            if( _isPrimed == true )
            {
                
                var className:String = flash.utils.getQualifiedClassName( Syndrome );
                
                if( variant == "" || variant == null )
                    variant = DEFAULT_VARIANT;
                
                // do an implicit conversion here, which will work
                // safely even if the className key doesn't exist in
                // dependencies
                var dispensary:Dispensary = _dispensaries[className];
                
                // if not a normal dependency, check the singleton map
                if( dispensary == null )
                {
                    dispensary = _rareAntidoteDispensaries[ className ];
                }
                
                // sanity null check prior to accessing the value
                const retVal:Boolean =  dispensary != null && dispensary.canTreat( variant );
                
                if(_debug){
                    syringeOut(_id, "canTreat()", "Syndrome: " + className + ", variant: " + variant + "? " + retVal);
                }
                
                return retVal;
            }
            else if( _suppressWarnings == false )
            {
                throw new Error( "Syringe is not primed" );
            }
            return false;
        }
        
        /**
         * Unmap a singleton instance against the specified mapping <code>name</code> if it exists.
         *  
         * @param Klass
         * a <code>Class</code> or <code>Interface</code>
         * 
         * @param name
         * a <code>String</code>, the mapping <code>name</code>.
         */        
        public function removeRareTreatment( Syndrome:Class, variant:String=null ):void
        {
            if( _isPrimed == true )
            {
                if( Syndrome != null )
                {
                    
                    if( variant == "" || variant == null )
                        variant = DEFAULT_VARIANT;
                    
                    var syndromeClassName:String = flash.utils.getQualifiedClassName( Syndrome );
                    
                    if(_debug){
                        syringeOut(_id, "removeRareTreatment()", "Syndrome: " + syndromeClassName + ", variant: " + variant);
                    }
                    
                    
                    // do an implicit conversion here, which will work
                    // safely even if the className key doesn't exist in
                    // dependencies
                    var dispensary:RareAntidoteDispensary = _rareAntidoteDispensaries[syndromeClassName];       
                    
                    // sanity check the rule exists
                    if( dispensary != null )
                    {
                        if( dispensary.canTreat( variant ) == false )
                        {
                            trace( new Error( "[WARN][Syringe] - Cannot remove Syndrome: " + Syndrome + " as singleton, a Syndrome with name [" + variant + "] doesn't exist!").getStackTrace() );
                        }
                        else
                        {
                            dispensary.removeFormula( variant );
                        }
                    }
                    else
                    {
                        trace( new Error( "[WARN][Syringe] - Cannot remove formula: " + syndromeClassName + ", their is no Dispensary that carries it" ).getStackTrace() );
                    }
                }
            }
            else if( _suppressWarnings == false )
            {
                trace( new Error( "[WARN][Syringe] - Syringe is not primed" ).getStackTrace() );
            }
        }
        
        /**
         * Maps a Class or Interface definition for dependency injection. If the 'KlassOrInterface' type is
         * requested via [Inject], an instance of <code>Injected</code> will be supplied by <code>Syringe</code>
         * if <code>Injected</code> is not supplied, then an instance of <code>KlassOrInterface</code> is returned, if
         * it is a <code>Class</code>. You cannot instantiate an <code>Interface</code>.
         *
         *
         * @param KlassOrInterface
         * a <code>Class</code>
         *
         * @param Injected
         * a <code>Class</code>
         *
         * @param name
         * a <code>String</code>, an optional name to request this dependency by.
         */
        public function addTreatment( Syndrome:Class, AntidoteFormula:Class, variant:String=null, replaceExistingAntidote:Boolean = false ):void
        {
            if( _isPrimed == true )
            {
                if( variant == "" || variant == null )
                    variant = DEFAULT_VARIANT;
                
                if( Syndrome != null )
                {
                    var className:String = flash.utils.getQualifiedClassName( Syndrome );
                    var rule:Dispensary;
                    
                    if( _dispensaries[className] == null )
                    {
                        rule = new Dispensary(_id);
                        //singleton map for this class
                        _dispensaries[className] = rule;
                    }
                    else
                    {
                        rule = _dispensaries[className];
                    }
                    rule.addFormula( Syndrome, AntidoteFormula, variant, replaceExistingAntidote );
                }
                else if( _suppressWarnings == false )
                {
                    throw new Error( "Cannot add antidote formula for unknown / null Syndrome" );
                }
            }
            else if( _suppressWarnings == false )
            {
                throw new Error( "Syringe is not primed" );
            }
        }
        
        /**
         * Set an instance that will act as a Singleton Object from this point on.
         *  
         * @param Klass
         * a <code>Class</code> that will be used to request this singleton instance. Indicates the interface / base class for which we want an
         * implentation.
         * 
         * @param singletonInstance
         * the Instance to use for a Singleton. It is highly recommended that <code>singletonInstance</code> either implement or extend the <code>Klass</code> instance
         * that is passed in.
         * 
         * @param name
         * a <code>String</code>, the unique mapping for this implementation, with regard to the interface we've provided.
         * 
         * @param overwrite
         * a <code>Boolean</code>, <code>true</code> to overwrite any existing instance under the specified group and mapping.
         */        
        public function addRareTreatment( Syndrome:Class, rareAntidote:Object, variant:String=null, replaceExistingRareAntidote:Boolean = false ) : void
        {
            if( _isPrimed == true )
            {
                if( variant == "" || variant == null )
                    variant = DEFAULT_VARIANT;
                
                syringeOut(_id,  "addRareTreatment()", "Syndrome: " + Syndrome + ", rareAntidote: " + rareAntidote + ", variant: " + variant + ", replaceExistingRareAntidote: " + replaceExistingRareAntidote );
                
                if( Syndrome != null )
                {
                    var className:String = flash.utils.getQualifiedClassName( Syndrome );
                    var rareAntidoteDispensary:RareAntidoteDispensary;
                    if( _rareAntidoteDispensaries[className] == null )
                    {
                        rareAntidoteDispensary = new RareAntidoteDispensary(_id);
                        //singleton map for this class
                        _rareAntidoteDispensaries[className] = rareAntidoteDispensary;
                    }
                    else
                    {
                        rareAntidoteDispensary = _rareAntidoteDispensaries[className];
                    }
                    
                    rareAntidoteDispensary.setRareAntidote( Syndrome, rareAntidote, variant, replaceExistingRareAntidote );
                }
                else if( _suppressWarnings == false )
                {
                    throw new Error( "Could not find Antidote for NULL Syndrome" );
                }
            }
            else
            {
                throw new Error( "Syringe is not primed" );
            }
        }
        
        /**
         * Set a <code>Class</code> instance to be served back as a Singleton for the specified
         * <code>SingletonClass</code>
         * 
         * @param Klass
         * a <code>Class</code> to serve up when requesting <code>SingletonClass</code>
         * 
         * @param SingletonClass
         * a <code>Class</code> that Dependent consumers will use to request the implementation
         * 
         * @param name
         * a <code>String</code> the mapping name.
         */
        public function setRareTreatmentOf( Syndrome:Class, RareAntidoteFormula:Class, variant:String=null, replaceOldFormula:Boolean = false ):void
        {
            if( _isPrimed == true )
            {
                if( variant == "" || variant == null )
                    variant = DEFAULT_VARIANT;
                
                if(_debug){
                    syringeOut(_id, "setRareTreatmentOf()", "Syndrome: " + Syndrome + ", RareAntidoteFormula: " + RareAntidoteFormula + ", variant: " + variant + ", replaceOldFormula: " + replaceOldFormula );
                }
                
                if( Syndrome != null )
                {
                    const syndromeName:String = flash.utils.getQualifiedClassName( Syndrome );
                    var dispensary:RareAntidoteDispensary;
                    if( _rareAntidoteDispensaries[syndromeName] == null )
                    {
                        dispensary = new RareAntidoteDispensary(_id);
                        //singleton map for this class
                        _rareAntidoteDispensaries[syndromeName] = dispensary;
                    }
                    else
                    {
                        dispensary = _rareAntidoteDispensaries[syndromeName];
                    }
                    
                    dispensary.addFormula( Syndrome, RareAntidoteFormula, variant, replaceOldFormula );
                }
                else if( _suppressWarnings == false )
                {
                    throw new Error( "Could not find dependency for NULL Class" );
                }
            }
            else
            {
                throw new Error( "Syringe is not primed" );
            }
        }
        
        /**
         * Set a singleton Class
         *  
         * @param Klass
         * @param name
         * @param overwrite
         */        
        public function setRareTreatment( Klass:Class, name:String="", overwrite:Boolean = false ):void
        {
            setRareTreatmentOf( Klass, null, name, overwrite );
        }
        
        
        /**
         * Returns a registered Dependancy Instance, based on the Class Requested, and the dependency name
         *  
         * @param Klass
         * the Interface or Class that marks the desired dependency ( registered with this <code>Syringe</code> instance )
         * 
         * @param name
         * the Dependency Name as registered.
         * 
         * @param params
         * any Evaluation parameters
         * 
         * @param preferRareAntidote
         * in the case where we have the same interface mapped as both a singleton and as a non-singleton, we can use this flag to prefer the singleton
         * or prefer the non-singleton dependency mappings if set <code>false</code>
         * 
         * @return 
         * any object type, based on the Dependency requested.
         */        
        public function getAntidote( Syndrome:Class, name:String="", params:Array=null, createIfNotExists:Boolean = true, preferRareAntidote:Boolean = true ):*
        {
            var instance:Object = null;
            
            if( _isPrimed == true )
            {
                if( Syndrome != null )
                {
                    if( name == "" || name == null )
                        name = Syringe.DEFAULT_VARIANT;
                    
                    const syndromeName:String = getQualifiedClassName( Syndrome );
                    var dispensary:Dispensary;
                    
                    // check if there are two mapping types
                    
                    if( _dispensaries[syndromeName] != null && _rareAntidoteDispensaries [syndromeName] != null)
                    {
                        if(preferRareAntidote == true)
                        {
                            dispensary = _rareAntidoteDispensaries[ syndromeName];
                            instance = dispensary.evaluate( name, params );
                        }
                        else
                        {
                            dispensary = _dispensaries[syndromeName];
                            instance = dispensary.evaluate( name, params );
                        }
                    }
                    else if( _dispensaries[syndromeName] != null || _rareAntidoteDispensaries[syndromeName] != null )
                    {
                        if( _dispensaries[syndromeName] != null )
                        {
                            dispensary = _dispensaries[syndromeName];
                            instance = dispensary.evaluate( name, params );
                            
                            return instance;
                        }
                        else if(_rareAntidoteDispensaries[syndromeName] != null)
                        {
                            dispensary = _rareAntidoteDispensaries[ syndromeName];
                            instance = dispensary.evaluate( name, params );
                        }
                    }
                    else if( createIfNotExists == true )
                    {
                        //just create one
                        instance = new Syndrome();
                    }
                    else
                    {
                        trace( new Error( "[ERROR][Syringe] - No Dependency exists for class: " + Syndrome + ", and createIfNotExists was set false" ).getStackTrace() );
                    }
                }
                else if( _suppressWarnings == false )
                {
                    trace( new Error( "[ERROR][Syringe] - Could not find treatment for NULL syndrome" ).getStackTrace() );
                }
            }
            else if( _suppressWarnings == false )
            {
                trace( new Error( "[ERROR][Syringe] - Syringe is not primed" ).getStackTrace() );
            }
            
            return instance;
        }
        
        /**
         * Returns the <code>Class</code> that implements / extends the base <code>Class</code> or <code>Interface</code> specified by 
         * <code>Klass</code>.
         *  
         * @param Klass
         * a <code>Class</code> or <code>Interface</code>
         * 
         * @param name
         * a <code>String</code>, the mapping  <code>name</code>
         * 
         * @return 
         * a <code>Object</code>, usually of type <code>Class</code> that represents the implementation for the interface or base <code>Klass</code>.
         */        
        public function getTreatmentObject( Syndrome:Class, name:String=null ) : Object
        {
            if( _isPrimed == true )
            {
                if( Syndrome != null )
                {
                    if( name == "" || name == null )
                        name =  Syringe.DEFAULT_VARIANT;;
                    
                    var syndromeName:String    = flash.utils.getQualifiedClassName( Syndrome );
                    var dispensary:Dispensary  = null;
                    var impl:Class          = dispensary.getImplementation( name );
                    
                    if( _dispensaries[syndromeName] != null )
                    {
                        dispensary    = _dispensaries[syndromeName];
                        impl    = dispensary.getImplementation( name );
                        return impl;
                    }
                    else if(_rareAntidoteDispensaries[syndromeName] != null)
                    {
                        dispensary    = _rareAntidoteDispensaries[syndromeName];
                        impl    = dispensary.getImplementation( name );
                    }
                    else if( _suppressWarnings == false )
                    {
                        trace( new Error( "[ERROR][Syringe] - Could not find treatement for syndrome: " + syndromeName ).getStackTrace() );
                    }
                }
                else if( _suppressWarnings == false )
                {
                    trace( new Error( "[ERROR][Syringe] - Could not find treatement for NULL syndrome" ).getStackTrace() );
                }
            }
            else if( _suppressWarnings == false )
            {
                trace( new Error( "[ERROR][Syringe] - Syringe is not primed" ).getStackTrace() );
            }
            
            return null;
        }
        
        /**
         * Synonymous with 'inject', however only accepts
         * Type ISyndromeSubject instances.
         *  
         * @param syndromeSubject
         * a <code>ISyndromeSubject</code> instance.
         */        
        public function treat( syndromeSubject:ISyndromeSubject ) : void
        {
            // use 'treat' as a synonym for 'inject'
            inject(syndromeSubject);
        }
        /**
         * Inject an object, which will use describe type cache
         * to inform the injection points ( if any exist ).
         * 
         * It is not cheap for the first call, however subsequent calls
         * with the same type are notably faster.
         * 
         * processing of the injection also depends on the number of items
         * to be injected.
         *  
         * @param target
         * an item with dependencies that need to be injected.
         */        
        public function inject( target:Object ):void
        {
            if( _isPrimed )
            {
                if( _debug )
                    syringeOut(_id,  "inject()", "" + target );
                
                var type:XML;
                
                // if DescribeTypeCache is available, use it. If the FlashPlayer or SDK didn't supply it
                // or its not available in the current flash player, fallback to flash.utils.describeType (slower).
                
                if(ApplicationDomain.currentDomain.hasDefinition('mx.utils.DescribeTypeCache')){
                    type = DescribeTypeCache.describeType( target ).typeDescription;
                }
                else
                {
                    if (target is String)
                    {
                        try
                        {
                            target = getDefinitionByName(target as String);
                            
                            if( _debug )
                                trace( "\t", "target reset because input value was 'string' that referenced an FQCN: " + target );
                        }
                        catch (error:ReferenceError)
                        {
                            // The o parameter doesn't refer to an ActionScript 
                            // definition, it's just a string value.
                        }
                    }
                    type = flash.utils.describeType(target);
                }
                
                //inject class level properties
                processClassMetadata( type.metadata, target );
                processVariablesMetadata( type.variable, target );
                processVariablesMetadata( type.accessor, target );
                processFunctionsMetadata( type.method , target );
            }
            else
            {
                trace( new Error( "[ERROR][Syringe] - not initialized!" ).getStackTrace() );
            }
        }
        
        /**
         * Lifecycle method for Initialization 
         */        
        private function onInit():void
        {
            if(_debug){
                syringeOut(_id, "onInit()", "");
            }
        }
        
        /**
         * Lifecycle Method for Shutdown 
         */        
        private function onDispose():void
        {
            
        }
        
        
        /**
         * Invoked when a dependency mapping changes, or is added or removed.
         *  
         * @param e
         * a <code>DependencyEvent</code>
         */
        private function onDependencyMappingChanged( e : InoculationEvent ) : void 
        {
            if(_debug){
                syringeOut(_id, "onDependencyMappingChanged()", e.toString());
            }
            
            const dLen:int = _injectionHandlerList.length;
            
            if(dLen > 0)
            {
                for(var i:int = 0; i < dLen; i++)
                {
                    const depObj:Object = _injectionHandlerList[i];
                    const mappings:Array = depObj.mappings as Array;
                    const mLen:int = mappings.length;
                    const observer:Object = depObj.observer;
                    const syndrome:Class = depObj.dependency;
                    const callback:Function = depObj.callback;
                    
                    if(observer != null && (syndrome == e.oldSyndrome || syndrome == e.syndrome))
                    {
                        for(var j:int = 0; j < mLen; ++j)
                        {
                            if(mappings[j] == e.variant || mappings[j] == e.oldVariant)
                            {
                                // inject
                                if(callback == null)
                                {
                                    if(observer is ISyndromeSubject)
                                    {
                                        if(_debug){
                                            syringeOut(_id, "\t", "auto injecting ISyndromeSubjectInstance: " + String(observer));
                                        }
                                        treat(observer as ISyndromeSubject);
                                    }
                                }
                                // invoke the callback with the dependency instance
                                else
                                {
                                    if(_debug){
                                        syringeOut(_id, "\t", "invoking callback");
                                    }
                                    callback( getAntidote( syndrome, mappings[j], null, false, true ) );
                                }
                            }
                        }
                    }
                }
            }
        }
        
        /**
         * Process Function Level Metadata for the MetatagInjectors
         *  
         * @param functions
         * the <code>XMLList</code> of function definitions from the reflection table.
         * 
         * @param target
         * a <code>Object</code> target
         */        
        private function processFunctionsMetadata( functions:XMLList, target:Object ):void
        {
            for each( var func:XML in functions )
                processMetaTagsForFunction( func, target );
        }
        
        /**
         * Process Variable Level metadata tags for MetatagInjectors
         *  
         * @param variables
         * @param target
         */        
        private function processVariablesMetadata( variables:XMLList, target:Object ):void
        {
            for each( var variable:XML in variables )
                processMetaTagsForVariable( variable, target );
        }
        
        
        /**
         * Process Classes Meta Data Tags
         * @param metadata
         * @param target
         */
        private function processClassMetadata( metadata:XMLList, target:Object ):void
        {
            //find class meta
            var tagName:String;
            for each( var metaItem:XML in metadata )
            {
                tagName = metaItem.@name;
                
                if( _excludedTags[tagName] == true )
                    continue;
                
                const p:IInjector = _classInjectors[tagName];
                
                if( p != null )
                    p.inoculate( this.id, metaItem, target, null );
            }
        }
        
        /**
         * Parse Meta Tags for a variable
         * <br/>Sample XML<br/>
         * @param variable
         * a <code>XML</code> describing the accissible variable for this target.
         *
         * @param target
         * the <code>Object</code> that is being injected.
         */
        private function processMetaTagsForFunction( fun:XML, target:Object ):void
        {
            var tagName:String;

            // build the parameter array (if we can)
            const parameters:Array = [];
            var Type:Object = null;
            var paramIsOptional:Boolean = false;
            // process /build injected parameters for this method
            for each(var param:XML in fun.parameter )
            {
                paramIsOptional = Boolean(param.@optional);
                
                var typeName:String = String(param.@type);
                
                // use 'Object' in the * case, so all values will still
                // be accepted
                if(typeName == "*"){
                    typeName = "Object";
                }
                Type = getDefinitionByName( typeName );
                
                // build a list of 'param types' to inject
                parameters[parameters.length] = Type;
            }
            for each( var metadata:XML in fun.metadata )
            {
                tagName = metadata.@name;
                // skip excluded metadata tags
                if( _excludedTags[tagName] == true )
                    continue;
                
                processFunctionMetaTag( metadata, fun, target, parameters );
            }
        }
        
        /**
         * Process meta tag for a specified function reflection data XML.
         *  
         * @param metadata
         * @param fun
         * @param target
         * @param parameters
         */        
        private function processFunctionMetaTag( metadata:XML, fun:XML, target:Object, parameters:Array ):void
        {
            const funName:String = String( fun.@name );
            const tagName:String = metadata.@name;
            const p:IInjector = _functionInjectors[tagName];
            
            if( p != null )
            {
                p.inoculate(this.id, fun, target, metadata.arg, parameters );
            }
        }
        
        /**
         * Parse Meta Tags for a variable
         *
         * @param variable
         * a <code>XML</code> describing the accissible variable for this target.
         *
         * @param target
         * the <code>Object</code> that is being injected.
         */
        private function processMetaTagsForVariable( variable:XML, target:Object ):void
        {
            var tagName:String;
            
            for each( var metadata:XML in variable.metadata )
            {
                tagName = metadata.@name;
                // skip excluded metadata tags
                if( _excludedTags[tagName] == true )
                    continue;
                
                processVariableMetaTag( metadata, variable, target );
            }
        }
        
        /**
         * Process a Variable Metadata Tag
         *  
         * @param metadata
         * @param variable
         * @param target
         */        
        private function processVariableMetaTag( metadata:XML, variable:XML, target:Object ):void
        {
            const varName:String = String( variable.@name );
            const tagName:String = metadata.@name;
            const p:IInjector = _variableInjectors[tagName];
            
            if( p != null )
                p.inoculate(this.id, variable, target, metadata.arg );
        }
    }
}


/**
 * Insures that Syringe is the only class that can construct instances of Syringe.
 *  
 * @author barcher
 */
class SyringeCTORPermissionToken{}
//==============================================================================================================
// A Single Item within a Dependency Map. This item knows the Interface/Base Class, and a Single Implementation, 
// mapped via a name within the Dependency Map
//==============================================================================================================

