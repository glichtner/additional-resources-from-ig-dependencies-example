Resource: AdditionalRecord
Parent: DomainResource
Id: AdditionalRecord
Description: "A minimal additional resource supplied to the consuming IG."
* ^url = "http://hl7.org/fhir/StructureDefinition/AdditionalRecord"
* ^extension[+].url = "http://hl7.org/fhir/tools/StructureDefinition/additional-resource"
* ^extension[=].valueBoolean = true
* label 1..1 string "Record label"
