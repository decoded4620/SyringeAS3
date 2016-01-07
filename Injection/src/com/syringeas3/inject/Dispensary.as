package com.syringeas3.inject
{
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    /**
     * A Single Dependency Rule. This can contain many dependencies for a single Requested Class or Interface. This is gated on the 
     * name parameter, when constructing this rule, or when manually adding more rule items
     *  
     * @author barcher
     */
    public class Dispensary
    {
        /**
         * The Default Dependency Name 
         */    
        protected var _medicineCabinet:Dictionary                                                                       = null;
        protected static var _inoculationEvent:InoculationEvent                                                     = null;
        protected static var _preventInoculationEventDispatch:Boolean                                                   = false;
        
        //==============================================================================================================
        // IManagedObject Properties
        //==============================================================================================================
        private var _isInitialized:Boolean                                                                              = false;
        private var _isDisposed:Boolean                                                                                 = false;
        private var _isShuttingDown:Boolean                                                                             = false;
        
        //==============================================================================================================
        // IDebuggable Properties
        //==============================================================================================================
        private var _debug:Boolean                                                                                      = false;
        private var _syringeId:String                                                                                   = null;
        /**
         * Constructor
         *  
         * @param WhenClassIsRequested
         * @param InjectThisClass
         * @param name
         */    
        public function Dispensary(syringeId:String)
        {
            _syringeId = syringeId;
            _medicineCabinet = new Dictionary();
        }
        
        /**
         * Id of the 'Syringe' instance that will be supplied AntidoteFormula instances by this Dispensary object
         *  
         * @return 
         * a <code>String</code>
         */        
        public function get syringeId():String
        {
            return _syringeId;
        }
        
        /**
         * Create the next dependency event to dispatch. This happens when dependencies are about to change
         *  
         * @param eventType
         * a <code>String</code>, see DependencyEvent static constants for more information.
         * 
         * @see com.wgt.core.inject.DependencyEvent
         */    
        internal static function createInoculationEvent( eventType : String ) : void
        {
            if(_inoculationEvent == null)
                _inoculationEvent = new InoculationEvent( eventType );
            else
                throw new Error("InoculationEvent already in progress, please dispatch before creating another!");
        }
        
        /**
         * Dispatch the InoculationEvent. This will clear the current event, so you must call <code>createNextDependencyEvent</code> prior
         * to calling this method again.
         */    
        internal static function dispatchInoculationEvent(s:Syringe) : void
        {
            if(_inoculationEvent != null)
            {
                s.dispatchEvent( _inoculationEvent );
                _inoculationEvent = null;
                _preventInoculationEventDispatch = false;
            }
        }
        //==============================================================================================================
        // IDebuggable Methods
        //==============================================================================================================
        /**
         * @see com.wgt.util.IDebuggable#debug 
         */        
        public function get debug():Boolean
        {
            return _debug;
        }
        public function set debug( value:Boolean ):void
        {
            _debug = value;
        }
        
        //==============================================================================================================
        // IManagedObject Methods
        //==============================================================================================================
        
        /**
         * @see com.wgt.core.IManagedObject#isShuttingDown
         */     
        public function get isShuttingDown():Boolean
        {
            return _isShuttingDown;
        }
        
        /**
         * @see com.wgt.core.IManagedObject#isInitialized
         */        
        public function get isInitialized():Boolean
        {
            return _isInitialized;
        }
        
        /**
         * @see com.wgt.core.IManagedObject#isDisposed
         */       
        public function get isDisposed():Boolean
        {
            return _isDisposed;
        }
        
        /**
         * @see com.wgt.core.IManagedObject#initialize() 
         */        
        public function initialize():void
        {
            if( !_isInitialized && !_isDisposed )
            {
                _isInitialized = true;
                onInit();
            }
        }
        
        /**
         * @see com.wgt.core.IManagedObject#dispose() 
         */    
        public function dispose():void
        {
            if( !_isInitialized && !_isDisposed && !_isShuttingDown )
            {
                if( _debug )
                    trace( "[DEBUG][Syringe::DependencyRule]::dispose()" );
                
                _isInitialized = false;
                _isShuttingDown = true;
                for ( var key:String in _medicineCabinet )
                {
                    var item:MedicineJar = _medicineCabinet[key];
                    
                    item.dispose();
                }
                
                _medicineCabinet = null;
                _isDisposed = true;
            }
        }
        
        
        /**
         * Lifecycle method for Initialization 
         */        
        protected function onInit():void
        {
            
        }
        
        /**
         * Lifecycle Method for Shutdown 
         */        
        protected function onDispose():void
        {
            
        }
        
        /**
         * Returns a Class for the named mapping if it is registerered.
         *  
         * @param name
         * a <code>String</code>
         * 
         * @return 
         * a <code>Class</code> object, or <code>null</code> if no mapping exists for the specified <code>name</code>
         */    
        public function getImplementation( name:String ):Class
        {
            if( name == "" || name == null )
                name = Syringe.DEFAULT_VARIANT;
            
            var ruleItem:MedicineJar =  _medicineCabinet[name];
            
            if( ruleItem != null )
            {
                return ruleItem.antidoteFormula;
            }
            
            return null;
        }
        
        /**
         * Returns a mapping for the specified mapping name
         *  
         * @param variant
         * a <code>String</code>
         */    
        public function removeFormula( variant:String ):void
        {
            if( variant == "" || variant == null )
                variant =  Syringe.DEFAULT_VARIANT;
            
            
            var depMapItem:MedicineJar = _medicineCabinet[variant];
            
            if( depMapItem != null)
            {
                if(_inoculationEvent == null)
                    createInoculationEvent( InoculationEvent.ANTIDOTE_VARIANT_CHANGE );
                
                _inoculationEvent.changeType                   = InoculationEvent.CHANGE_TYPE_REMOVE;
                _inoculationEvent.oldVariant                   = variant;
                _inoculationEvent.oldSyndrome           = depMapItem.baseFormula;
                _inoculationEvent.oldAntidoteFormula            = depMapItem.antidoteFormula;
                _inoculationEvent.oldRareAntidoteFormula            = depMapItem.antidoteInstance;
                
                if(flash.utils.getQualifiedClassName(this).indexOf("SingletonDependencyMap") != -1)
                    _inoculationEvent.antidoteIsRare = true;
                else
                    _inoculationEvent.antidoteIsRare = false;
            }
            
            if( _medicineCabinet[variant] != null )
                delete _medicineCabinet[variant];
            
            if(!_preventInoculationEventDispatch )
                dispatchInoculationEvent(Syringe.find(syringeId));
        }
        
        /**
         * Add a dependency mapping to the Injector Dependency Map
         *  
         * @param WhenClassIsRequested
         * a <code>Class</code> or <code>Interface</code> that defines the shared "API" for implementations
         * 
         * @param InjectThisClass
         * the <code>instance</code> or <code>implementation</code> of the specified "API". NOTE: This instance should implement or extend
         * the type that is passed in for <code>WhenClassIsRequested</code>
         * 
         * @param variant
         * a <code>String</code>, the variant name for the Formula (i.e. which Dependency Does it supply).
         * 
         * @param overwrite
         * a <code>Boolean</code> true to overwrite any previously mapped objects to this mapping name.
         */    
        public function addFormula( WhenClassIsRequested:Class, AntidoteFormula:Class, variant:String=null, overwrite:Boolean = false ):void
        {
            if( variant == "" || variant == null )
                variant =  Syringe.DEFAULT_VARIANT;
            
            var medicineJar:MedicineJar;
            
            if( _medicineCabinet[variant] == null || overwrite == true )
            {
                if( _medicineCabinet[variant] != null )
                {
                    medicineJar = _medicineCabinet[variant];
                    
                    var oldBlock:Boolean = _preventInoculationEventDispatch;
                    _preventInoculationEventDispatch = true;
                    
                    removeFormula( variant );
                    
                    // keep the setting as it was prior
                    _preventInoculationEventDispatch = oldBlock;
                    
                    // if removal occurs, it means there will now be a new dependency event.
                    // its type will be 'change' in this case, since we are removing an old, and replacing
                    // it with a new. Even if the new is 'null', we'll still consider it a change.
                    // otherwise, its a plain 'add'.
                    _inoculationEvent.changeType                   = InoculationEvent.CHANGE_TYPE_CHANGE;
                }
                
                medicineJar = new MedicineJar(syringeId);
                medicineJar.fillWithFormula( WhenClassIsRequested, AntidoteFormula );
                //set an initial name
                _medicineCabinet[variant] = medicineJar;
                
                // if removal didn't occur, this will be true so the event type gets created and its
                // changetype gets set to 'add'
                if(_inoculationEvent == null)
                {
                    createInoculationEvent( InoculationEvent.ANTIDOTE_VARIANT_CHANGE );
                    _inoculationEvent.changeType                   = InoculationEvent.CHANGE_TYPE_ADD;
                }
                _inoculationEvent.variant                   = variant;
                _inoculationEvent.syndrome           = WhenClassIsRequested;
                _inoculationEvent.antidoteFormula            = AntidoteFormula;
                _inoculationEvent.rareAntidoteFormula            = null;
                _inoculationEvent.antidoteIsRare     = false;
                
                dispatchInoculationEvent(Syringe.find(_syringeId));
            }
            else
            {
                throw new Error( "Syringe::addRuleItemFor() - Cannot Add Duplicate name for a Class Mapping!" );
            }
        }
        
        /**
         * Returns <code>true</code> if there is a mapping registered with the specified <code>name</code>
         *  
         * @param name
         * a <code>String</code>, the mapping name to check.
         * 
         * @return 
         * a <code>Boolean</code>, <code>true</code> if there exists a mapping with specified <code>name</code>.
         */    
        public function canTreat( name:String ):Boolean
        {
            if( name == "" || name == null )
                name =  Syringe.DEFAULT_VARIANT;
            
            return _medicineCabinet[name] != null;
        }
        
        /**
         * Evaluates the dependency, given the specified name.
         *  
         * @param name
         * a <code>String</code> matching the original Mapping that was setup when configuring the injector.
         * 
         * @param params
         * a <code>Array</code> of parameters to pass into the Constructor
         * 
         * @return 
         * a <code>Object</code> created from the result of evaluation, or <code>null</code>
         */    
        public function evaluate( name:String=null, params:Array = null ):Object
        {
            if( name == "" || name == null )
                name = Syringe.DEFAULT_VARIANT;
            
            var item:MedicineJar = _medicineCabinet[name];
            
            if( item == null )
                return null;
            
            var instanceObject:Object;
            
            var pLen:int = params==null ? 0 : params.length;
            
            if( pLen > 0 && pLen <= Syringe.MAX_CONSTRUCTOR_EVAL_PARAMS )
            {
                params.unshift(item);
                instanceObject = this["evaluateWithParams_" + pLen].apply( null, params );
            }
            //create a new instance and inject
            if( instanceObject == null )
            {
                if(item.antidoteFormula != null)
                    instanceObject = new item.antidoteFormula();
                else if(item.antidoteInstance != null)
                    instanceObject = item.antidoteInstance();
            }
            if( !( instanceObject is ISyndromeSubject ) )
                Syringe.find(syringeId).inject( instanceObject );
            
            return instanceObject;
        }
        
        //==============================================================================================================
        // Eval Methods for Constructors with Parameters. 
        // Supports up to MAX_CONSTRUCTOR_EVAL_PARAMS in Syringe
        //==============================================================================================================
        
        public function evaluateWithParams_1( item:MedicineJar, param:* ) : Object
        {
            return new item.antidoteFormula( param );
        }
        
        public function evaluateWithParams_2( item:MedicineJar, param1:*, param2:* ) : Object
        {
            return new item.antidoteFormula( param1, param2 );
        }
        
        public function evaluateWithParams_3( item:MedicineJar, param1:*, param2:*, param3:* ) : Object
        {
            return new item.antidoteFormula( param1, param2, param3 );
        }
        
        public function evaluateWithParams_4( item:MedicineJar, param1:*, param2:*, param3:*, param4:* ) : Object
        {
            return new item.antidoteFormula( param1, param2, param3, param4 );
        }
        
        public function evaluateWithParams_5( item:MedicineJar, param1:*, param2:*, param3:*, param4:*, param5:* ) : Object
        {
            return new item.antidoteFormula( param1, param2, param3, param4, param5 );
        }
        
        public function evaluateWithParams_6( item:MedicineJar, param1:*, param2:*, param3:*, param4:*, param5:*, param6:* ) : Object
        {
            return new item.antidoteFormula( param1, param2, param3, param4, param5, param6 );
        }
        
        public function evaluateWithParams_7( item:MedicineJar, param1:*, param2:*, param3:*, param4:*, param5:*, param6:*, param7:* ) : Object
        {
            return new item.antidoteFormula( param1, param2, param3, param4, param5, param6, param7 );
        }
        
        public function evaluateWithParams_8( item:MedicineJar, param1:*, param2:*, param3:*, param4:*, param5:*, param6:*, param7:*, param8:* ) : Object
        {
            return new item.antidoteFormula( param1, param2, param3, param4, param5, param6, param7, param8 );
        }
    }
}