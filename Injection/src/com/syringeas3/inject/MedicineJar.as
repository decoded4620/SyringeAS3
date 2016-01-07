package com.syringeas3.inject
{
    /**
     * A Single Dependency Item that belongs to a Dependency Rule for a 
     * specified Class or Interface.
     *  
     * @author barcher
     */
    
    public class MedicineJar
    {
        protected var _BaseFormula:Class;
        protected var _AntidoteFormula:Class;
        protected var _antidoteInstance:Object;
        
        protected var _isDisposed:Boolean = false;
        protected var _isShuttingDown:Boolean = false;
        protected var _isInitialized:Boolean = false;
        
        private var _syringeId:String = Syringe.DEFAULT_VARIANT;
        /**
         * Constructor
         *  
         * @param Dependency
         * @param Injected
         */    
        public function MedicineJar(syringeId:String)
        {
            _syringeId = syringeId;
        }
        
        /**
         * Uses an Antidote Definition (Class) to 'fill' the medicine jar. Which means this class will
         * be served upon injection requests for the Dependency class provided.
         *  
         * Initializes a Class Definition to be constructed / served upon injection
         *  
         * @param Syndrome
         * a <code>Class</code> or <code>Interface</code> that requires an Antidote / AntidoteFormula, i.e. an unsupplied dependency type.
         * 
         * @param AntidoteFormula
         * a <code>Class</code> that will be used any time Syndrome is encountered as a Missing Dependency
         */    
        public function fillWithFormula( Syndrome:Class, AntidoteFormula:Class = null ) : void
        {
            _BaseFormula = Syndrome;
            _antidoteInstance = null;
            if( AntidoteFormula == null )
                _AntidoteFormula = _BaseFormula;
            else
                _AntidoteFormula = AntidoteFormula;
        }
        
        /**
         * Initializes an object instance of an AntidoteFormula (Class) for the specified dependency.
         *  
         * @param Dependency
         * a <code>Class</code>
         * 
         * @param InjectedObject
         * a <code>Object</code> to inject when injection is handled.
         */    
        public function fillWithAntidote( Syndrome:Class, antidote:Object ) : void
        {
            if(antidote == null)
                throw new Error("Cannot fill medicine jar with null antidote. Dependency not satisfied");
            
            // lets assume the syndrome can 'cure' itself, i.e. be used as supplement for its own Dependency Type.
            // This won't work if the Syncrome is an Interface instead of a class!! If thats the case, use fillWithFormula and
            // supply a Class for AntidoteFormula.
            _BaseFormula = Syndrome;
            _antidoteInstance = antidote;
            
            // if the antidote happens to be an IInjectedObject
            // run it through Syringe and populate its dependencies
            // prior to returning it to the calling entity.
            if( !( _antidoteInstance is ISyndromeSubject ) )
                Syringe.find().inject( _antidoteInstance );
            
            _AntidoteFormula = null;
        }
        
        /**
         * The Injected Instance for a Singleton that was mapped externally AFTER construction. 
         * @return 
         * a <code>Object</code>
         */    
        public function get antidoteInstance():Object
        {
            return _antidoteInstance;
        }
        
        /**
         * The Class that will be constructed / served based on the <code>classDef</code> 
         * @return 
         * 
         */    
        public function get antidoteFormula():Class
        {
            return _AntidoteFormula;
        }
        
        /**
         * The API or Interface used to retrieve implementations (via Compile-Time Type Information)
         */
        public function get baseFormula():Class
        {
            return _BaseFormula;
        }
        
        /**
         * @see com.wgt.core.IManagedOBject#isDisposed
         */
        public function get isDisposed():Boolean
        {
            return _isDisposed;
        }
        
        /**
         * @see com.wgt.core.IManagedOBject#isShuttingDown
         */
        public function get isShuttingDown():Boolean
        {
            return _isShuttingDown;
        }
        
        /**
         * @see com.wgt.core.IManagedOBject#isInitialized
         */
        public function get isInitialized():Boolean
        {
            return _isInitialized;
        }
        
        /**
         * @see com.wgt.core.IManagedOBject#initialize() 
         */
        public function initialize():void
        {
            if( !_isInitialized )
            {
                _isInitialized = true;
                _isShuttingDown = false;
                
                _isDisposed = false;
            }
        }
        
        /**
         * @see com.wgt.core.IManagedOBject#dispose() 
         */    
        public function dispose():void
        {
            if( _isInitialized && !_isShuttingDown && !_isDisposed )
            {
                _isShuttingDown = true;
                _isInitialized = false;
                
                if( Syringe.find().debug )
                    trace( "[DEBUG][Syringe::Dispensary::MedicineJar]::dispose( " + _AntidoteFormula + " )" );
                
                if( _AntidoteFormula != null )
                {
                    // check for a static disposal for this object
                    if( _AntidoteFormula["dispose"] != null )
                        _AntidoteFormula.dispose();
                }
                
                _BaseFormula = null;
                _AntidoteFormula = null;
                
                _isDisposed = true;
            }
        }
    }
}