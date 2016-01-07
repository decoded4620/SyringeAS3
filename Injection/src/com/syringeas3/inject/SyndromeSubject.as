package com.syringeas3.inject
{
    /**
     * Extending this class will automatically grant you self injection upon construction
     *  
     * @author TheTechnoViking
     * 
     */    
    public class SyndromeSubject extends Object implements ISyndromeSubject
    {
        /**
         * @private 
         */        
        private var _syringeId:String = null;
        /**
         * @private 
         */        
        private var _autoCreateSyringe:Boolean = false;
        
        /**
         * Constructor 
         * @param syringeId
         * @param autoCreateSyringe
         */        
        public function SyndromeSubject(syringeId:String = null, autoCreateSyringe:Boolean = false)
        {
            // finish creation of the super object so we have a full 'instance'   
            super();
            
            _syringeId = syringeId;
            _autoCreateSyringe = autoCreateSyringe;
            
            getTreament();
        }

        /**
         * Get treatments for all syndromes contained by this <code>SyndromeSubject</code> 
         */        
        public function getTreament():void
        {
            // at this point all of our members and function can be 'called'
            // so here we'll find Syringe and inject
            const s:Syringe = Syringe.find(_syringeId, _autoCreateSyringe );
            if(s != null)
            {
                s.inject(this);
            }
        }
    }
}