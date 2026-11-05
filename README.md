# Week 11 classwork — Run the Terraform Loop

Individually, about 40 minutes. Nothing here touches AWS, needs credentials, or
costs anything: the `local` provider just writes a file on your own machine.

## Setup

Install Terraform (`terraform -version` should print a version), then work in
this folder.

## Steps

**1. `terraform init`**
Terraform downloads the `local` provider. Look at the directory afterwards —
`.terraform/` and `.terraform.lock.hcl` appeared. What do you think the lock
file is for?

**2. `terraform plan`**
Read the output rather than skimming it. Count the `+` symbols. Say out loud
what Terraform is about to create, and where.

**3. `terraform apply`**
Type `yes` when prompted. Then check the file really exists:
`cat hello.txt`

**4. `terraform plan` again**
It reports **no changes**. Nothing was rebuilt, nothing was touched. That is
**idempotency**, and it is the single most important idea this week: running
the same automation twice is safe.

**5. Change something**
Edit `main.tf` and set `default` on `student_name` to your own name. Run
`terraform plan` once more and read what Terraform now intends to do — look
carefully at which symbol it uses, and what that implies about the file.

Apply it, and check `hello.txt` again.

**6. `terraform destroy`**
Read the `-` symbols before confirming. Then check the file is gone.

## To be marked

Show your instructor:

- the `plan` output from step 2
- the **no changes** result from step 4
- what the plan in step 5 said it would do, and why
- the empty directory after `destroy`

## Worth noticing

You never told Terraform *how* to create or delete the file. You described the
state you wanted and it worked out the difference between that and reality.
That is what *declarative* means, and it is the same idea whether the resource
is a text file or a production database.
