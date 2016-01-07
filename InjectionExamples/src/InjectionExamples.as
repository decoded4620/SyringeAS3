package
{
    import com.syringe.examples.SyringeVariableInjection;
    
    import flash.display.Sprite;
    import flash.events.Event;
    
    /**
     * Example Runner for Injection With Syringe
     *  
     * @author TheTechnoViking
     */    
    public class InjectionExamples extends Sprite
    {
        public function InjectionExamples()
        {
            trace("Injection Examples!");
            addEventListener( Event.ADDED_TO_STAGE, onAddedToStage);
        }
        
        
        protected function onAddedToStage(e:Event):void
        {
            removeEventListener( e.type, onAddedToStage );
            
            // run the basic example
            var variableInjectionExample:SyringeVariableInjection = new SyringeVariableInjection();
            variableInjectionExample.initialize();
            
            // TODO
            
            // var functionInjectionExample = new SyringeFunctionInjection();
            // functionInjectionExample.initialize();
            
            // var classInjectionExample = new SyringeClassInjection();
            // classInjectionExample.initialize();
        }
    }
}