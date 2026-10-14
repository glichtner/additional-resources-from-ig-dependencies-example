# Additional resources from IG dependencies

Minimal reproduction of an IG Publisher failure when an additional resource
comes from a dependency and its canonical URL is in the FHIR namespace.

`dependency-ig` defines `AdditionalRecord`, a specialization of `DomainResource`
with one required string field. Its canonical URL is
`http://hl7.org/fhir/StructureDefinition/AdditionalRecord`, and it explicitly sets
`http://hl7.org/fhir/tools/StructureDefinition/additional-resource` to `true`.

`consumer-ig` depends on that package and contains one `AdditionalRecord` instance
with `label = "Example record"`. It has no local resource definition or
`additional-resource` / `custom-resource` IG parameter.

## Run

Requirements: Bash, Java 17+, Node.js, SUSHI (tested with 3.20.1), and `tar`.
Both projects use FHIR **6.0.0-snapshot1**. Standard FHIR packages and the template
are downloaded on the first run if they are not cached.

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

1. Runs SUSHI on `dependency-ig`, including snapshot generation.
2. Packages the resource and installs the unpublished
   `example.additional-resource#0.1.0` dependency in `~/.fhir/packages` for SUSHI.
3. Runs SUSHI on `consumer-ig` and removes its empty generated table of contents.
4. Runs the Publisher on the consuming IG with the local dependency package.

The dependency is packaged directly; it needs no separate Publisher website build.
The consumer has no website pages. Removing SUSHI's empty page tree avoids an
unrelated Publisher template error when HTML generation is disabled.
The final command disables HTML generation, validation and terminology-server
use. Resource loading still runs, which is where the error occurs.
Generated resources, packages, logs, downloaded templates and JARs are ignored by Git.

## Expected failure

With **IG Publisher 3.0.0 (bundled FHIR Core 7.0.1)**, the script exits with code 1:

```text
Unable to determine type for .../AdditionalRecord-example-record:
Unknown.Unrecognised resource type 'AdditionalRecord' (in property 'resourceType')
```

The Publisher loads the definition but does not register it as an additional
resource because its URL is in the FHIR namespace. It then passes the instance
to the generated FHIR resource parser, which has no built-in `AdditionalRecord`
type. The log is saved in `.build/publisher.log`.

With the additional-resource registration fix, resource loading completes and
the instance retains its resource type and label. A fixed Publisher may therefore
finish successfully rather than reproduce the failure.

The initialization diagnostic about the bundled `DocumentStructure` example's
section slice minima is unrelated. The reproduced failure is the later
`Unrecognised resource type 'AdditionalRecord'` error.

## Source files

```text
.gitignore
README.md
reproduce.sh
dependency-ig/
  sushi-config.yaml
  input/fsh/additional-record.fsh
consumer-ig/
  sushi-config.yaml
  ig.ini
  input/ignoreWarnings.txt
  input/fsh/example-record.fsh
```

`ignoreWarnings.txt` contains only the required Publisher format header; no
messages are suppressed. All FHIR JSON is generated from the two FSH files.
