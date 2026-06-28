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

var clusterScopedKinds = map[string]bool{
	"ClusterRole":                    true,
	"ClusterRoleBinding":             true,
	"CustomResourceDefinition":       true,
	"Namespace":                      true,
	"Node":                           true,
	"PersistentVolume":               true,
	"StorageClass":                   true,
	"ValidatingWebhookConfiguration": true,
	"MutatingWebhookConfiguration":   true,
}

type object map[string]any

func TestRenderedContracts(t *testing.T) {
	var all []object
	all = append(all, renderAndCheck(t, "platform/overlays/local", "platform")...)
	all = append(all, renderAndCheck(t, "apps/demo-api/overlays/local", "app")...)

	checkNoMessages(t, validateRequiredNamespaces(all))
	checkNoMessages(t, validateNamespaceBoundaries(all))
	checkNoMessages(t, validateDeployments(all))
	checkNoMessages(t, validateServices(all))
}

func TestContractFixtures(t *testing.T) {
	tests := []struct {
		name          string
		path          string
		expectedLayer string
		want          []string
	}{
		{
			name:          "missing required labels",
			path:          "tests/contracts/testdata/missing-required-labels",
			expectedLayer: "app",
			want:          []string{"missing metadata label app.kubernetes.io/name"},
		},
		{
			name:          "wrong layer",
			path:          "tests/contracts/testdata/wrong-layer",
			expectedLayer: "app",
			want:          []string{"expected layer app, got platform"},
		},
		{
			name:          "deployment missing resources",
			path:          "tests/contracts/testdata/deployment-missing-resources",
			expectedLayer: "app",
			want: []string{
				"missing resource requests",
				"missing resource limits",
			},
		},
		{
			name:          "container missing resource keys",
			path:          "tests/contracts/testdata/container-missing-resource-keys",
			expectedLayer: "app",
			want: []string{
				"missing resource requests.memory",
				"missing resource limits.cpu",
			},
		},
		{
			name:          "app namespace boundary",
			path:          "tests/contracts/testdata/app-platform-namespace",
			expectedLayer: "app",
			want:          []string{"app-layer namespaced resources must render into namespace demo"},
		},
		{
			name:          "platform namespace boundary",
			path:          "tests/contracts/testdata/platform-wrong-namespace",
			expectedLayer: "platform",
			want:          []string{"platform-layer namespaced resources must render into namespace platform"},
		},
		{
			name:          "deployment selector mismatch",
			path:          "tests/contracts/testdata/deployment-selector-mismatch",
			expectedLayer: "app",
			want:          []string{"selector.matchLabels must match pod template labels"},
		},
		{
			name:          "service selector missing name",
			path:          "tests/contracts/testdata/service-selector-missing-name",
			expectedLayer: "app",
			want:          []string{"service selector must include app.kubernetes.io/name"},
		},
		{
			name:          "service selector no deployment",
			path:          "tests/contracts/testdata/service-selector-no-deployment",
			expectedLayer: "app",
			want:          []string{"selector does not match any Deployment pod template labels"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			objects := renderKustomize(t, tt.path)
			messages := validateObjects(objects, tt.expectedLayer)
			var missing []string
			for _, want := range tt.want {
				if !containsMessage(messages, want) {
					missing = append(missing, want)
				}
			}
			if len(missing) > 0 {
				t.Fatalf("missing expected message substrings %q, got:\n%s", missing, strings.Join(messages, "\n"))
			}
		})
	}
}

func renderAndCheck(t *testing.T, path, expectedLayer string) []object {
	t.Helper()

	objects := renderKustomize(t, path)
	checkNoMessages(t, validateLabels(objects, expectedLayer))
	return objects
}

func checkNoMessages(t *testing.T, messages []string) {
	t.Helper()

	for _, message := range messages {
		t.Error(message)
	}
}

func validateObjects(objects []object, expectedLayer string) []string {
	var messages []string
	messages = append(messages, validateLabels(objects, expectedLayer)...)
	messages = append(messages, validateNamespaceBoundaries(objects)...)
	messages = append(messages, validateDeployments(objects)...)
	messages = append(messages, validateServices(objects)...)
	return messages
}

