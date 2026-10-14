#!/usr/bin/env bash
set -euo pipefail

example_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
publisher_jar="${1:-${FHIR_PUBLISHER_HOME:-$HOME/.fhir/tools/publisher}/publisher.jar}"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [path/to/publisher.jar]" >&2
  exit 2
fi
for tool in sushi node java tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    exit 2
  fi
done
if [[ ! -f "$publisher_jar" ]]; then
  echo "Publisher JAR not found: $publisher_jar" >&2
  echo "Usage: $0 [path/to/publisher.jar]" >&2
  exit 2
fi
publisher_jar="$(cd -- "$(dirname -- "$publisher_jar")" && pwd)/$(basename -- "$publisher_jar")"
cd "$example_root"

echo "Generating the dependency resource and its snapshot"
sushi dependency-ig --snapshot

# The dependency is unpublished. Package its generated definition and cache it
# so the consumer's SUSHI run can resolve example.additional-resource#0.1.0.
package_dir="$example_root/.build/package"
mkdir -p "$package_dir"
cp dependency-ig/fsh-generated/resources/StructureDefinition-AdditionalRecord.json "$package_dir/"
cat > "$package_dir/package.json" <<'JSON'
{
  "name": "example.additional-resource",
  "version": "0.1.0",
  "type": "fhir.ig",
  "canonical": "http://example.org/fhir/additional-resource",
  "url": "http://example.org/fhir/additional-resource",
  "fhirVersions": ["6.0.0-snapshot1"],
  "dependencies": {"hl7.fhir.r6.core": "6.0.0-snapshot1"}
}
JSON
tar -czf .build/example.additional-resource-0.1.0.tgz -C .build package
dependency_cache="$HOME/.fhir/packages/example.additional-resource#0.1.0/package"
mkdir -p "$dependency_cache"
cp "$package_dir/"*.json "$dependency_cache/"

echo "Generating the consuming IG and its AdditionalRecord instance"
sushi consumer-ig

# This example has no website pages. Remove SUSHI's empty table of contents,
# which otherwise triggers an unrelated template error with -generation-off.
node - consumer-ig/fsh-generated/resources/ImplementationGuide-example.additional-resource-consumer.json <<'JS'
const fs = require('node:fs');
const filename = process.argv[2];
const ig = JSON.parse(fs.readFileSync(filename, 'utf8'));
delete ig.definition.page;
fs.writeFileSync(filename, JSON.stringify(ig, null, 2) + '\n');
JS

echo "Running IG Publisher $(java -jar "$publisher_jar" -v)"
java -Xmx3g -jar "$publisher_jar" \
  -ig consumer-ig/ig.ini -packages .build \
  -no-sushi -tx n/a -generation-off -validation-off \
  2>&1 | tee .build/publisher.log
