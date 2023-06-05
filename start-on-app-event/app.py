""""
    Copyright (C) 2023 Axis Communications AB, Lund, Sweden

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        <http://www.apache.org/licenses/LICENSE-2.0>

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
"""

import json
import os
import time
import xml.etree.ElementTree as ET
from ast import literal_eval
from datetime import date

import requests
from requests.auth import HTTPDigestAuth

app_name = os.environ["APPNAME"]
device_ip = os.environ["DEVICE_IP"]
device_username = os.environ["DEVICE_USERNAME"]
device_password = os.environ["DEVICE_PASSWORD"]
generate_event_triggers = literal_eval(
    os.environ["GENERATE_EVENT_TRIGGERS"].lower().capitalize()
)


def get_recordings_path():
    date_today = str(date.today().isoformat()).replace("-", "")
    return "/tmp/recordings/" + date_today


def get_file_data(file_name):
    f = open(file_name)
    file_data = f.read()
    f.close()
    return file_data


def set_configuration(data):
    url = "http://{}/local/{}/control.cgi".format(device_ip, app_name)
    requests.post(url, auth=HTTPDigestAuth(device_username, device_password), json=data)


def vapix_services(xml):
    url = "http://{}/vapix/services".format(device_ip)
    response = requests.post(
        url,
        auth=HTTPDigestAuth(device_username, device_password),
        headers={"Content-Type": "text/plain;charset=UTF-8"},
        data=xml.encode("utf-8"),
    )
    return response.text


def get_action_configuration_id(response):
    root = ET.fromstring(response)
    for element in root.iter():
        if "ConfigurationID" in element.tag:
            return element.text


def get_folder_composition(path):
    file_path_set = set()
    for dir_path, _, files in os.walk(path):
        file_paths = list(map(lambda f: os.path.join(dir_path, f), files))
        mkv_file_paths = filter(lambda f_p: f_p.endswith(".mkv"), file_paths)
        file_path_set = file_path_set.union(set(mkv_file_paths))
    return file_path_set


def folder_has_changed(current, last):
    return len(current - last) > 0


def generate_rules_and_actions():
    app_config_data = get_file_data("json/" + app_name + "_config.json")
    app_config_data_json = json.loads(app_config_data)
    set_configuration(app_config_data_json)

    add_action_configuration = get_file_data("xml/add_action_configuration.xml")
    time.sleep(5)
    add_action_rule = get_file_data("xml/" + app_name + "_add_action_rule.xml")
    response = vapix_services(add_action_configuration)

    action_config_id = get_action_configuration_id(response)
    new_action_rule = add_action_rule.replace("ConfigurationID", str(action_config_id))
    vapix_services(new_action_rule)


if generate_event_triggers:
    generate_rules_and_actions()

recordings_path = get_recordings_path()
last_recordings_path = recordings_path

last_folder_comp = get_folder_composition(recordings_path)

while True:
    recordings_path = get_recordings_path()
    current_folder_comp = get_folder_composition(recordings_path)

    if recordings_path != last_recordings_path:
        last_recordings_path = recordings_path
        last_folder_comp = current_folder_comp
    else:
        if folder_has_changed(current_folder_comp, last_folder_comp):
            new_file_path = str(sorted(list(current_folder_comp))[-1])
            os.environ["FILE_NAME"] = new_file_path
            os.system("./start_stream_mkv.sh")
        else:
            print("no event detected...")
        last_folder_comp = current_folder_comp
        last_recordings_path = recordings_path
        time.sleep(3)
