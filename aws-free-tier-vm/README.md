# Terraform lab: a free-tier VM on AWS

In this lab you will use Terraform to create one small Linux virtual machine
(an EC2 instance) on AWS, log in to it, open a web page it serves, change it,
and finally destroy it. Everything stays inside the AWS Free Tier **as long as
you follow the cleanup steps at the end**.

Time needed: 60 to 90 minutes.

## What you will build

```
Your laptop                       AWS (one region)
+------------------+              +----------------------------------------+
| terraform CLI    |  --API-->    | default VPC                            |
| aws CLI          |              |  +----------------------------------+  |
| ~/.ssh/id_ed25519|              |  | security group: 22 (SSH), 80 (HTTP)|  |
+------------------+              |  |  +----------------------------+  |  |
        |                         |  |  | EC2 t3.micro, Ubuntu 24.04 |  |  |
        |  ssh / http             |  |  | nginx -> "Hello from TF"   |  |  |
        +------------------------>|  |  +----------------------------+  |  |
                                  |  +----------------------------------+  |
                                  +----------------------------------------+
```

Terraform creates three things: an SSH key pair, a security group (firewall),
and the instance. It *reads* (but does not create) the default VPC, its subnets,
and the latest Ubuntu image.

## Quick start: every command in order

The full walkthrough is below. If you just want the commands, run these from
the `aws-free-tier-vm` folder, top to bottom.

```bash
# 0. Prerequisites (once per laptop)
terraform -version                      # need >= 1.5
aws --version
aws configure                           # access key, secret, region (e.g. eu-central-1), json
aws sts get-caller-identity             # must print your account ID
ls ~/.ssh/*.pub                         # need one public key; if none:
ssh-keygen -t ed25519 -C "student"      #   creates ~/.ssh/id_ed25519.pub

# 1. Configure
cd aws-free-tier-vm
cp terraform.tfvars.example terraform.tfvars
curl -s ifconfig.me                     # your public IP, for ssh_allowed_cidr
#    edit terraform.tfvars: aws_region, ssh_public_key_path, ssh_allowed_cidr = "<ip>/32"

# 2. Create the VM
terraform init                          # download the AWS provider
terraform fmt                           # tidy formatting (optional)
terraform validate                      # syntax check, no AWS calls
terraform plan                          # expect: 3 to add, 0 to change, 0 to destroy
terraform apply                         # type yes; ~30 s

# 3. Use the VM (wait ~1 min for nginx to install)
terraform output                        # instance_id, public_ip, ssh_command, web_url
curl $(terraform output -raw web_url)   # <h1>Hello from Terraform!</h1>
$(terraform output -raw ssh_command)    # log in as ubuntu; or:
ssh -i ~/.ssh/<your-key> ubuntu@$(terraform output -raw public_ip)
#    on the VM:  cat /var/log/cloud-init-output.log ; exit

# 4. Inspect state
terraform state list
terraform state show aws_instance.vm
terraform plan                          # expect: No changes.

# 5. Change something, then re-plan and re-apply
#    edit main.tf (user_data text -> replacement; add a tag -> in-place update)
terraform plan
terraform apply

# 6. Destroy everything (do not skip; this is what keeps it free)
terraform destroy                       # type yes; expect: 3 destroyed
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output table
aws ec2 describe-volumes --query 'Volumes[].VolumeId' --output table   # should be empty
aws ec2 describe-addresses --query 'Addresses[].PublicIp' --output table # should be empty
```

## Read this first: what "free" means on AWS

AWS changed its Free Tier on 15 July 2025. Which rules apply to you depends on
**when your account was created**. Check in the AWS console under
*Billing and Cost Management -> Free Tier*.

| Account created        | What you get for EC2                                                                           |
|------------------------|-----------------------------------------------------------------------------------------------|
| Before 15 July 2025    | 12 months of 750 hours/month of t2.micro or t3.micro, 30 GB of EBS storage, 750 h of public IPv4 |
| On/after 15 July 2025  | A credit balance (up to USD 200, some of it unlocked by completing activities) valid for 6 months on the Free plan. EC2 usage is paid from those credits. |

