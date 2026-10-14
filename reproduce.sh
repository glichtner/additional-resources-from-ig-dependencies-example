#!/usr/bin/env bash
set -euo pipefail

example_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
publisher_jar="${1:-${FHIR_PUBLISHER_HOME:-$HOME/.fhir/tools/publisher}/publisher.jar}"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [path/to/publisher.jar]" >&2
  exit 2
fi
for tool in sushi java jekyll; do
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
mkdir -p .build

echo "Building the dependency IG"
sushi dependency-ig
java -Xmx3g -jar "$publisher_jar" -ig dependency-ig/ig.ini -no-sushi -tx n/a -validation-off \
  2>&1 | tee .build/dependency-publisher.log

echo "Building the consuming IG"
sushi consumer-ig
java -Xmx3g -jar "$publisher_jar" -ig consumer-ig/ig.ini -no-sushi -tx n/a -validation-off \
  2>&1 | tee .build/consumer-publisher.log
