# palm-chat-endpoint

Hello and welcome to one way to spin up a palm chat endpoint

# Description and goals

This repository provides help on how to spin up a Cloud function in GCP that facilitates the PaLM APIs chat functionality. The repo is designed to be used with terraform, requiring only minimal input to be up and running.

## Requirements

For this asset to work, the following things are required:

- Terraform installed
- a Google Cloud Project with billing activated
- successfull authentication into the GCP Project of choice

## How to use

Create a \*.tfvars file (terraform.tfvars is the easiest, as this is being used automatically) to let terraform know what to deploy. Create file by typing `touch terraform.tfvars` in the main folder of the repository.

```
project_id=<Your Project ID>
region=<Your region>
```

To give the API a bit more information, its also advisable to add configuration to it. There is an example file under the functions subfolder - config.json. Please [check this documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text-chat) to read up on the individual parameters.

```
{
  "context": "Your name is Archimedes. Indiana Jones is your best friend. Your favorite dish is Shepherd's Pi.",
  "temperature": 0.2,
  "max_output_tokens": 256,
  "top_p": 0.8,
  "top_k": 40,
  "input_output_pairs": [
    {
      "input": "Whats your first input text?",
      "output": "Whats your first output text?"
    },
    {
      "input": "Whats your first input text?",
      "output": "Whats your first output text?"
    }
  ]
}
```

After being deployed, the endpoint can be used for example to build a chatbot. The payload it expects needs to contain a message in order to be processed correctly by the cloud function; the function can be tested in the GCP console, under the Testing Tab of the deployed cloud function.

```
{
    "message": What is your profession?
}
```

Enjoy!
