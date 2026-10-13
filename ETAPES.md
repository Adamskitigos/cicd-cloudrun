# Étapes de mise en place (runbook)

Prérequis : `gcloud` installé et connecté (`gcloud auth login`), un compte GitHub, `git`.
Toutes les commandes se lancent depuis la racine du projet.

## 0. Tester en local (optionnel)
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -v
python -m app.main            # http://localhost:8080
```

## 1. Projet GCP
```bash
gcloud projects create <ID_UNIQUE>          # ou utilisez un projet existant
gcloud config set project <ID_UNIQUE>
# Liez un compte de facturation dans la console (Billing) si ce n'est pas fait
```

## 2. Dépôt GitHub
```bash
git init && git add . && git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<USER>/cicd-cloudrun.git
git push -u origin main
```
Puis éditez `scripts/config.sh` : `GITHUB_OWNER` et `GITHUB_REPO`.

## 3. Setup GCP (APIs, Artifact Registry, comptes de service, IAM)
```bash
chmod +x scripts/*.sh
./scripts/01_setup_gcp.sh
```

## 4. Connecter GitHub à Cloud Build (une seule fois, dans la console)
Console GCP > **Cloud Build** > **Triggers** > **Connect repository** > *GitHub (Cloud Build GitHub App)*
> autorisez l'accès > sélectionnez votre dépôt > **Connect** (ne créez pas de trigger ici).

## 5. Créer les triggers
```bash
./scripts/02_create_triggers.sh
```
Puis lancez le premier déploiement :
```bash
gcloud builds triggers run deploy-on-main --branch=main --region=global
```

## 6. Vérifier
```bash
./scripts/03_status.sh
```
Console : Cloud Build > Historique (logs des builds) / Cloud Run > cicd-demo > Révisions.

## 7. Démo versioning
Dans `app/main.py`, remplacez `APP_VERSION = "v1"` par `"v2"` (et le test reste vert car il compare à la constante).
```bash
git commit -am "Release v2" && git push
```
Le pipeline redéploie automatiquement. `./scripts/03_status.sh` montre 2 révisions.
Chaque commit a aussi sa propre URL : `https://c-<sha>---cicd-demo-xxxx.run.app`.

## 8. Démo rollback
```bash
./scripts/04_rollback.sh            # retour à v1, sans rebuild
./scripts/04_rollback.sh --latest   # retour à v2
```

## 9. Démo canary (bonus)
```bash
./scripts/05_canary.sh 10           # 10 % v2 / 90 % v1, affiche la répartition
./scripts/05_canary.sh 100          # promotion complète
```

## 10. Démo test bloquant (bonus)
Cassez un test volontairement (ex. `assert r.status_code == 500` dans `test_health`) et poussez :
le build échoue à l'étape `tests`, **rien n'est déployé**. Annulez ensuite le commit.

## 11. Démo pull request (bonus)
```bash
git checkout -b feature/x && git commit --allow-empty -m "test PR" && git push -u origin feature/x
```
Ouvrez une PR vers main : le trigger `test-on-pr` lance les tests sans déployer.

## 12. Rendu
```bash
./scripts/06_add_teacher.sh         # prof en Viewer sur le projet
```
Envoyez par mail : lien du repo, `cloudbuild.yaml`, captures (Cloud Build history, révisions Cloud Run, rollback), doc + schéma.

## 13. Nettoyage (après la note)
```bash
./scripts/99_cleanup.sh
```
