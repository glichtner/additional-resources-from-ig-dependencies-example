# Additional resources from IG dependencies

Minimal reproduction of an IG Publisher failure when an additional resource
comes from a dependency and its canonical URL is in the FHIR namespace.

See https://github.com/HL7/fhir-ig-publisher/pull/1410.

`dependency-ig` defines `AdditionalRecord`, a specialization of `DomainResource`. Its canonical URL is
`http://hl7.org/fhir/StructureDefinition/AdditionalRecord`, and it explicitly sets
`http://hl7.org/fhir/tools/StructureDefinition/additional-resource` to `true`.

`consumer-ig` depends on that package and contains one `AdditionalRecord` instance

## Run


From the repository root:

```sh
npm install --global fsh-sushi@3.20.1
curl --fail --location https://github.com/HL7/fhir-ig-publisher/releases/download/3.0.0/publisher.jar --output publisher.jar
./reproduce.sh ./publisher.jar
```

Alternatively, run `./reproduce.sh` to use the Publisher already installed at
`~/.fhir/tools/publisher/publisher.jar` (or `$FHIR_PUBLISHER_HOME/publisher.jar`).
An explicit JAR path can be absolute or relative to the current working directory.

The script:

1. Runs SUSHI on `dependency-ig`.
2. Runs the Publisher on `dependency-ig`, generating snapshots and the package.
   The Publisher automatically installs it as `example.additional-resource#dev`
   in the local FHIR package cache.
3. Runs SUSHI on `consumer-ig`, which declares that `dev` dependency.
4. Runs the Publisher on `consumer-ig`, where the failure occurs.


## Expected failure

With **IG Publisher 3.0.0 (bundled FHIR Core 7.0.1)**, the script exits with code 1:

```text
Unable to determine type for .../AdditionalRecord-example-record:
Unknown.Unrecognised resource type 'AdditionalRecord' (in property 'resourceType')
```


