package com.syringe.examples
{
    import com.syringe.examples.formula.tummyAches.MinorTummyAcheFormula;
    import com.syringe.examples.syndrome.ISinusInfectionSyndrome;
    import com.syringe.examples.syndrome.ITummyAcheSyndrome;
    import com.syringe.examples.formula.sinusInfections.MajorSinusInfectionFormula;
    import com.syringe.examples.formula.sinusInfections.MildSinusInfectionFormula;
    import com.syringeas3.inject.Syringe;

    /**
     * Shows variable injection with Syringe 
     * @author TheTechnoViking
     * 
     */    
    public class SyringeVariableInjection
    {
        //======================================================================================================================
        // Example Setup
        //======================================================================================================================
        /**
         * @private
         * The Syringe Instance that is managing our treatments 
         */        
        private var _syringe:Syringe;
        /**
         * Example 1. Single Variable Injection with Syringe. 
         */        
        public function SyringeVariableInjection()
        {
            
        }
        
        //======================================================================================================================
        // Example Syringe Treatments (Injections)
        //======================================================================================================================
        /**
         * Example 1-A 
         * public member injection, the syndrome is the minorSinusInfection. 
         * Syringe will check its 'Dispensaries' to see if there is a <code>treatment</code> (a Class instance that can fill the dependancy) for a
         * 'mild' ISinusInfectionSyndrome. If there is an AntidoteFormula instance managed by the Syringe for 'everyDaySicknesses'
         * this public member will be assigned the value of that instance
         */        
        [Treat (variant='mildCase')]
        public var mildSinusInfection:ISinusInfectionSyndrome;
        
        /**
         * Example 1-B
         * public member injection, the syndrome is the minorSinusInfection. 
         * Syringe will check its 'Dispensaries' to see if there is a <code>treatment</code> (a Class that can fill the dependancy) for a
         * 'major' ISinusInfectionSyndrome. If there is a treatment in Syringe that is avialable for this 'variant'
         */  
        [Treat (variant='majorCase')]
        public var majorSinusInfection:ISinusInfectionSyndrome;

        /**
         * @private 
         */        
        private var _tummyAche:ITummyAcheSyndrome;
        
        /**
         * Example 1-C
         * public member injection, the syndrome is the minorSinusInfection. 
         * Syringe will check its 'Dispensaries' to see if there is a <code>treatment</code> (a Class that can fill the dependancy) for a
         * 'minor' ITummyAcheSyndrome. If there is a treatment, this setter is invoked with the treatment (the value managed by Syringe).
         */  
        [Treat (variant='minorCase')]
        public function set tummyAche( value:ITummyAcheSyndrome ):void
        {
            trace("treating tummyAche (Syndrome) with treatment Object( " + value  + ")");
            _tummyAche = value;
        }
        public function get tummyAche():ITummyAcheSyndrome
        {
            return _tummyAche;
        }
        
        private var _everydaySicknessesSyringeId:String = 'everydaySicknesses';
        
        public function initialize():void
        {
            // get the 'syringe' instances that supplies antidotes for 'everyday sicknesses' i.e. Sinus Infection, etc
            // this will NOT create it if it doesn't exist.
            _syringe = Syringe.find(_everydaySicknessesSyringeId, false);
            
            // if syringe was not found, create it now, and add some 'AntidoteFormulas' to treat (implement|extend) known Syndrome (classes|interfaces).
            if(_syringe == null)
            {
                // create an instance of 'syringe' for everyday sicknesses
                _syringe = Syringe.find(_everydaySicknessesSyringeId, true);
                
                // ~ Adding Treatments ~
                //  The Logic:
                //   -- IF:   i have an unsupplied dependency of type 'ISinusInfection',
                //   -- AND:  it is annoted [Inject (variant='mild')] (as you see above),
                //   -- THEN: calling _syringe.inject() upon myself will supply my sinusInfection with a 
                //          MildSinusInfectionFormula instance (which implements ISinusInfectionSyndrome).
                _syringe.addTreatment( ISinusInfectionSyndrome, MildSinusInfectionFormula, 'mildCase', true );
                
                
                // add another treatment formula for a 'majorCase' of ISinusInfectionSyndrome
                _syringe.addTreatment( ISinusInfectionSyndrome, MajorSinusInfectionFormula, 'majorCase', true );
                
                // add a treatment formula for  a 'minorCase' of a ITummyAche :P.
                _syringe.addTreatment( ITummyAcheSyndrome, MinorTummyAcheFormula, 'minorCase', true );
            }
            
            // turn on the trace statements to learn good things @@
            _syringe.debug = true;
            
            // perform injection to get treatments for all of our 'syndromes' above (setters/public members)
            _syringe.inject(this);
            
            trace("Syringe Injected Antidote Formulas: \n" +
                "\tTreatement for ISinusInfectionSyndrome, variant 'majorCase' is  " + majorSinusInfection + "\n" +
                "\tTreatement for ISinusInfectionSyndrome, variant 'mildCase' is " + mildSinusInfection + "\n" +
                "\tTreatement for ITummyAcheSyndrome, variant 'minorCase' is " + tummyAche + "\n"
                );
        }
    }
}