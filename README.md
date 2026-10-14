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

Requirements: Bash, Java 17+, SUSHI (tested with 3.20.1), and Ruby/Jekyll.
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

1. Runs SUSHI on `dependency-ig`.
2. Runs the Publisher on `dependency-ig`, generating snapshots and the package.
   The Publisher automatically installs it as `example.additional-resource#dev`
   in the local FHIR package cache.
3. Runs SUSHI on `consumer-ig`, which declares that `dev` dependency.
4. Runs the Publisher on `consumer-ig`, where the failure occurs.

Both IGs use the normal Publisher build. `-no-sushi` avoids rerunning SUSHI;
`-tx n/a` disables terminology-server use. `-validation-off` skips FHIR
validation to isolate the resource-loading failure. Snapshot generation,
website generation and package generation still run. The package is built and cached by
the Publisher without manual packaging or editing of generated FHIR JSON.
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
type. Logs are saved in `.build/dependency-publisher.log` and
`.build/consumer-publisher.log`.

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
  ig.ini
  input/ignoreWarnings.txt
  input/fsh/additional-record.fsh
  input/pagecontent/index.md
consumer-ig/
  sushi-config.yaml
  ig.ini
  input/ignoreWarnings.txt
  input/fsh/example-record.fsh
  input/pagecontent/index.md
```

`ignoreWarnings.txt` contains only the required Publisher format header; no
messages are suppressed. All FHIR JSON is generated from the two FSH files.
