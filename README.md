# CircleCI Runners

This repository holds the code for the creation of CircleCI runners and FSx filesystem used for Shared DDC and Binaries/Intermediate files movement in between BuildGraph jobs.

## Create/Update/Remove a runner with an existing resource class

All runners are managed by the `runners.tf` file and `modules/runner` module, they are created based on a list of objects as defined in `variables.tf` and `runners.auto.tfvars` files. If you want to remove a runner or update an existing runner then go to the variables file.

## Creating a new runner under a new resource class.

Runners are registered against CircleCI in their resource class using an auth token provided by the CircleCI CLI.

1. Create the new resource class using CircleCI CLI
```bash
$ circleci runner resource-class create vela-games/your-runner-name "Some Description" --generate-token
api:
    auth_token: <AUTH_TOKEN>
+-------------------------------+---------------------------+
|        RESOURCE CLASS         |        DESCRIPTION        |
+-------------------------------+---------------------------+
| vela-games/your-runner-name   | Some Description          |
+-------------------------------+---------------------------+
```

2. The auth token has to be added to the `circleci_auth_tokens` map variable stored in Terraform Cloud as an HCL structure and sensitive. So you'll need the existing tokens for the current runners for that, those are stored in LastPass.

3. Define the runner object in the `runners.auto.tfvars` file and apply the changes.

If everything was done properly then running:
```bash
$ circleci runner instance list vela-games
```

Should show the new instances in the resource class you created.