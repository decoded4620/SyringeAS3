Syringe is a Dependency Injection Framework that is extremely lightweight. It uses names that follow the theme*

Some Terms



Syringe: The Main Injection Mechanism.
Syndrome: A Class that is defined as a Dependency that is waiting to be supplied by Syringe 
SyndromeSubject : An Object Type that is thought to contain 'syndromes' (i.e. a patient) that can be treated by Syringe. Used in 'Auto Injection Schemes'.
AntidoteFormula: A Class that treats a Syndrome.
Antidote : An instance of the AntidoteFormula class, and can be used to satisfy Syndromes, served by a Dispensary.
RareAntidoteFormula / RareAntidote : A Singleton Instance of an Antidote (Dependency), served by a Dispensary.
MedicineJar : An object that manages either an Antidote (instance) or AntidoteFormula (Class) that will treat any Syndrome (by supplying a dependency) whose Antidote Variant is contained by this MedicineJar.
Dispensary : An object that manages a Dictionary of variant 'AntidoteFormula' (Classes|Class instance) values by variant name. This object supplies Syringe with Variant 'Antidotes' to treat specific Syndrome (Dependency) variants.
SingletonDispensary : A Dispensary that manages only 'Singleton' or 'rare' Antidotes. This Dispensary creates a Single instance of its 'AntidoteFormula' and serves that instance to Syringe anytime inoculation takes place.
Inoculation : A Synonym for 'Injection'.
Inoculate : To perform Inoculation (Injection) upon an object with one or more Syndromes requiring AnitdoteFormula or Antidote variants. 
To 'treate' : If an AntidoteFormula(class|object) implements or extends the Syndrome (class|interface), it can be said that the AntidoteFormula (class) treats the Syndrome (class|interface).