Rules that keep this lab free under either model:

- **One instance at a time**, type `t3.micro` (or `t2.micro`). The `instance_type`
  variable refuses anything else.
- **Destroy it when you are done.** 750 hours is one instance running all month.
  Two instances, or forgetting one for a few weeks, is what produces a bill.
- Root disk is 8 GB gp3 (limit is 30 GB).
- Public IPv4 addresses cost about USD 0.005/hour outside the free allowance.
  Our instance has one. Again: destroy when done.
- Data transfer out is free up to 100 GB/month. A few web page loads are nothing.

**Set up a billing alert before you start** (AWS console -> Billing -> Budgets ->
Create budget -> *Zero spend budget*). It emails you the moment anything is
charged. This takes two minutes and is the best habit you will learn today.

## Prerequisites

1. **An AWS account.** Do not use the root user for daily work. Create an IAM
   user (or, better, an IAM Identity Center user) with the
   `AmazonEC2FullAccess` policy and create an access key for it.
2. **AWS CLI** installed: `aws --version`.
3. **Terraform >= 1.5** installed: `terraform -version`.
   macOS: `brew install terraform`. Others: https://developer.hashicorp.com/terraform/install
4. **An SSH key pair on your laptop.** If `ls ~/.ssh/id_ed25519.pub` shows
   nothing, create one:

   ```bash
   ssh-keygen -t ed25519 -C "student"
   ```

   Accept the defaults. The `.pub` file is uploaded to AWS; the private key
   never leaves your machine.

## Step 1. Give Terraform your AWS credentials

```bash
aws configure
```

Enter the access key ID, the secret key, a default region such as
`eu-central-1`, and output format `json`. Verify it works:

```bash
aws sts get-caller-identity
```

You should see your account ID and user ARN. Terraform's AWS provider reads
the same credentials file, so no keys go into the `.tf` files. **Never paste
access keys into Terraform code or commit them to git.**

## Step 2. Configure the lab

```bash
cd aws-free-tier-vm
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and:

- set `aws_region` to the region you chose in `aws configure`;
- optionally set `ssh_allowed_cidr` to your own IP, found with `curl -s ifconfig.me`,
  followed by `/32`. Leaving `0.0.0.0/0` works but lets the whole internet
  knock on port 22.

## Step 3. Initialise

```bash
terraform init
```

Terraform downloads the AWS provider into `.terraform/` and writes
`.terraform.lock.hcl`, which pins the exact provider version. Both are
git-ignored here. Run `init` again any time you add a provider or module.

## Step 4. Plan

```bash
terraform plan
```

Read the output. You should see `Plan: 3 to add, 0 to change, 0 to destroy.`
Find the three `+` resources. Notice values shown as `(known after apply)`:
Terraform cannot know the public IP until AWS hands one out.

## Step 5. Apply

```bash
terraform apply
```

Type `yes`. It takes about 30 seconds. At the end Terraform prints the outputs:

```
public_ip   = "3.120.xx.xx"
ssh_command = "ssh ubuntu@3.120.xx.xx"
web_url     = "http://3.120.xx.xx"
```

Wait about a minute for the first-boot script to install nginx, then:

```bash
curl $(terraform output -raw web_url)
```

You should get `<h1>Hello from Terraform!</h1>`. Open the same URL in a browser.

Log in:

```bash
$(terraform output -raw ssh_command)
```

Type `yes` to accept the host key. On the VM, try `cat /var/log/cloud-init-output.log`
to see what the first-boot script did, then `exit`.

## Step 6. Explore the state

```bash
terraform state list                 # what Terraform is managing
terraform state show aws_instance.vm # every attribute of the VM
terraform output                     # just the outputs again
terraform plan                       # should say: No changes.
```

"No changes" is the key idea: Terraform compared the real infrastructure with
your files and found them identical. Running `apply` twice is safe.

## Step 7. Change something

Edit `main.tf` and change the text inside the `user_data` block, for example
`Hello from <your name>!`. Run `terraform plan`.

Terraform wants to **destroy and recreate** the instance (look for `-/+` and
`# forces replacement`). The first-boot script only runs at first boot, so a
new VM is the only way to apply it. This is a deliberate lesson: some changes
are in-place updates, some force replacement. Apply it, wait a minute, `curl`
the new IP (it changes!).

