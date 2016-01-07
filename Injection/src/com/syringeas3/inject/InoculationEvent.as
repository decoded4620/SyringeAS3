package com.syringeas3.inject
{
    import flash.events.Event;
    
    /**
     * This Event Class is used solely by Syringe to notify observers of innoculations that
     * may require 're-inoculation' of existing dependency requirements in an injected object.
     *  
     * @author barcher
     */    
    public class InoculationEvent extends Event
    {
        /**
         * If event type is ANTIDOTE_VARIANT_CHANGE, this will be the old mapping value for the
         * Dependency mapping that was changed 
         */        
        public var oldVariant:String                                                        = null;
        
        /**
         * The variant name that generated the event 
         */        
        public var variant:String                                                           = null;
        
        /**
         * The Old Dependency Class (or interface) from the previous mapping after a ANTIDOTE_VARIANT_CHANGE event 
         */        
        public var oldSyndrome:Class                                                 = null;
        
        /**
         * the dependency class (or interface) for this mapping
         */
        public var syndrome:Class                                                    = null;
        
        /**
         * the previous dependency implementation for this mapping ( this is a class, not an interface )
         */
        public var oldAntidoteFormula:Class                                                  = null;
        
        /**
         * the current dependency implementation for this mapping ( this is a class, not an interface )
         */
        public var antidoteFormula:Class                                                     = null;
        
        /**
         * The old dependency instance 
         */        
        public var oldRareAntidoteFormula:Object                                                 = null;
        
        /**
         * the dependency instance of the dependency mapped class
         */
        public var rareAntidoteFormula:Object                                                    = null;
        
        /**
         * <code>true</code> if the previous dependency was served as a Singleton
         */        
        public var oldAntidoteIsRare:Boolean                                         = false;
        
        /**
         * <code>true</code> if the current dependency is Singleton Mapped. 
         */        
        public var antidoteIsRare:Boolean                                            = false;
        
        /**
         * The Type of dependency change (update, remove, or add) 
         */        
        public var changeType:int                                                           = -1;
        
        /**
         * If a dependency is changed from a previous value to a new value 
         */        
        public static const CHANGE_TYPE_CHANGE:int  = 0;
        
        /**
         * If a dependency is added for the first time 
         */        
        public static const CHANGE_TYPE_ADD:int     = 1;
        
        /**
         * If a dependency is removed 
         */        
        public static const CHANGE_TYPE_REMOVE:int  = 2;
        
        /**
         * Event Type Dispatched when variants change for a specified syndrome. 
         */        
        public static const ANTIDOTE_VARIANT_CHANGE:String   = "antidoteVariantChange";
        
        /**
         * @see flash.events.Event
         */        
        public function InoculationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
        {
            super(type, bubbles, cancelable);
        }
        
        /**
         * Debugging
         *  
         * @return 
         * a <code>String</code>
         */        
        override public function toString():String
        {
            return super.toString() + "\nProperties:\n" + 
                "[" + 
                    "\n\toldVariant:         " + oldVariant + "            \tnewVariant:             " + variant + 
                    "\n\toldSyndrome:        " + oldSyndrome + "           \tnewSyndrome:            " + syndrome + 
                    "\n\toldAntidoteFormula: " + oldAntidoteFormula + "    \tnewAntidoteFormula:     " + antidoteFormula +
                    "\n\toldRareAntidote:    " + oldRareAntidoteFormula + "\tnewRareAntidoteFormula: " + rareAntidoteFormula + 
                    "\n\toldAntidoteIsRare:  " + oldAntidoteIsRare + "     \tnewAntidoteIsRare?      " + antidoteIsRare +
                "\n]";
        }
    }
}