func validateLabels(objects []object, expectedLayer string) []string {
	var messages []string
	for _, obj := range objects {
		rid := resourceID(obj)
		labels := stringMap(nested(obj, "metadata", "labels"))

		if labels["app.kubernetes.io/name"] == "" {
			messages = append(messages, fmt.Sprintf("%s: missing metadata label app.kubernetes.io/name", rid))
		}
		if labels["app.kubernetes.io/part-of"] != "homelab-garden" {
			messages = append(messages, fmt.Sprintf("%s: app.kubernetes.io/part-of must be homelab-garden", rid))
		}

		layer := labels["homelab-garden.io/layer"]
		switch {
		case layer == "":
			messages = append(messages, fmt.Sprintf("%s: missing metadata label homelab-garden.io/layer", rid))
		case !allowedLayers[layer]:
			messages = append(messages, fmt.Sprintf("%s: homelab-garden.io/layer must be one of app, platform, policy", rid))
		case layer != expectedLayer:
			messages = append(messages, fmt.Sprintf("%s: expected layer %s, got %s", rid, expectedLayer, layer))
		}

		if kind(obj) == "Deployment" {
			templateLabels := stringMap(nested(obj, "spec", "template", "metadata", "labels"))
			for _, key := range []string{"app.kubernetes.io/name", "app.kubernetes.io/part-of", "homelab-garden.io/layer"} {
				if templateLabels[key] != labels[key] {
					messages = append(messages, fmt.Sprintf("%s: pod template label %s must match deployment metadata", rid, key))
				}
			}
		}
	}
	return messages
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

func validateNamespaceBoundaries(objects []object) []string {
	var messages []string
	for _, obj := range objects {
		if clusterScopedKinds[kind(obj)] {
			continue
		}

		ns := stringValue(nested(obj, "metadata", "namespace"))
		if ns == "" {
			continue
		}
		labels := stringMap(nested(obj, "metadata", "labels"))
		switch labels["homelab-garden.io/layer"] {
		case "platform":
			if ns != "platform" {
				messages = append(messages, fmt.Sprintf("%s: platform-layer namespaced resources must render into namespace platform, got %s", resourceID(obj), ns))
			}
		case "app":
			if ns == "platform" {
				messages = append(messages, fmt.Sprintf("%s: app-layer namespaced resources must not target namespace platform", resourceID(obj)))
			}
			if ns != "demo" {
				messages = append(messages, fmt.Sprintf("%s: app-layer namespaced resources must render into namespace demo, got %s", resourceID(obj), ns))
			}
		}
	}
	return messages
}

func validateRequiredNamespaces(objects []object) []string {
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
		return []string{fmt.Sprintf("missing expected Namespace resources: %s", strings.Join(missing, ", "))}
	}
	return nil
}

func validateDeployments(objects []object) []string {
	var messages []string
	for _, obj := range objects {
		if kind(obj) != "Deployment" {
			continue
		}
		rid := resourceID(obj)
		selector := stringMap(nested(obj, "spec", "selector", "matchLabels"))
		templateLabels := stringMap(nested(obj, "spec", "template", "metadata", "labels"))
		if len(selector) == 0 {
			messages = append(messages, fmt.Sprintf("%s: selector.matchLabels must be non-empty", rid))
		} else if !selectorMatches(selector, templateLabels) {
			messages = append(messages, fmt.Sprintf("%s: selector.matchLabels must match pod template labels", rid))
		}

		for _, container := range containers(obj) {
			name := stringValue(container["name"])
			if name == "" {
				name = "<missing-name>"
			}
			resources := objectMap(container["resources"])
			requests := objectMap(resources["requests"])
			limits := objectMap(resources["limits"])
			if requests == nil {
				messages = append(messages, fmt.Sprintf("%s container %s: missing resource requests", rid, name))
			}
			if limits == nil {
				messages = append(messages, fmt.Sprintf("%s container %s: missing resource limits", rid, name))
			}
			for _, key := range []string{"cpu", "memory"} {
				if requests != nil && requests[key] == nil {
					messages = append(messages, fmt.Sprintf("%s container %s: missing resource requests.%s", rid, name, key))
				}
				if limits != nil && limits[key] == nil {
					messages = append(messages, fmt.Sprintf("%s container %s: missing resource limits.%s", rid, name, key))
				}
			}
			securityContext := objectMap(container["securityContext"])
			if privileged, ok := securityContext["privileged"].(bool); ok && privileged {
				messages = append(messages, fmt.Sprintf("%s container %s: privileged containers are not allowed", rid, name))
			}
		}
	}
	return messages
}

func validateServices(objects []object) []string {
	var deployments []object
	for _, obj := range objects {
		if kind(obj) == "Deployment" {
			deployments = append(deployments, obj)
		}
	}

	var messages []string
	for _, service := range objects {
		if kind(service) != "Service" {
			continue
		}
		rid := resourceID(service)
		selector := stringMap(nested(service, "spec", "selector"))
		if len(selector) == 0 {
			messages = append(messages, fmt.Sprintf("%s: missing service selector", rid))
			continue
		}
		if selector["app.kubernetes.io/name"] == "" {
			messages = append(messages, fmt.Sprintf("%s: service selector must include app.kubernetes.io/name", rid))
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
			messages = append(messages, fmt.Sprintf("%s: selector does not match any Deployment pod template labels in namespace %s", rid, serviceNamespace))
		}
	}
	return messages
}

func containsMessage(messages []string, want string) bool {
	for _, message := range messages {
		if strings.Contains(message, want) {
			return true
		}
	}
	return false
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