Now try a change that does *not* force replacement: in `main.tf` add a tag,
for example `Owner = "your-name"`, next to `Name`. `terraform plan` shows `~`
(update in place). Apply it.

## Step 8. Destroy

```bash
terraform destroy
```

Type `yes`. Then **verify in the AWS console** (EC2 -> Instances, correct
region) that the instance shows *terminated* and that no other instance is
running. The key pair and security group are gone too.

Lastly, in the EC2 console check *Elastic Block Store -> Volumes* and
*Network and Security -> Elastic IPs*. Both should be empty. This lab does not
create either, but checking is the habit.

## Cleanup checklist

- [ ] `terraform destroy` finished with `Destroy complete! Resources: 3 destroyed.`
- [ ] EC2 console shows no running instances in **every region you used**
- [ ] No volumes, no Elastic IPs
- [ ] Zero-spend budget alert exists
- [ ] (Optional) deactivate the IAM access key if you will not use it again

## File-by-file

| File                       | Purpose                                                         |
|----------------------------|-----------------------------------------------------------------|
| `versions.tf`              | Required Terraform and provider versions                        |
| `providers.tf`             | Region and default tags for the AWS provider                    |
| `variables.tf`             | Inputs with defaults and a free-tier guard on `instance_type`   |
| `main.tf`                  | Data sources (VPC, subnets, AMI) and the three resources        |
| `outputs.tf`               | Values printed after apply (IP, SSH command, URL)               |
| `terraform.tfvars.example` | Template for your own values; copy to `terraform.tfvars`        |
| `.gitignore`               | Keeps state, lock file and tfvars out of git                    |

## Troubleshooting

**`Error: no matching EC2 VPC found`**
Your account has no default VPC in this region. In the console go to
VPC -> Your VPCs -> Actions -> *Create default VPC*, then re-run.

**`Error: Invalid function argument ... file(...)`**
The public key path in `ssh_public_key_path` does not exist. Run `ssh-keygen`
(see Prerequisites) or point the variable at your existing `.pub` file.

**`UnauthorizedOperation`**
Your IAM user lacks EC2 permissions. Attach `AmazonEC2FullAccess` or ask the
instructor.

**`InvalidParameterValue: The requested configuration is currently not supported`**
`t3.micro` is not available in that availability zone or region. Set
`instance_type = "t2.micro"` or switch region.

**The web page does not load**
Wait 1 to 2 minutes; the script installs packages on first boot. If it still
fails, SSH in and check `cat /var/log/cloud-init-output.log`.

**`Permission denied (publickey)` on SSH**
The user is `ubuntu`, not `root` or `ec2-user`. Make sure you are using the
private key that matches the uploaded `.pub`: `ssh -i ~/.ssh/id_ed25519 ubuntu@IP`.

**SSH hangs / times out**
If you set `ssh_allowed_cidr` to your IP, your IP may have changed. Check
`curl -s ifconfig.me`, update `terraform.tfvars`, `terraform apply`.

**Terraform says resources exist but the console is empty (or vice versa)**
You are probably looking at a different region in the console. Check the
region selector in the top right corner.

## Going further

- Pin a specific AMI ID instead of `most_recent = true` and discuss why
  production teams do that.
- Replace the default VPC with your own `aws_vpc`, `aws_subnet`,
  `aws_internet_gateway` and `aws_route_table`.
- Move the state to an S3 bucket (`backend "s3"`) and discuss remote state.
- Run `terraform plan` from a second laptop with the same code and no state
  file. What does it want to do, and why is that dangerous?

## References

- AWS Free Tier: https://aws.amazon.com/free/
- Terraform AWS provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform CLI docs: https://developer.hashicorp.com/terraform/cli
- Ubuntu AMI locator: https://cloud-images.ubuntu.com/locator/ec2/
