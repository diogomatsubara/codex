Create a new GCP project, named whatever you want.
(I chose "codex")

From the Google Cloud COnsole, enable the following:

  - Compute Engine API (should already be enabled)
  - IAM API
  - CRM API

Then, from the gcloud shell (the `>_` icon):

```
export project_id=$(gcloud config get-value project)
export region=us-east1
export zone=us-east1-d
export service_account_email=terraform@${project_id}.iam.gserviceaccount.com

gcloud config set compute/zone ${zone}
gcloud config set compute/region ${region}

gcloud iam service-accounts create terraform --display-name terraform
gcloud iam service-accounts keys create ~/terraform.key.json \
  --iam-account ${service_account_email}

gcloud projects add-iam-policy-binding ${project_id} \
  --member serviceAccount:${service_account_email} \
  --role roles/owner
```

Copy the contents of ~/terraform.key.json down to wherever you
want to run Terraform from, into the file `keys/iam.json` in the
`google/` directory.

Then, create a key:

```
mkdir keys
ssh-keygen -f keys/gce </dev/null
chmod 0400 keys/*
echo "/keys" >> .gitignore
```

Finally, populate your tfvars file (example):

```
google_project      = "<< YOUR PROJECT ID >>"
google_region       = "us-east1"
google_az1          = "b"
google_network_name = "codex"
google_credentials  = "keys/iam.json"
google_pubkey_file  = "keys/gce.pub"
```
