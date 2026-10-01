# NovaShop DevOps — TP1 (AWS, Terraform, Ansible, CI)

Ticket **CHG-NOVASHOP-001** — création automatisée du serveur PREPROD `SRV-WEB-PREPROD-01` et déploiement de l'application NovaShop.

## Chaîne mise en place

```
git push ──> GitHub ──> Runner RUNNER-DEVOPS-01 (self-hosted, label devops)
                              └──> terraform init + validate
Poste DevOps (AWS CloudShell)
   Terraform ──API AWS──> EC2 SRV-WEB-PREPROD-01 + Security Group
   Ansible   ──SSH──────> Nginx ──> NovaShop (HTTP 80)
```

> Le sujet est prévu pour GitLab + GitLab Runner : le fichier `.gitlab-ci.yml` est fourni à titre de référence,
> et l'équivalent GitHub Actions est dans `.github/workflows/terraform-validate.yml` (même job `terraform_validate`,
> exécuté par un runner auto-hébergé nommé `RUNNER-DEVOPS-01` avec le label `devops`).

## Structure

```
novashop-devops/
├── app/index.html
├── terraform/  main.tf · variables.tf · outputs.tf · terraform.tfvars
├── ansible/    inventory.ini · deploy.yml · ansible.cfg
├── .github/workflows/terraform-validate.yml
├── .gitlab-ci.yml
└── README.md
```

## Utilisation

```bash
# 1. Infrastructure
cd terraform
terraform init && terraform fmt && terraform validate
terraform plan && terraform apply
terraform output

# 2. Configuration (remplacer l'IP dans inventory.ini par l'output public_ip)
cd ../ansible
ansible all -i inventory.ini -m ping
ansible-playbook -i inventory.ini deploy.yml

# 3. Test
curl http://<public_ip>

# Nettoyage en fin de TP
cd ../terraform && terraform destroy
```

Aucun secret n'est versionné : les identifiants AWS viennent de l'environnement (CloudShell), la clé privée SSH
reste sur le poste (`~/.ssh/novashop-key`), seule sa partie publique est déclarée dans AWS (`novashop-key`).

## Relevé de l'infrastructure créée

| Élément | Valeur observée dans AWS |
|---|---|
| Instance ID | `i-0ab0aa3e0ae139bd5` |
| Public IP | `35.182.254.45` |
| Private IP | `172.31.3.254` |
| Instance type | `t3.micro` |
| Région | `ca-central-1` (AZ `ca-central-1b`) |
| Security Group | `novashop-preprod-sg` (`sg-0f96b24e8cf466b58`) |
| État de l'instance | `running` |
| AMI | `ami-09074928cc6690a45` (Ubuntu Server 24.04 LTS) |

## Résultats

- `ansible all -m ping` → `SUCCESS` / `"ping": "pong"`
- 1er `ansible-playbook` → `ok=4 changed=2 failed=0`
- 2e `ansible-playbook` → `ok=4 changed=0 failed=0` (idempotence)
- `http://35.182.254.45` → page NovaShop « Environnement PREPROD »

## Synthèse

**1. Pourquoi Terraform est-il utilisé avant Ansible ?**
Terraform crée l'infrastructure (instance EC2, Security Group) via l'API AWS : tant qu'elle n'existe pas, Ansible n'a
aucune machine ni adresse IP à joindre. Ansible intervient ensuite pour configurer l'intérieur du serveur par SSH
(paquets, services, fichiers). Terraform = provisionnement, Ansible = configuration.

**2. Quel est le rôle exact du Runner ?**
C'est l'agent qui exécute réellement les jobs du pipeline. GitLab/GitHub ne fait que stocker le code et déclencher le
pipeline ; le Runner (ici `RUNNER-DEVOPS-01`, exécution shell, label `devops`) récupère le job, clone le dépôt et lance
les commandes (`terraform init`, `terraform validate`) sur la machine où Terraform est installé, puis renvoie le
résultat et le statut (Passed/Failed).

**3. Que se passe-t-il si on relance le même playbook sans modifier le serveur ?**
Rien n'est modifié : les modules Ansible sont idempotents, ils vérifient l'état existant (Nginx déjà installé et
démarré, fichier identique) et n'agissent que s'il y a un écart. Le récapitulatif affiche `changed=0`
(vérifié : `ok=4 changed=0`).
