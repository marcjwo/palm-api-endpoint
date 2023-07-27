# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import functions_framework, vertexai, json, os
from vertexai.preview.language_models import ChatModel


def load_config():
    with open("config.json", "r") as config_file:
        return json.load(config_file)


def initialize_parameters(config):
    context = config["context"]
    input_output_pairs = config["input_output_pairs"]
    temperature = config["temperature"]
    max_output_tokens = config["max_output_tokens"]
    top_p = config["top_p"]
    top_k = config["top_k"]
    examples = [
        vertexai.preview.language_models.InputOutputTextPair(pair["input"], pair["output"]) for pair in input_output_pairs
    ]
    project_id = os.environ.get("PROJECT_ID")
    location = os.environ.get("LOCATION")
    return context, examples, temperature, max_output_tokens, top_p, top_k, project_id, location


def initialize_chat_model():
    return ChatModel.from_pretrained("chat-bison@001")


config = load_config()
context, examples, temperature, max_output_tokens, top_p, top_k, project_id, location = initialize_parameters(config)
chat_model = initialize_chat_model()

@functions_framework.http
def process_request(request):
    request_json = request.get_json(silent=True)
    parameters = {
        "temperature": temperature,
        "max_output_tokens": max_output_tokens,
        "top_p": top_p,
        "top_k": top_k,
    }
    chat = chat_model.start_chat(context=context, examples=examples)
    response = chat.send_message(request_json["message"], **parameters)
    response_json = {"message": response.text}
    return response_json
