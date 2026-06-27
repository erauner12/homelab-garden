#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

render() {
  local name="$1"
  local path="$2"
  local output="$TMPDIR/${name}.yaml"

  echo "Rendering $path" >&2
  kustomize build "$ROOT/$path" >"$output"
  echo "$output"
}

platform_render="$(render platform platform/overlays/local)"
apps_render="$(render apps apps/demo-api/overlays/local)"

ruby - "$platform_render" "$apps_render" <<'RUBY'
require "yaml"
require "set"

ALLOWED_LAYERS = Set["platform", "app", "policy"]
REQUIRED_NAMESPACES = Set["platform", "demo"]

$errors = []
$all_docs = []

def dig_hash(hash, *keys)
  keys.reduce(hash) { |value, key| value.is_a?(Hash) ? value[key] : nil }
end

def resource_id(doc)
  "#{doc["kind"] || "<missing-kind>"}/#{dig_hash(doc, "metadata", "name") || "<missing-name>"}"
end

def load_render(path, expected_layer)
  YAML.load_stream(File.read(path)).compact.each do |doc|
    $all_docs << doc
    rid = resource_id(doc)
    labels = dig_hash(doc, "metadata", "labels") || {}

    $errors << "#{rid}: missing metadata label app.kubernetes.io/name" unless labels["app.kubernetes.io/name"]
    if labels["app.kubernetes.io/part-of"] != "homelab-garden"
      $errors << "#{rid}: app.kubernetes.io/part-of must be homelab-garden"
    end

    layer = labels["homelab-garden.io/layer"]
    if !layer
      $errors << "#{rid}: missing metadata label homelab-garden.io/layer"
    elsif !ALLOWED_LAYERS.include?(layer)
      $errors << "#{rid}: homelab-garden.io/layer must be one of #{ALLOWED_LAYERS.to_a.sort}"
    elsif layer != expected_layer
      $errors << "#{rid}: expected layer #{expected_layer}, got #{layer}"
    end

    next unless doc["kind"] == "Deployment"

    template_labels = dig_hash(doc, "spec", "template", "metadata", "labels") || {}
    ["app.kubernetes.io/name", "app.kubernetes.io/part-of", "homelab-garden.io/layer"].each do |key|
      if template_labels[key] != labels[key]
        $errors << "#{rid}: pod template label #{key} must match deployment metadata"
      end
    end
  end
end

def containers_for(deployment)
  pod_spec = dig_hash(deployment, "spec", "template", "spec") || {}
  Array(pod_spec["initContainers"]) + Array(pod_spec["containers"])
end

load_render(ARGV[0], "platform")
load_render(ARGV[1], "app")

namespaces = $all_docs.select { |doc| doc["kind"] == "Namespace" }.map { |doc| dig_hash(doc, "metadata", "name") }.to_set
missing_namespaces = REQUIRED_NAMESPACES - namespaces
$errors << "missing expected Namespace resources: #{missing_namespaces.to_a.sort}" unless missing_namespaces.empty?

$all_docs.select { |doc| doc["kind"] == "Deployment" }.each do |doc|
  rid = resource_id(doc)
  containers_for(doc).each do |container|
    cname = container["name"] || "<missing-name>"
    resources = container["resources"] || {}
    $errors << "#{rid} container #{cname}: missing resource requests" unless resources["requests"]
    $errors << "#{rid} container #{cname}: missing resource limits" unless resources["limits"]
    if dig_hash(container, "securityContext", "privileged") == true
      $errors << "#{rid} container #{cname}: privileged containers are not allowed"
    end
  end
end

services = $all_docs.select { |doc| doc["kind"] == "Service" }
deployments = $all_docs.select { |doc| doc["kind"] == "Deployment" }

services.each do |service|
  rid = resource_id(service)
  selector = dig_hash(service, "spec", "selector") || {}
  if selector.empty?
    $errors << "#{rid}: missing service selector"
    next
  end

  svc_namespace = dig_hash(service, "metadata", "namespace") || "default"
  matched = deployments.any? do |deployment|
    dep_namespace = dig_hash(deployment, "metadata", "namespace") || "default"
    next false unless dep_namespace == svc_namespace

    pod_labels = dig_hash(deployment, "spec", "template", "metadata", "labels") || {}
    selector.all? { |key, value| pod_labels[key] == value }
  end

  unless matched
    $errors << "#{rid}: selector does not match any Deployment pod template labels in namespace #{svc_namespace}"
  end
end

if $errors.any?
  warn "Contract validation failed:"
  $errors.each { |error| warn "- #{error}" }
  exit 1
end

puts "Contract validation passed"
RUBY
