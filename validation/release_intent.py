#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INTENT_DIR = ROOT / "release-intents"
ALLOWED_ENVIRONMENTS = {"local", "hcloud-lab"}
REQUIRED_PATHS = (
    ("schemaVersion",),
    ("kind",),
    ("metadata", "name"),
    ("app", "id"),
    ("environment",),
    ("git", "revision"),
    ("manifest", "path"),
    ("image", "reference"),
    ("image", "identityMode"),
    ("validationEvidence",),
    ("authority",),
)
FORBIDDEN_TEXT = {
    "real-homelab",
    "production",
    "prod-cluster",
    "prod-argocd",
    "kubeconfig",
    "providerCredential",
    "providerCredentials",
    "secretKey",
    "accessToken",
}
FORBIDDEN_KEY_FRAGMENTS = ("secret", "token", "credential", "password")


def fail(errors, path, message):
    errors.append(f"{path.relative_to(ROOT)}: {message}")


def get_nested(data, *keys):
    cur = data
    for key in keys:
        if not isinstance(cur, dict) or key not in cur:
            return None
        cur = cur[key]
    return cur


def scan_forbidden_keys(intent_path, value, errors, path=()):
    if isinstance(value, dict):
        for key, child in value.items():
            key_path = path + (str(key),)
            key_name = str(key).lower()
            if any(fragment in key_name for fragment in FORBIDDEN_KEY_FRAGMENTS):
                fail(errors, intent_path, f"forbidden credential-like key '{'.'.join(key_path)}'")
            scan_forbidden_keys(intent_path, child, errors, key_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            scan_forbidden_keys(intent_path, child, errors, path + (str(index),))


def validate_forbidden_refs(intent_path, data, errors):
    lowered = json.dumps(data).lower()
    for forbidden in FORBIDDEN_TEXT:
        if forbidden.lower() in lowered:
            fail(errors, intent_path, f"forbidden real-homelab/private reference '{forbidden}'")
    scan_forbidden_keys(intent_path, data, errors)


def validate_intent(path):
    errors = []
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as err:
        return [f"{path.relative_to(ROOT)}: invalid JSON: {err}"]

    if not isinstance(data, dict):
        return [f"{path.relative_to(ROOT)}: intent must be a JSON object"]

    for field_path in REQUIRED_PATHS:
        if not get_nested(data, *field_path):
            fail(errors, path, f"{'.'.join(field_path)} is required")

    schema_version = data.get("schemaVersion")
    if schema_version and schema_version != "homelab-garden.release-intent/v1alpha1":
        fail(errors, path, "schemaVersion must be homelab-garden.release-intent/v1alpha1")

    kind = data.get("kind")
    if kind and kind != "ReleaseIntent":
        fail(errors, path, "kind must be ReleaseIntent")

    app_id = get_nested(data, "app", "id")
    if app_id and app_id != "demo-api":
        fail(errors, path, "app.id must be demo-api")

    environment = data.get("environment")
    if environment and environment not in ALLOWED_ENVIRONMENTS:
        fail(errors, path, "environment must be local or hcloud-lab")

    manifest_path = get_nested(data, "manifest", "path")
    if isinstance(manifest_path, str):
        if manifest_path.startswith("/") or ".." in Path(manifest_path).parts:
            fail(errors, path, "manifest.path must be a repository-relative path")
        elif not (ROOT / manifest_path).exists():
            fail(errors, path, f"manifest.path does not exist: {manifest_path}")

    image = data.get("image") if isinstance(data.get("image"), dict) else {}
    identity_mode = image.get("identityMode")
    reference = image.get("reference", "")
    if identity_mode and identity_mode not in {"digest", "tag"}:
        fail(errors, path, "image.identityMode must be digest or tag")
    elif identity_mode == "digest" and "@sha256:" not in reference:
        fail(errors, path, "digest image identity must include @sha256: in image.reference")
    elif identity_mode == "tag" and not image.get("risk"):
        fail(errors, path, "tag-only image identity must include image.risk")

    evidence = data.get("validationEvidence")
    if not isinstance(evidence, list) or not evidence:
        fail(errors, path, "validationEvidence must be a non-empty list")
    else:
        for index, item in enumerate(evidence):
            if isinstance(item, str) and item.strip():
                continue
            ref = item.get("ref") if isinstance(item, dict) else None
            if isinstance(ref, str) and ref.strip():
                continue
            fail(errors, path, f"validationEvidence[{index}] must be a non-empty string or object with non-empty ref")

    if data.get("authority") and data.get("authority") != "read-only":
        fail(errors, path, "authority must be read-only")

    validate_forbidden_refs(path, data, errors)
    return errors


def main():
    paths = sorted(INTENT_DIR.glob("*.json"))
    if not paths:
        print("No release intent files found", file=sys.stderr)
        return 1

    errors = []
    for path in paths:
        errors.extend(validate_intent(path))

    if errors:
        print("Release intent validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    for path in paths:
        print(f"ok: {path.relative_to(ROOT)}")
    print("Release intent validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
