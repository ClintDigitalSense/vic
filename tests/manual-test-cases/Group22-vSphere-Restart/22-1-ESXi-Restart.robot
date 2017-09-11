# Copyright 2017 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

*** Settings ***
Documentation  Test 22-1 - ESXi Restart
Resource  ../../resources/Util.robot
Suite Teardown  Run Keyword And Ignore Error  Nimbus Cleanup  ${list}

*** Test Cases ***
Test
    Log To Console  \nStarting test...
    Log To Console  \nWait until Nimbus is at least available...
    Open Connection  %{NIMBUS_GW}
    Wait Until Keyword Succeeds  10 min  30 sec  Login  %{NIMBUS_USER}  %{NIMBUS_PASSWORD}
    Close Connection

    ${esx}  ${esx-ip}=  Deploy Nimbus ESXi Server  %{NIMBUS_USER}  %{NIMBUS_PASSWORD}
    Set Global Variable  @{list}  ${esx}
    Set Environment Variable  GOVC_URL  root:${NIMBUS_ESX_PASSWORD}@${esx-ip}
    Set Environment Variable  TEST_URL_ARRAY  ${esx-ip}
    Set Environment Variable  TEST_URL  ${esx-ip}
    Set Environment Variable  TEST_USERNAME  root
    Set Environment Variable  TEST_PASSWORD  ${NIMBUS_ESX_PASSWORD}
    Set Environment Variable  TEST_DATASTORE  datastore1
    Set Environment Variable  TEST_TIMEOUT  30m
    Set Environment Variable  HOST_TYPE  ESXi
    Remove Environment Variable  TEST_DATACENTER
    Remove Environment Variable  TEST_RESOURCE
    Remove Environment Variable  BRIDGE_NETWORK
    Remove Environment Variable  PUBLIC_NETWORK

    Install VIC Appliance To Test Server
    Run Regression Tests

    Reset Nimbus Server  %{NIMBUS_USER}  %{NIMBUS_PASSWORD}  ${esx}
    Log To Console  Sleeping 5 minutes to allow for the server to reboot in Nimbus...
    Sleep  5 minutes
    Wait Until vSphere Is Powered On

    ${rc}  ${output}=  Run And Return Rc And Output  govc vm.power -on %{VCH-NAME}
    Should Be Equal As Integers  ${rc}  0
    Wait Until VM Powers On  %{VCH-NAME}

    Log To Console  Getting VCH IP ...
    ${new-vch-ip}=  Get VM IP  %{VCH-NAME}
    Log To Console  New VCH IP is ${new-vch-ip}
    Replace String  %{VCH-PARAMS}  %{VCH-IP}  ${new-vch-ip}

    # wait for docker info to succeed
    Wait Until Keyword Succeeds  20x  5 seconds  Run Docker Info  %{VCH-PARAMS}

    Run Regression Tests
