#  Copyright 2024 Dataport. All rights reserved. Developed as part of the MERLOT project.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# frozen_string_literal: true

require_relative '../../lib/config'
require_relative '../../lib/keys'
require_relative '../../lib/user'
require_relative '../../lib/client'

require 'base64'
require 'tmpdir'
require 'securerandom'

after '/api/v1/connectors*' do
  headers['Content-Type'] = 'application/json'
end

before '/api/v1/connectors/*' do
  return if request.env['REQUEST_METHOD'] == 'OPTIONS'
rescue StandardError => e
  p e if debug
  halt 401
end

endpoint '/api/v1/connectors', ['POST'], public_endpoint: true do

  begin
    # use client name of body if available
    json = JSON.parse request.body.read
    client_name = json['client_name'].empty? ? SecureRandom.uuid : json['client_name']
    did = json['did'].empty? ? "" : json['did']
  rescue => e
    client_name = SecureRandom.uuid
    did = ""
  end

  # generate a new password for the keystore
  keystore_password = SecureRandom.base64(24)

  # create certificate/key or load from disk if exists
  gen_cert_cmd = "./scripts/register_connector.sh #{client_name} #{did}"
  gen_cert_cmd_value = `#{gen_cert_cmd}`
  client_id = gen_cert_cmd_value.strip

  keystore_encoded = ""
  Dir.mktmpdir do |d| # create temp directory
    # generate keystore
    cert_to_pem_cmd = "openssl x509 -in keys/#{client_name}.cert -out #{d}/#{client_name}.cert.pem -outform PEM 2>&1"
    `#{cert_to_pem_cmd}`
    export_keystore_cmd = "openssl pkcs12 --password pass:#{keystore_password} -export -in #{d}/#{client_name}.cert.pem -inkey keys/#{client_name}.key -out #{d}/#{client_name}.cert.pfx 2>&1"
    `#{export_keystore_cmd}`

    # encode keystore in base64 for sending via json
    keystore_file = File.open("#{d}/#{client_name}.cert.pfx", "rb")
    keystore_data = keystore_file.read
    keystore_file.close
    keystore_encoded = Base64.strict_encode64(keystore_data)
  end

  halt 200, JSON.generate({
    "client_name": client_name,
    "client_id": client_id,
    "keystore": keystore_encoded, 
    "password": keystore_password,
    "scope": "idsc:IDS_CONNECTOR_ATTRIBUTES_ALL"
  })
end

endpoint '/api/v1/connectors/:client_id', ['GET'], public_endpoint: true do
  begin
    client_id = params['client_id']
  rescue => e
    halt 400
  end

  connector_details = load_connector_details(client_id, "id")
  if connector_details.nil?
    halt 404
  end

  halt 200, JSON.generate(connector_details)
end

endpoint '/api/v1/connectors', ['GET'], public_endpoint: true do
  begin
    client_name = params['client_name']
    client_id = params['client_id']
  rescue => e
    halt 400
  end
  id_type = (client_id.nil? || client_id.empty?) ? "name" : "id"
  used_id = (id_type == "name") ? client_name : client_id

  if used_id.class != Array
    used_id = [used_id]
  end

  connector_details = {}
  used_id.each do |uid|
    details = load_connector_details(uid, id_type)
    if !details.nil?
      connector_details[uid] = details
    end
  end

  halt 200, JSON.generate(connector_details)
end

endpoint '/api/v1/connectors/:client_id', ['DELETE'], public_endpoint: true do
  begin
    client_id = params['client_id']
  rescue => e
    halt 400
  end

  # delete client from keystore
  delete_cmd = "./scripts/delete_connector.sh #{client_id}"
  `#{delete_cmd}`

  halt 200
end

def load_connector_details(used_id, id_type)
  # load info from clients
  details_cmd = "./scripts/read_connector_details.sh #{id_type} #{used_id}"
  details_cmd_value = `#{details_cmd}`
  if $?.exitstatus != 0 || details_cmd_value.empty?
    return nil
  end
  details_json = JSON.parse(details_cmd_value)
  if details_json.class == Array
    details_json = details_json[0]
  end

  attributes = {}
  details_json['attributes'].each do |attr|
    attributes[attr['key']] = attr['value']
  end

  cleaned_details = {
    "client_name": details_json['client_name'],
    "client_id": details_json['client_id'],
    "attributes": attributes,
  }

  return cleaned_details
end
