package contracts

import (
	"bytes"
	"fmt"
	"io"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
	"sigs.k8s.io/kustomize/api/krusty"
	kusttypes "sigs.k8s.io/kustomize/api/types"
	"sigs.k8s.io/kustomize/kyaml/filesys"
)

var allowedLayers = map[string]bool{
	"platform": true,
	"app":      true,
	"policy":   true,
}

var requiredNamespaces = []string{"platform", "demo"}

type object map[string]any

func TestRenderedContracts(t *testing.T) {
	var all []object
	all = append(all, renderAndCheck(t, "platform/overlays/local", "platform")...)
	all = append(all, renderAndCheck(t, "apps/demo-api/overlays/local", "app")...)

	checkRequiredNamespaces(t, all)
	checkDeployments(t, all)
	checkServices(t, all)
}

func renderAndCheck(t *testing.T, path, expectedLayer string) []object {
	t.Helper()

	objects := renderKustomize(t, path)
	for _, obj := range objects {
		rid := resourceID(obj)
		labels := stringMap(nested(obj, "metadata", "labels"))

		if labels["app.kubernetes.io/name"] == "" {
			t.Errorf("%s: missing metadata label app.kubernetes.io/name", rid)
		}
		if labels["app.kubernetes.io/part-of"] != "homelab-garden" {
			t.Errorf("%s: app.kubernetes.io/part-of must be homelab-garden", rid)
		}

		layer := labels["homelab-garden.io/layer"]
		switch {
		case layer == "":
			t.Errorf("%s: missing metadata label homelab-garden.io/layer", rid)
		case !allowedLayers[layer]:
			t.Errorf("%s: homelab-garden.io/layer must be one of app, platform, policy", rid)
		case layer != expectedLayer:
			t.Errorf("%s: expected layer %s, got %s", rid, expectedLayer, layer)
		}

		if kind(obj) == "Deployment" {
			templateLabels := stringMap(nested(obj, "spec", "template", "metadata", "labels"))
			for _, key := range []string{"app.kubernetes.io/name", "app.kubernetes.io/part-of", "homelab-garden.io/layer"} {
				if templateLabels[key] != labels[key] {
					t.Errorf("%s: pod template label %s must match deployment metadata", rid, key)
				}
			}
		}
	}

	return objects
}

func repoRoot(t *testing.T) string {
	t.Helper()

	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("locate test source")
	}
	return filepath.Clean(filepath.Join(filepath.Dir(file), "..", ".."))
}

func renderKustomize(t *testing.T, path string) []object {
	t.Helper()

	opts := krusty.MakeDefaultOptions()
	opts.LoadRestrictions = kusttypes.LoadRestrictionsNone

	k := krusty.MakeKustomizer(opts)
	resMap, err := k.Run(filesys.MakeFsOnDisk(), filepath.Join(repoRoot(t), path))
	if err != nil {
		t.Fatalf("render kustomize root %s: %v", path, err)
	}

	rendered, err := resMap.AsYaml()
	if err != nil {
		t.Fatalf("serialize rendered output for %s: %v", path, err)
	}

	return decodeYAML(t, rendered)
}

func decodeYAML(t *testing.T, data []byte) []object {
	t.Helper()

	decoder := yaml.NewDecoder(bytes.NewReader(data))
	var objects []object
	for {
		var obj object
		err := decoder.Decode(&obj)
		if err != nil {
			if err == io.EOF {
				break
			}
			t.Fatalf("decode rendered YAML: %v", err)
		}
		if len(obj) > 0 {
			objects = append(objects, obj)
		}
	}
	return objects
}

func checkRequiredNamespaces(t *testing.T, objects []object) {
	t.Helper()

	found := map[string]bool{}
	for _, obj := range objects {
		if kind(obj) == "Namespace" {
			found[stringValue(nested(obj, "metadata", "name"))] = true
		}
	}

	var missing []string
	for _, name := range requiredNamespaces {
		if !found[name] {
			missing = append(missing, name)
		}
	}
	if len(missing) > 0 {
		t.Errorf("missing expected Namespace resources: %s", strings.Join(missing, ", "))
	}
}

func checkDeployments(t *testing.T, objects []object) {
	t.Helper()

	for _, obj := range objects {
		if kind(obj) != "Deployment" {
			continue
		}
		rid := resourceID(obj)
		for _, container := range containers(obj) {
			name := stringValue(container["name"])
			if name == "" {
				name = "<missing-name>"
			}
			resources := objectMap(container["resources"])
			if _, ok := resources["requests"]; !ok {
				t.Errorf("%s container %s: missing resource requests", rid, name)
			}
			if _, ok := resources["limits"]; !ok {
				t.Errorf("%s container %s: missing resource limits", rid, name)
			}
			securityContext := objectMap(container["securityContext"])
			if privileged, ok := securityContext["privileged"].(bool); ok && privileged {
				t.Errorf("%s container %s: privileged containers are not allowed", rid, name)
			}
		}
	}
}

func checkServices(t *testing.T, objects []object) {
	t.Helper()

	var deployments []object
	for _, obj := range objects {
		if kind(obj) == "Deployment" {
			deployments = append(deployments, obj)
		}
	}

	for _, service := range objects {
		if kind(service) != "Service" {
			continue
		}
		rid := resourceID(service)
		selector := stringMap(nested(service, "spec", "selector"))
		if len(selector) == 0 {
			t.Errorf("%s: missing service selector", rid)
			continue
		}

		serviceNamespace := namespace(service)
		matched := false
		for _, deployment := range deployments {
			if namespace(deployment) != serviceNamespace {
				continue
			}
			podLabels := stringMap(nested(deployment, "spec", "template", "metadata", "labels"))
			if selectorMatches(selector, podLabels) {
				matched = true
				break
			}
		}
		if !matched {
			t.Errorf("%s: selector does not match any Deployment pod template labels in namespace %s", rid, serviceNamespace)
		}
	}
}

func containers(deployment object) []object {
	podSpec := objectMap(nested(deployment, "spec", "template", "spec"))
	var out []object
	for _, key := range []string{"initContainers", "containers"} {
		for _, item := range list(podSpec[key]) {
			if container := objectMap(item); container != nil {
				out = append(out, container)
			}
		}
	}
	return out
}

func selectorMatches(selector, labels map[string]string) bool {
	for key, value := range selector {
		if labels[key] != value {
			return false
		}
	}
	return true
}

func resourceID(obj object) string {
	return fmt.Sprintf("%s/%s", defaultString(kind(obj), "<missing-kind>"), defaultString(stringValue(nested(obj, "metadata", "name")), "<missing-name>"))
}

func namespace(obj object) string {
	return defaultString(stringValue(nested(obj, "metadata", "namespace")), "default")
}

func kind(obj object) string {
	return stringValue(obj["kind"])
}

func nested(value any, keys ...string) any {
	for _, key := range keys {
		m := objectMap(value)
		if m == nil {
			return nil
		}
		value = m[key]
	}
	return value
}

func objectMap(value any) object {
	if value == nil {
		return nil
	}
	if m, ok := value.(map[string]any); ok {
		return m
	}
	if m, ok := value.(object); ok {
		return m
	}
	return nil
}

func stringMap(value any) map[string]string {
	out := map[string]string{}
	for key, value := range objectMap(value) {
		if str, ok := value.(string); ok {
			out[key] = str
		}
	}
	return out
}

func list(value any) []any {
	if value == nil {
		return nil
	}
	items, ok := value.([]any)
	if !ok {
		return nil
	}
	return items
}

func stringValue(value any) string {
	str, _ := value.(string)
	return str
}

func defaultString(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
