# Local Secret Inputs

This directory contains public-safe templates for narrow local-only credential handoffs. Do not commit real tokens or decrypted secret manifests.

## Local ArgoCD repository credentials

`garden workflow local-argocd-reconcile --env local` can apply repository credentials to the disposable kind ArgoCD namespace before it applies app-of-apps.

Use one of these local-only inputs when the GitHub repo is private:

1. Runtime environment token, preferred for one-off runs:

   ```bash
   ARGOCD_GITHUB_TOKEN="$(gh auth token)" garden workflow local-argocd-reconcile --env local
   ```

   `GH_TOKEN` is also accepted. The username defaults to `ARGOCD_GITHUB_USERNAME`, `GITHUB_USERNAME`, `GH_USERNAME`, the GitHub repo owner parsed from `ARGOCD_REPO_URL`, then `x-access-token`.

2. Default encrypted source:

   ```bash
   SOPS_AGE_KEY_FILE=secrets/age/key.txt garden workflow local-argocd-reconcile --env local
   ```

   The default encrypted source path is `secrets/argocd-repo-creds.sops.yaml`. If `SOPS_AGE_KEY_FILE` is unset and `secrets/age/key.txt` exists, the apply helper uses that key automatically. Override the encrypted source with `ARGOCD_REPO_CREDS_SOPS_FILE=/path/to/secret.sops.yaml`.

3. Local plaintext Secret file:

   ```bash
   install -m 0600 secrets/argocd-repo-creds.yaml.template secrets/argocd-repo-creds.local.yaml
   # Edit only secrets/argocd-repo-creds.local.yaml with your local token.
   garden workflow local-argocd-reconcile --env local
   ```

   The default local file path is `secrets/argocd-repo-creds.local.yaml`. Override it with `ARGOCD_REPO_CREDS_FILE=/path/to/secret.yaml`.

To rotate the encrypted source, copy `secrets/argocd-repo-creds.yaml.template` to a temporary path, replace only `stringData.password`, then encrypt it back:

```bash
sops --encrypt --input-type yaml --output-type yaml --filename-override secrets/argocd-repo-creds.sops.yaml /tmp/argocd-repo-creds.yaml > secrets/argocd-repo-creds.sops.yaml
rm /tmp/argocd-repo-creds.yaml
```

The live Secret is applied only by `platform/addons/argocd/apply-local-apps.sh`, only after the script has accepted a `kind-*` context, and only to the local `argocd` namespace. It is not part of `make check` or `local-validate`.
