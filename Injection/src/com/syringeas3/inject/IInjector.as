package com.syringeas3.inject
{
    /**
     * Interface for a Metadata Tag Injector using Reflection Data
     * returned from DescribeType or DescribeTypeCache.
     *  
     * @author TheTechnoViking
     */	
    public interface IInjector
    {
        /**
         * returns the [MetaTag] name that this injector will operate on.
         *  
         * @return 
         * a String
         */		
        function get metadataTagName():String;
        
        /**
         * Given a Metadata tag around a thing (Variable / Accessor, or Class)
         * this will parse the metadata and perform any injection operations supported for this
         * metadata tag.
         *  
         * @param syringeId
         * a <code>String</code>, the id of the Syringe Instance that is involved with this 'treatment'
         * 
         * @param metadata
         * a <code>XML</code> snippet of the injection metadata
         * 
         * @param target
         * a <code>Object</code> target to use for injection
         * 
         * @param extraArgs
         * a <code>XMLList</code> of extra metadata arguments, if needed.
         * 
         * @param parameters
         * an <code>Array</code> of parameters for constructor or injection purposes
         */        
        function inoculate(syringeId:String, metadata:XML, target:Object, extraArgs:XMLList = null, parameters:Array = null):void;
    }
}